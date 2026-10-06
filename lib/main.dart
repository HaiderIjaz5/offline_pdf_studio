import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:in_app_update/in_app_update.dart';

import 'screens/home_screen.dart';
import 'screens/pdf_viewer_screen.dart';
import 'services/settings_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    unawaited(MobileAds.instance.initialize());
  }

  final String savedTheme = await SettingsService.getThemeMode();
  if (savedTheme == 'light') themeNotifier.value = ThemeMode.light;
  else if (savedTheme == 'dark') themeNotifier.value = ThemeMode.dark;
  else themeNotifier.value = ThemeMode.system;

  runApp(const OfflinePdfStudioApp());
}

class OfflinePdfStudioApp extends StatefulWidget {
  const OfflinePdfStudioApp({super.key});

  @override
  State<OfflinePdfStudioApp> createState() => _OfflinePdfStudioAppState();
}

class _OfflinePdfStudioAppState extends State<OfflinePdfStudioApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initIntentListener();
      _checkForUpdate();
    }
  }

  Future<void> _checkForUpdate() async {
    try {
      final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        if (info.immediateUpdateAllowed) {
          await InAppUpdate.performImmediateUpdate();
        } else if (info.flexibleUpdateAllowed) {
          await InAppUpdate.startFlexibleUpdate();
          await InAppUpdate.completeFlexibleUpdate();
        }
      }
    } catch (e) {
      debugPrint("In-app update check failed: $e");
    }
  }

  void _initIntentListener() {
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    if (files.isNotEmpty) {
      final file = files.first;
      final pathLower = file.path.toLowerCase();
      final mime = file.mimeType?.toLowerCase() ?? '';

      if (pathLower.endsWith('.pdf') || mime.contains('pdf')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => PdfViewerScreen(
                filePath: file.path,
                openedFromIntent: true,
              ),
            ),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _intentDataStreamSubscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'Offline PDF Studio',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFD32F2F),
              primary: const Color(0xFFD32F2F),
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFD32F2F),
              primary: const Color(0xFFD32F2F),
              brightness: Brightness.dark,
            ),
          ),
          home: const HomeScreen(),
        );
      },
    );
  }
}