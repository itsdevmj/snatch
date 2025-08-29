// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:file_picker/file_picker.dart';
import '../utils/download_manager.dart';

class DownloadsPage extends StatefulWidget {
  @override
  _DownloadsPageState createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final DownloadManager _downloadManager = DownloadManager();
  List<DownloadItem> downloads = [];
  String downloadPath = '';

  @override
  void initState() {
    super.initState();
    _setupDownloadManager();
    _loadDownloadPath();
  }

  void _setupDownloadManager() async {
    // Listen to download updates
    _downloadManager.onDownloadsUpdated = (updatedDownloads) {
      if (mounted) {
        setState(() {
          downloads = updatedDownloads;
        });
      }
    };

    // Wait a bit for downloads to load from storage, then update UI
    await Future.delayed(Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        downloads = _downloadManager.downloads;
      });
    }
  }

  void _loadDownloadPath() async {
    final path = await _downloadManager.getDownloadDirectory();
    if (mounted) {
      setState(() {
        downloadPath = path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Downloads',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Download path section
          GestureDetector(
            onTap: _changeDownloadPath,
            onLongPress: _showPathOptions,
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.folder_rounded,
                      color: Color(0xFF2196F3),
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Download Path',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 4),
                            Text(
                              '(Tap to change • Hold for options)',
                              style: TextStyle(
                                color: Color(0xFF2196F3),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Text(
                          downloadPath.isNotEmpty ? downloadPath : 'Loading...',
                          style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit_rounded, color: Color(0xFF2196F3), size: 18),
                ],
              ),
            ),
          ),

          // Downloads list
          Expanded(
            child: downloads.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: downloads.length,
                    itemBuilder: (context, index) {
                      return _buildDownloadItem(downloads[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadItem(DownloadItem item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Platform icon
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getPlatformColor(item.platform).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getPlatformIcon(item.platform),
              color: _getPlatformColor(item.platform),
              size: 24,
            ),
          ),
          SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      item.size,
                      style: TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.duration > 0) ...[
                      SizedBox(width: 8),
                      Text(
                        '• ${item.duration}s',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getStatusColor(item.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _getStatusText(item.status),
                        style: TextStyle(
                          color: _getStatusColor(item.status),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'By ${item.author}',
                      style: TextStyle(
                        color: Color(0xFF888888),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      item.platform,
                      style: TextStyle(
                        color: _getPlatformColor(item.platform),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (item.status == DownloadStatus.downloading) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: item.progress,
                          backgroundColor: Color(0xFFE0E0E0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF2196F3),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${(item.progress * 100).toInt()}%',
                        style: TextStyle(
                          color: Color(0xFF666666),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                if (item.status == DownloadStatus.failed &&
                    item.error != null) ...[
                  SizedBox(height: 4),
                  Text(
                    'Error: ${item.error}',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Action button
          PopupMenuButton<String>(
            onSelected: (action) => _handleAction(action, item),
            itemBuilder: (context) => [
              if (item.status == DownloadStatus.completed)
                PopupMenuItem(
                  value: 'play',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow, size: 16),
                      SizedBox(width: 8),
                      Text('Play'),
                    ],
                  ),
                ),
              if (item.status == DownloadStatus.downloading)
                PopupMenuItem(
                  value: 'pause',
                  child: Row(
                    children: [
                      Icon(Icons.pause, size: 16),
                      SizedBox(width: 8),
                      Text('Pause'),
                    ],
                  ),
                ),
              if (item.status == DownloadStatus.paused)
                PopupMenuItem(
                  value: 'resume',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow, size: 16),
                      SizedBox(width: 8),
                      Text('Resume'),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(String action, DownloadItem item) async {
    switch (action) {
      case 'play':
        if (item.filePath != null) {
          final result = await OpenFilex.open(item.filePath!);
          if (result.type != ResultType.done) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Could not open file')));
          }
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('File not found')));
        }
        break;
      case 'pause':
        _downloadManager.pauseDownload(item.id);
        break;
      case 'resume':
        _downloadManager.resumeDownload(item.id);
        break;
      case 'delete':
        _downloadManager.deleteDownload(item.id);
        break;
    }
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'tiktok':
        return Icons.music_note;
      case 'instagram':
        return Icons.camera_alt;
      case 'youtube':
        return Icons.play_circle;
      case 'twitter':
        return Icons.alternate_email;
      case 'facebook':
        return Icons.facebook;
      default:
        return Icons.video_library;
    }
  }

  Color _getPlatformColor(String platform) {
    switch (platform.toLowerCase()) {
      case 'tiktok':
        return Colors.black;
      case 'instagram':
        return Colors.purple;
      case 'youtube':
        return Colors.red;
      case 'twitter':
        return Colors.blue;
      case 'facebook':
        return Colors.indigo;
      default:
        return Color(0xFF2196F3);
    }
  }

  Color _getStatusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.completed:
        return Color(0xFF4CAF50);
      case DownloadStatus.downloading:
        return Color(0xFF2196F3);
      case DownloadStatus.paused:
        return Color(0xFFFF9800);
      case DownloadStatus.failed:
        return Color(0xFFF44336);
    }
  }

  String _getStatusText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.paused:
        return 'Paused';
      case DownloadStatus.failed:
        return 'Failed';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFF2196F3).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.download_rounded,
              size: 48,
              color: Color(0xFF2196F3),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Downloads Yet',
            style: TextStyle(
              color: Color(0xFF1A1A1A),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Copy social media links to start downloading',
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _changeDownloadPath() async {
    try {
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        // Update the download manager with new path
        await _downloadManager.setCustomDownloadPath(selectedDirectory);

        // Update UI
        if (mounted) {
          setState(() {
            downloadPath = selectedDirectory;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Download path updated successfully'),
              backgroundColor: Color(0xFF4CAF50),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to change download path: $e'),
            backgroundColor: Color(0xFFF44336),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _showPathOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Download Path Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.folder_open, color: Color(0xFF2196F3)),
              title: Text('Change Path'),
              subtitle: Text('Select a new download directory'),
              onTap: () {
                Navigator.pop(context);
                _changeDownloadPath();
              },
            ),
            ListTile(
              leading: Icon(Icons.restore, color: Color(0xFF4CAF50)),
              title: Text('Reset to Default'),
              subtitle: Text('Use the default download directory'),
              onTap: () {
                Navigator.pop(context);
                _resetToDefaultPath();
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _resetToDefaultPath() async {
    try {
      // Clear custom path
      await _downloadManager.setCustomDownloadPath('');

      // Get default path
      final defaultPath = await _downloadManager.getDownloadDirectory();

      if (mounted) {
        setState(() {
          downloadPath = defaultPath;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reset to default download path'),
            backgroundColor: Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset path: $e'),
            backgroundColor: Color(0xFFF44336),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
