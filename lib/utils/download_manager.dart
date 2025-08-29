// lib/utils/download_manager.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadManager {
  static final DownloadManager _instance = DownloadManager._internal();
  factory DownloadManager() => _instance;
  DownloadManager._internal();

  final Dio _dio = Dio();
  final List<DownloadItem> _downloads = [];
  
  // Callback to notify UI about updates
  Function(List<DownloadItem>)? onDownloadsUpdated;

  List<DownloadItem> get downloads => _downloads;

  // Request storage permission
Future<bool> requestStoragePermission() async {
  if (Platform.isAndroid) {
    if (await Permission.storage.isGranted) {
      return true;
    }

    // For Android 11+ (API 30+)
    if (await Permission.manageExternalStorage.isGranted) {
      return true;
    }

    // Request normal storage permission first
    var status = await Permission.storage.request();
    if (status.isGranted) return true;

    // If still not granted, request all files access
    var manageStatus = await Permission.manageExternalStorage.request();
    return manageStatus.isGranted;
  }
  return true;
}


  // Get download directory
  Future<String> getDownloadDirectory() async {
    if (Platform.isAndroid) {
      // Try to use the Downloads folder
      Directory? downloadsDir = Directory('/storage/emulated/0/Download/Videos');
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
            downloadItem.size = '${(received / 1024 / 1024).toStringAsFixed(1)} MB';
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
}

enum DownloadStatus {
  downloading,
  completed,
  paused,
  failed,
}