// lib/utils/download_manager.dart
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal() {
    _loadDownloads();
    _loadCustomPath();
  }

  final Dio _dio = Dio();
  final List<DownloadItem> _downloads = [];
  static const String _downloadsKey = 'saved_downloads';
  static const String _customPathKey = 'custom_download_path';
  String? _customDownloadPath;

  // Callback to notify UI about updates
  Function(List<DownloadItem>)? onDownloadsUpdated;

  List<DownloadItem> get downloads => _downloads;

  // Public method to reload downloads
  Future<void> loadDownloads() async {
    await _loadDownloads();
  }

  // Load downloads from storage
  Future<void> _loadDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = prefs.getString(_downloadsKey);

      if (downloadsJson != null) {
        final List<dynamic> downloadsList = json.decode(downloadsJson);
        _downloads.clear();

        for (final downloadData in downloadsList) {
          final item = DownloadItem.fromJson(downloadData);

          // Verify file still exists for completed downloads
          if (item.status == DownloadStatus.completed &&
              item.filePath != null) {
            final file = File(item.filePath!);
            if (await file.exists()) {
              _downloads.add(item);
            }
          } else if (item.status != DownloadStatus.completed) {
            // Reset non-completed downloads to failed state
            item.status = DownloadStatus.failed;
            item.error = 'Download interrupted by app restart';
            _downloads.add(item);
          }
        }

        _notifyUpdate();
      }
    } catch (e) {
      print('Error loading downloads: $e');
    }
  }

  // Save downloads to storage
  Future<void> _saveDownloads() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = json.encode(
        _downloads.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_downloadsKey, downloadsJson);
    } catch (e) {
      print('Error saving downloads: $e');
    }
  }

  // Load custom download path
  Future<void> _loadCustomPath() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _customDownloadPath = prefs.getString(_customPathKey);
    } catch (e) {
      print('Error loading custom path: $e');
    }
  }

  // Save custom download path
  Future<void> _saveCustomPath(String path) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customPathKey, path);
      _customDownloadPath = path;
    } catch (e) {
      print('Error saving custom path: $e');
    }
  }

  // Set custom download path
  Future<void> setCustomDownloadPath(String path) async {
    if (path.isEmpty) {
      // Clear custom path
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_customPathKey);
      _customDownloadPath = null;
    } else {
      await _saveCustomPath(path);
    }
  }

  // Get current custom path
  String? get customDownloadPath => _customDownloadPath;

  // Request storage permission
  Future<bool> requestStoragePermission() async {
    if (Platform.isAndroid) {
      try {
        // Check if we already have permissions
        bool hasStorage = await Permission.storage.isGranted;
        bool hasManageExternal =
            await Permission.manageExternalStorage.isGranted;

        if (hasStorage || hasManageExternal) {
          print('Storage permissions already granted');
          return true;
        }

        print('Requesting storage permissions...');

        // Request storage permission first
        PermissionStatus storageStatus = await Permission.storage.request();
        print('Storage permission status: $storageStatus');

        if (storageStatus.isGranted) {
          return true;
        }

        // If storage permission denied, try manage external storage
        PermissionStatus manageStatus = await Permission.manageExternalStorage
            .request();
        print('Manage external storage permission status: $manageStatus');

        if (manageStatus.isGranted) {
          return true;
        }

        // If both denied, show user what to do
        if (storageStatus.isPermanentlyDenied ||
            manageStatus.isPermanentlyDenied) {
          print('Permissions permanently denied. Opening app settings...');
          await openAppSettings();
        }

        return false;
      } catch (e) {
        print('Error requesting permissions: $e');
        return false;
      }
    }
    return true;
  }

  // Get download directory
  Future<String> getDownloadDirectory() async {
    // Use custom path if set
    if (_customDownloadPath != null) {
      final customDir = Directory(_customDownloadPath!);
      if (await customDir.exists()) {
        return _customDownloadPath!;
      }
    }

    if (Platform.isAndroid) {
      try {
        // Try to use the external storage directory first
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          final downloadsDir = Directory('${directory.path}/Downloads');
          if (!await downloadsDir.exists()) {
            await downloadsDir.create(recursive: true);
          }
          return downloadsDir.path;
        }
      } catch (e) {
        print('Error accessing external storage: $e');
      }

      // Fallback to app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${directory.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      return downloadsDir.path;
    } else {
      // For iOS, use app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${directory.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      return downloadsDir.path;
    }
  }

  // Start download
  Future<void> startDownload({
    required String videoUrl,
    required String title,
    required String platform,
    String? author,
    int? duration,
  }) async {
    // Request permission first
    bool hasPermission = await requestStoragePermission();
    if (!hasPermission) {
      throw Exception('Storage permission denied');
    }

    // Create download item
    final downloadItem = DownloadItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      platform: platform,
      author: author ?? 'Unknown',
      duration: duration ?? 0,
      status: DownloadStatus.downloading,
      progress: 0.0,
      size: 'Calculating...',
      videoUrl: videoUrl,
    );

    // Add to downloads list
    _downloads.insert(0, downloadItem);
    _notifyUpdate();

    try {
      // Get download directory
      final downloadDir = await getDownloadDirectory();

      // Create filename (remove special characters)
      final fileName = '${title.replaceAll(RegExp(r'[^\w\s-]'), '')}.mp4';
      final filePath = '$downloadDir/$fileName';

      // Start download with progress tracking
      await _dio.download(
        videoUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            // Update progress
            downloadItem.progress = received / total;
            downloadItem.size =
                '${(received / 1024 / 1024).toStringAsFixed(1)} MB';
            _notifyUpdate();
          }
        },
      );

      // Download completed
      downloadItem.status = DownloadStatus.completed;
      downloadItem.progress = 1.0;
      downloadItem.filePath = filePath;
      _notifyUpdate();
    } catch (error) {
      // Download failed
      downloadItem.status = DownloadStatus.failed;
      downloadItem.error = error.toString();
      _notifyUpdate();
      print('Download error: $error');
    }
  }

  // Notify UI about updates
  void _notifyUpdate() {
    onDownloadsUpdated?.call(_downloads);
    _saveDownloads(); // Save to persistent storage
  }

  // Pause download (basic implementation)
  void pauseDownload(String id) {
    final item = _downloads.firstWhere((d) => d.id == id);
    item.status = DownloadStatus.paused;
    _notifyUpdate();
  }

  // Resume download (basic implementation)
  void resumeDownload(String id) {
    final item = _downloads.firstWhere((d) => d.id == id);
    item.status = DownloadStatus.downloading;
    _notifyUpdate();
  }

  // Delete download
  void deleteDownload(String id) async {
    final item = _downloads.firstWhere((d) => d.id == id);

    // Delete file if exists
    if (item.filePath != null) {
      final file = File(item.filePath!);
      if (await file.exists()) {
        await file.delete();
      }
    }

    // Remove from list
    _downloads.removeWhere((d) => d.id == id);
    _notifyUpdate();
  }

  // Clear all downloads (for testing)
  Future<void> clearAllDownloads() async {
    _downloads.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_downloadsKey);
    _notifyUpdate();
  }
}

// Updated DownloadItem class
class DownloadItem {
  final String id;
  final String title;
  final String platform;
  final String author;
  final int duration;
  DownloadStatus status;
  double progress;
  String size;
  final String videoUrl;
  String? filePath;
  String? error;

  DownloadItem({
    required this.id,
    required this.title,
    required this.platform,
    required this.author,
    required this.duration,
    required this.status,
    required this.progress,
    required this.size,
    required this.videoUrl,
    this.filePath,
    this.error,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'platform': platform,
      'author': author,
      'duration': duration,
      'status': status.index,
      'progress': progress,
      'size': size,
      'videoUrl': videoUrl,
      'filePath': filePath,
      'error': error,
    };
  }

  // Create from JSON
  factory DownloadItem.fromJson(Map<String, dynamic> json) {
    return DownloadItem(
      id: json['id'],
      title: json['title'],
      platform: json['platform'],
      author: json['author'],
      duration: json['duration'],
      status: DownloadStatus.values[json['status']],
      progress: json['progress'].toDouble(),
      size: json['size'],
      videoUrl: json['videoUrl'],
      filePath: json['filePath'],
      error: json['error'],
    );
  }
}

enum DownloadStatus { downloading, completed, paused, failed }
