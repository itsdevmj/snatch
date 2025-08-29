import 'package:flutter/material.dart';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:snatch/utils/download_manager.dart';

class ClipboardWatcherPage extends StatefulWidget {
  const ClipboardWatcherPage({super.key});

  @override
  _ClipboardWatcherPageState createState() => _ClipboardWatcherPageState();
}

class _ClipboardWatcherPageState extends State<ClipboardWatcherPage>
    with ClipboardListener, TickerProviderStateMixin {
  String copiedText = "";
  List<String> savedClips = [];
  late AnimationController _animationController;

  final String apiEndpoint = "https://gen-apis.vercel.app/dl/tiktok";

  bool isSocialMediaLink(String text) {
    if (text.contains('tiktok.com') || text.contains('vm.tiktok.com')) {
      return true;
    } //only tiktok for now, will add more in the future

    return false;
  }

  String getPlatfromName(String url) {
    if (url.contains('tiktok')) return "Tiktok";
    return "Unknown"; //same here too just to identify the names of the platfroms
  }

  //link processing and stuff
  Future<void> sndLkToApi(String link) async {
    // processing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 8),
            Text('Processing ${getPlatfromName(link)} link...'),
          ],
        ),
        duration: Duration(seconds: 3),
      ),
    );

    Map<String, dynamic> dtosend = {
      'url': link,
      'platform': getPlatfromName(link),
      'timestamp': DateTime.now().toString(),
    };

    //will get GET later on
    final res = await http.post(
      Uri.parse(apiEndpoint),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(dtosend),
    );
    print('${res.body}');

    if (res.statusCode == 200) {
      // Parse API response
      final responseData = jsonDecode(res.body);

      final String title = responseData['title'] ?? 'Unknown Title';
      final String videoUrl = responseData['videoUrl'] ?? '';
      final String platform = getPlatfromName(link);
      final int duration = responseData['duration'] ?? 0;
      final Map<String, dynamic>? author = responseData['author'];

      // Clean up the title (remove hashtags for filename)
      String cleanTitle = title
          .replaceAll('#', '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      if (cleanTitle.isEmpty) {
        cleanTitle = 'Video_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Add author info to title if available
      if (author != null && author['nickname'] != null) {
        cleanTitle = '${author['nickname']} - $cleanTitle';
      }

      // Limit title length for filename
      if (cleanTitle.length > 100) {
        cleanTitle = cleanTitle.substring(0, 100);
      }

      if (videoUrl.isNotEmpty) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Starting download:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(cleanTitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (duration > 0) Text('Duration: ${duration}s'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );

        // Start the actual download
        await DownloadManager().startDownload(
          videoUrl: videoUrl,
          title: cleanTitle,
          platform: platform,
          author: author?['nickname'] ?? 'Unknown',
          duration: duration,
        );

        print('Download started for: $cleanTitle'); // Debug
      } else {
        throw Exception('No video URL found in API response');
      }
    } else {
      throw Exception(
        'API returned error: ${res.statusCode}\nBody: ${res.body}',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
    loadClips();
  }

  @override
  void dispose() {
    _animationController.dispose();
    clipboardWatcher.removeListener(this);
    clipboardWatcher.stop();
    super.dispose();
  }

  @override
  void onClipboardChanged() async {
    // Get what was copied
    ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);

    if (data != null &&
        data.text != null &&
        data.text!.isNotEmpty &&
        data.text != copiedText) {
      String newText = data.text!.trim(); // Remove extra spaces

      setState(() {
        copiedText = newText;
      });

      if (isSocialMediaLink(newText)) {
        await sndLkToApi(newText);
      }

      if (!savedClips.contains(copiedText)) {
        savedClips.insert(0, copiedText);
        if (savedClips.length > 100) {
          savedClips = savedClips.take(100).toList();
        }
      }
      saveClips();
    }
  }

  void saveClips() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('saved_clips', savedClips);
  }

  void loadClips() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    savedClips = prefs.getStringList('saved_clips') ?? [];
    setState(() {});
  }

  void copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text(
              'Copied to clipboard!',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void deleteClip(int index) {
    setState(() {
      savedClips.removeAt(index);
    });
    saveClips();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Clip deleted', style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: Color(0xFFFF5722),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void clearAllClips() {
    setState(() {
      savedClips.clear();
    });
    saveClips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1E293B),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.content_paste,
                color: Color(0xFF3B82F6),
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Text(
              "Snatch",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        actions: [
          if (savedClips.isNotEmpty)
            Container(
              margin: EdgeInsets.only(right: 16),
              child: PopupMenuButton<String>(
                icon: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.more_vert,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                onSelected: (value) {
                  if (value == 'clear_all') {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFFF5722),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Clear All Clips',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        content: Text(
                          'Are you sure you want to delete all saved clips? This action cannot be undone.',
                          style: TextStyle(color: Color(0xFF64748B)),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              clearAllClips();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFFF5722),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Clear All',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep, color: Color(0xFFFF5722)),
                        SizedBox(width: 12),
                        Text(
                          'Clear All',
                          style: TextStyle(color: Color(0xFFFF5722)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: savedClips.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Color(0xFF3B82F6).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.content_paste_outlined,
                      size: 64,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'No clips saved yet',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Copy some text to get started!',
                    style: TextStyle(fontSize: 16, color: Color(0xFF64748B)),
                  ),
                  SizedBox(height: 32),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 32),
                    padding: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF3B82F6).withOpacity(0.1),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: Color(0xFF3B82F6),
                            size: 24,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Snatch automatically saves everything you copy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your clipboard history is stored securely on your device',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  margin: EdgeInsets.all(16),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF3B82F6).withOpacity(0.1),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.storage,
                          size: 16,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        '${savedClips.length} clips saved',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Tap to copy',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: savedClips.length,
                    itemBuilder: (context, index) {
                      final clip = savedClips[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            clip,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF1E293B),
                              height: 1.4,
                            ),
                          ),
                          subtitle: Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.text_fields,
                                  size: 14,
                                  color: Color(0xFF64748B),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '${clip.length} characters',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: PopupMenuButton<String>(
                            icon: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.more_vert,
                                size: 16,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            onSelected: (value) {
                              if (value == 'copy') {
                                copyToClipboard(clip);
                              } else if (value == 'delete') {
                                deleteClip(index);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'copy',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.copy,
                                      size: 18,
                                      color: Color(0xFF3B82F6),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Copy',
                                      style: TextStyle(
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: Color(0xFFFF5722),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: Color(0xFFFF5722),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          onTap: () => copyToClipboard(clip),
                          onLongPress: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                title: Row(
                                  children: [
                                    Icon(
                                      Icons.preview,
                                      color: Color(0xFF3B82F6),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Clip Preview',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                content: Container(
                                  constraints: BoxConstraints(maxHeight: 300),
                                  child: SingleChildScrollView(
                                    child: Text(
                                      clip,
                                      style: TextStyle(
                                        fontSize: 16,
                                        height: 1.5,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text(
                                      'Close',
                                      style: TextStyle(
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      copyToClipboard(clip);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF3B82F6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Copy',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
