import 'package:flutter/material.dart';
import 'package:snatch/others/update_manager.dart';
import 'package:snatch/utils/clipboardwatcher.dart';
import 'package:snatch/utils/downloads.dart';
import 'package:snatch/utils/settings.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'SF Pro Display',
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int currentPageIndex = 0;
  late AnimationController _animationController;
  
  final List<Widget> pages = [
    ClipboardWatcherPage(),
    SettingsPage(),
    DownloadsPage()
  ];

  @override
  void initState() {
    super.initState();
      WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateManager.checkForUpdate(context);
     });
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[currentPageIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.08),
              blurRadius: 25,
              offset: Offset(0, -8),
              spreadRadius: 0,
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 65, // Fixed height - much better proportion
            margin: EdgeInsets.only(bottom: 5), // Small margin from bottom
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.content_paste_rounded,
                  label: 'Clips',
                  index: 0,
                ),
                _buildNavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  index: 1,
                ),
                  _buildNavItem(
                  icon: Icons.download,
                  label: 'Downloads',
                  index: 2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = currentPageIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          currentPageIndex = index;
        });
        // Smooth bounce animation
        _animationController.forward().then((_) {
          _animationController.reverse();
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 20 : 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected 
            // ignore: deprecated_member_use
            ? Color(0xFF2196F3).withOpacity(0.12) 
            : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with scale animation
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: Icon(
                icon,
                color: isSelected 
                  ? Color(0xFF2196F3) 
                  : Color(0xFF757575),
                size: 24,
              ),
            ),
            SizedBox(height: 4), // Better spacing
            // Text with smooth animation
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              style: TextStyle(
                color: isSelected 
                  ? Color(0xFF2196F3) 
                  : Color(0xFF757575),
                fontSize: 12,
                fontWeight: isSelected 
                  ? FontWeight.w600 
                  : FontWeight.w500,
                letterSpacing: 0.3,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}