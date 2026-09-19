import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget yang menampilkan kamera + renderer AR native (Opsi 3).
///
/// Native (ArEngineView) yang memegang ARCore session, image tracking, dan
/// rendering GLB. Designer hanya menampilkan; seluruh logika diendapkan di
/// [ArEngineController].
class ArEngineView extends StatelessWidget {
  static const viewType = 'com.example.frontend/ar_engine';

  final VoidCallback? onCreated;

  const ArEngineView({super.key, this.onCreated});

  @override
  Widget build(BuildContext context) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AndroidView(
          viewType: viewType,
          onPlatformViewCreated: (_) => onCreated?.call(),
        );
      default:
        return const ColoredBox(
          color: Colors.black,
          child: Center(
            child: Text(
              'AR hanya tersedia di perangkat Android.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
    }
  }
}
