// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateManager {
  static const String repoOwner = "itsdevmj";
  static const String repoName = "snatch";

  // Check for updates
  static Future<void> checkForUpdate(BuildContext context) async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version; // e.g. "1.0.0"

      // Fetch latest release from GitHub API
      final url =
          "https://api.github.com/repos/$repoOwner/$repoName/releases/latest";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final release = json.decode(response.body);
        final latestVersion = release["tag_name"].toString().replaceAll(
          "v",
          "",
        );
        final downloadUrl = release["html_url"]; // GitHub release page

        if (_isNewerVersion(latestVersion, currentVersion)) {
          showUpdateDialog(context, latestVersion, downloadUrl);
        }
      }
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  // Compare versions (simple semver)
  static bool _isNewerVersion(String latest, String current) {
    final latestParts = latest.split(".").map(int.parse).toList();
    final currentParts = current.split(".").map(int.parse).toList();

    for (var i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  static void showUpdateDialog(
    BuildContext context,
    String latestVersion,
    String url,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update Available"),
        content: Text(
          "A new version ($latestVersion) is available.\nWould you like to update?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close the dialog first
              await _launchUpdateUrl(context, url);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // Enhanced URL launching with multiple fallback strategies
  static Future<void> _launchUpdateUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnackBar(context, "Invalid update URL");
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
      );
      if (launched) return;


    } catch (e) {
      debugPrint("All URL launch strategies failed: $e");
      if (context.mounted) {
        _showSnackBar(
          context,
          "Could not open browser. URL copied to clipboard - paste it in your browser to update.",
        );
      }
    }
  }

  static void _showSnackBar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }
}