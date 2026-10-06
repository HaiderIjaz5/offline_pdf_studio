import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:in_app_update/in_app_update.dart';

import 'screens/home_screen.dart';
import 'screens/pdf_viewer_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!kIsWeb) {
    unawaited(MobileAds.instance.initialize());
  }

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
    // For sharing or opening files while the app is in the background
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // For sharing or opening files when the app is closed
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
        // Navigate to PdfViewerScreen once the navigator is ready
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
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Offline PDF Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F), // Crimson Red
          primary: const Color(0xFFD32F2F),
          surface: const Color(0xFFF8F9FA), // Professional Off-White
        ),
      ),
      home: const HomeScreen(),
    );
  }
}