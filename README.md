# 📱 Snatch - Smart Clipboard & Social Media Downloader

> **Snatch** automatically saves everything you copy and downloads videos from social media platforms with just a copy-paste!

## ✨ Features

### 🔄 Smart Clipboard Management
- **Automatic clipboard monitoring** - Saves everything you copy
- **Persistent history** - Never lose your copied text again
- **Clean interface** - Easy to browse and manage your clips
- **One-tap copy** - Quickly reuse any saved clip
- **Search & organize** - Find what you need instantly

### 📥 Social Media Downloads
- **TikTok video downloads** - Just copy the link and it downloads automatically
- **High-quality videos** - Downloads in the best available quality
- **Custom download paths** - Choose where to save your videos
- **Download progress tracking** - See real-time download status
- **Metadata preservation** - Keeps video title, author, and duration info

### 🛡️ Privacy & Security
- **Local storage only** - All data stays on your device
- **No cloud sync** - Your privacy is protected
- **Secure permissions** - Only requests necessary permissions
- **No tracking** - We don't collect any personal data

## 🚀 Getting Started

### Installation
1. Download the latest APK from the [Releases](../../releases) page
2. Install the APK on your Android device
3. Grant necessary permissions when prompted
4. Start copying and downloading!

### First Use
1. **Grant Permissions**: Allow storage access for downloads
2. **Copy Something**: Copy any text to see it appear in your clipboard history
3. **Download Videos**: Copy a TikTok link and watch it download automatically
4. **Customize**: Set your preferred download location in settings

## 📱 Screenshots

*Coming soon - Screenshots of the beautiful interface*

## 🔧 How It Works

### Clipboard Monitoring
Snatch runs in the background and automatically detects when you copy text. It intelligently saves your clipboard history while respecting your privacy.

### Social Media Detection
When you copy a supported social media link (currently TikTok), Snatch automatically:
1. Detects the platform
2. Fetches video information
3. Downloads the video to your chosen location
4. Shows download progress
5. Notifies you when complete

## 🎯 Supported Platforms

| Platform | Status | Features |
|----------|--------|----------|
| TikTok | ✅ Full Support | Video download, metadata, progress tracking |
| Instagram | 🔄 Coming Soon | Video & photo downloads |
| YouTube | 🔄 Coming Soon | Video downloads |
| Twitter | 🔄 Coming Soon | Video & GIF downloads |

## ⚙️ Technical Details

### Built With
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **Android Native** - Platform-specific features

### Key Dependencies
- `clipboard_watcher` - Clipboard monitoring
- `permission_handler` - Android permissions
- `dio` - HTTP client for downloads
- `path_provider` - File system access
- `shared_preferences` - Local data storage

### System Requirements
- **Android 6.0+** (API level 23+)
- **Storage permission** for downloads
- **Internet connection** for video downloads

## 🛠️ Development

### Prerequisites
- Flutter SDK (3.9.0+)
- Android Studio / VS Code
- Android device or emulator

### Setup
```bash
# Clone the repository
git clone https://github.com/itsdevmj/snatch.git
cd snatch

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Building Release APK
```bash
# Build release APK
flutter build apk --release

# Build app bundle for Play Store
flutter build appbundle --release
```

## 🤝 Contributing

We welcome contributions! Here's how you can help:

1. **Report Bugs** - Found an issue? Let us know!
2. **Suggest Features** - Have ideas for new platforms or features?
3. **Submit PRs** - Code contributions are always welcome
4. **Test & Feedback** - Help us improve the user experience

### Development Guidelines
- Follow Flutter best practices
- Test on multiple Android versions
- Ensure permissions are handled properly
- Maintain clean, readable code

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Contributors to open-source packages used
- Beta testers and early users

## 📞 Support

Having issues? Here's how to get help:

1. **Check the FAQ** below
2. **Search existing issues** in the repository
3. **Create a new issue** with detailed information
4. **Join our community** for discussions

## ❓ FAQ

**Q: Why isn't clipboard monitoring working in release builds?**
A: Make sure you've granted all necessary permissions. Try using the manual refresh button if automatic monitoring fails.

**Q: Can I download from other platforms besides TikTok?**
A: Currently only TikTok is supported, but we're working on Instagram, YouTube, and Twitter support.

**Q: Where are my downloads saved?**
A: By default, videos are saved to your device's Downloads folder. You can change this in the app settings.

**Q: Is my data safe?**
A: Yes! All data is stored locally on your device. We don't upload anything to external servers.

**Q: Why do I need storage permissions?**
A: Storage permissions are required to save downloaded videos and manage your clipboard history.

---

<div align="center">
  <p>Made with ❤️ using Flutter</p>
  <p>⭐ Star this repo if you find it useful!</p>
</div>
