import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _autoSaveEnabled = true;
  int _maxClips = 100;
  bool _showNotifications = true;
  bool _darkMode = false;
  String appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAppVersion();
  }

    void _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        appVersion = info.version; 
      });
    }
  }

  void _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _autoSaveEnabled = prefs.getBool('auto_save_enabled') ?? true;
      _maxClips = prefs.getInt('max_clips') ?? 100;
      _showNotifications = prefs.getBool('show_notifications') ?? true;
      _darkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  void _saveSetting(String key, dynamic value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }
  }

  void _showMaxClipsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.storage, color: Color(0xFF3B82F6)),
            SizedBox(width: 12),
            Text(
              'Maximum Clips',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose how many clips to keep in history:',
              style: TextStyle(color: Color(0xFF64748B)),
            ),
            SizedBox(height: 20),
            ...([50, 100, 200, 500].map(
              (value) => RadioListTile<int>(
                title: Text('$value clips'),
                value: value,
                groupValue: _maxClips,
                activeColor: Color(0xFF3B82F6),
                onChanged: (int? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _maxClips = newValue;
                    });
                    _saveSetting('max_clips', newValue);
                    Navigator.pop(context);
                  }
                },
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
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
              child: Icon(Icons.settings, color: Color(0xFF3B82F6), size: 20),
            ),
            SizedBox(width: 12),
            Text(
              "Settings",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // General Settings Section
          Container(
            margin: EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF3B82F6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.tune,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'General',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Color(0xFFF1F5F9)),
                SwitchListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  title: Text(
                    'Auto-save clips',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    'Automatically save copied text to clipboard history',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  value: _autoSaveEnabled,
                  activeColor: Color(0xFF3B82F6),
                  onChanged: (bool value) {
                    setState(() {
                      _autoSaveEnabled = value;
                    });
                    _saveSetting('auto_save_enabled', value);
                  },
                ),
                Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.storage,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Maximum clips',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    'Keep up to $_maxClips clips in history',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_maxClips',
                      style: TextStyle(
                        color: Color(0xFF3B82F6),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  onTap: _showMaxClipsDialog,
                ),
                SizedBox(height: 12),
              ],
            ),
          ),

          // Notifications Section
          Container(
            margin: EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.notifications,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Color(0xFFF1F5F9)),
                SwitchListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  title: Text(
                    'Show notifications',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    'Get notified when clips are copied or deleted',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  value: _showNotifications,
                  activeColor: Color(0xFF10B981),
                  onChanged: (bool value) {
                    setState(() {
                      _showNotifications = value;
                    });
                    _saveSetting('show_notifications', value);
                  },
                ),
                SizedBox(height: 12),
              ],
            ),
          ),

          // Appearance Section
          Container(
            margin: EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF8B5CF6).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.palette,
                          color: Color(0xFF8B5CF6),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Appearance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Color(0xFFF1F5F9)),
                SwitchListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  title: Text(
                    'Dark mode',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    'Use dark theme for better viewing in low light',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                  value: _darkMode,
                  activeColor: Color(0xFF8B5CF6),
                  onChanged: (bool value) {
                    setState(() {
                      _darkMode = value;
                    });
                    _saveSetting('dark_mode', value);
                  },
                ),
                SizedBox(height: 12),
              ],
            ),
          ),

          // About Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.info,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'About',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Color(0xFFF1F5F9)),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF3B82F6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.content_paste,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'snatch',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  subtitle: Text(
                    'Version $appVersion\nSecure clipboard manager for Flutter',
                    style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                  ),
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
