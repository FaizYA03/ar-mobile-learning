import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Speech bubble untuk penjelasan interaktif (hotspot) pada model 3D di
/// AR Scanner.
///
/// Ditempatkan sedekat mungkin dengan [anchorCenter] (titik hotspot hasil
/// proyeksi dari WebView model-viewer dalam koordinat Stack scanner) tetapi
/// selalu dijaga agar tetap berada di dalam area [viewport]. Menampilkan
/// pointer/panah kecil yang menunjuk ke hotspot, bersama tombol tutup.
class ArHotspotSpeechBubble extends StatelessWidget {
  final Offset anchorCenter;
  final Size viewport;
  final String title;
  final String? description;
  final VoidCallback onClose;

  const ArHotspotSpeechBubble({
    super.key,
    required this.anchorCenter,
    required this.viewport,
    required this.title,
    this.description,
    required this.onClose,
  });

  static const double _margin = 12;
  static const double _gap = 8;
  static const double _closeSize = 24;
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(16, 12, 16, 12);
  static const double _maxWidth = 280;

  static const TextStyle _titleStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
    height: 1.25,
  );

  static const TextStyle _descStyle = TextStyle(
    fontSize: 12.5,
    color: Color(0xE6FFFFFF),
    height: 1.4,
  );

  @override
  Widget build(BuildContext context) {
    if (viewport.width <= 0 || viewport.height <= 0) {
      return const SizedBox.shrink();
    }

    final bubbleSize = _measure(context);
    final rect = _chooseRect(bubbleSize);
    final hasDesc = description != null && description!.trim().isNotEmpty;

    return Positioned.fromRect(
      rect: rect,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.88, end: 1),
        duration: const Duration(milliseconds: 170),
        curve: Curves.easeOut,
        builder: (context, t, child) {
          return Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(scale: t, child: child),
          );
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Pointer menuju hotspot digambar di belakang kotak bubble agar
            // hanya bagian yang menonjol (di luar kotak) yang terlihat.
            Positioned.fill(
              child: CustomPaint(
                painter: _BubblePointerPainter(
                  anchorLocal: Offset(
                    anchorCenter.dx - rect.left,
                    anchorCenter.dy - rect.top,
                  ),
                  bubbleSize: rect.size,
                ),
              ),
            ),
            Container(
              width: rect.width,
              height: rect.height,
              padding: _padding,
              decoration: BoxDecoration(
                color: const Color(0xF21A1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x33FFFFFF)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: _titleStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hasDesc) ...[
                          const SizedBox(height: 6),
                          Text(
                            description!,
                            style: _descStyle,
                            maxLines: 6,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: onClose,
                    borderRadius: BorderRadius.circular(_closeSize / 2),
                    child: Container(
                      width: _closeSize,
                      height: _closeSize,
                      decoration: const BoxDecoration(
                        color: Color(0x33FFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mengukur ukuran bubble secara deterministik (TextPainter) agar bubble
  /// dapat diposisikan + diklem tepat di dalam viewport tanpa keluar layar.
  Size _measure(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final contentWidth =
        math.min(_maxWidth, viewport.width - _margin * 2).toDouble();
    // Lebar bidang teks dibuat sedikit lebih sempit daripada lebar layout
    // asli supaya TextPainter membungkus paling tidak sama banyaknya dengan
    // Text sesungguhnya (hasil ukur >= tinggi render); bubble tidak akan
    // pernah overflow/terpotong di dalam kotak berukuran tetap.
    final bodyWidth = (contentWidth - _padding.horizontal - _closeSize - 12)
        .clamp(80.0, contentWidth - _padding.horizontal)
        .toDouble();

    double heightFor(String text, TextStyle style, int maxLines) {
      final tp = TextPainter(
        text: TextSpan(text: text, style: style),
        maxLines: maxLines,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.start,
        textScaler: textScaler,
        ellipsis: '…',
      )..layout(maxWidth: bodyWidth);
      return tp.height;
    }

    final titleH = heightFor(title, _titleStyle, 2);
    final hasDesc = description != null && description!.trim().isNotEmpty;
    final descH = hasDesc ? heightFor(description!, _descStyle, 6) : 0.0;

    final inner = titleH + (hasDesc ? 6.0 + descH : 0.0);
    final height = math.max(
      _padding.vertical + inner + 3,
      _closeSize + _padding.vertical,
    );
    return Size(contentWidth, height);
  }

  double _clampDouble(double v, double lo, double hi) =>
      v < lo ? lo : (v > hi ? hi : v);

  /// Memilih posisi bubble di sekitar [anchorCenter] dengan urutan prioritas:
  /// kanan -> kiri -> bawah -> atas. Posisi selalu diklem agar tidak keluar
  /// dari viewport.
  Rect _chooseRect(Size b) {
    final vw = viewport.width;
    final vh = viewport.height;
    final minLeft = _margin;
    final minTop = _margin;
    final maxLeft = math.max(_margin, vw - _margin - b.width).toDouble();
    final maxTop = math.max(_margin, vh - _margin - b.height).toDouble();

    if (anchorCenter.dx + _gap + b.width <= vw - _margin) {
      return Rect.fromLTWH(
        anchorCenter.dx + _gap,
        _clampDouble(anchorCenter.dy - b.height / 2, minTop, maxTop),
        b.width,
        b.height,
      );
    }
    if (anchorCenter.dx - _gap - b.width >= _margin) {
      return Rect.fromLTWH(
        anchorCenter.dx - _gap - b.width,
        _clampDouble(anchorCenter.dy - b.height / 2, minTop, maxTop),
        b.width,
        b.height,
      );
    }
    if (anchorCenter.dy + _gap + b.height <= vh - _margin) {
      return Rect.fromLTWH(
        _clampDouble(anchorCenter.dx - b.width / 2, minLeft, maxLeft),
        anchorCenter.dy + _gap,
        b.width,
        b.height,
      );
    }
    if (anchorCenter.dy - _gap - b.height >= _margin) {
      return Rect.fromLTWH(
        _clampDouble(anchorCenter.dx - b.width / 2, minLeft, maxLeft),
        anchorCenter.dy - _gap - b.height,
        b.width,
        b.height,
      );
    }
    return Rect.fromLTWH(
      _clampDouble(anchorCenter.dx + _gap, minLeft, maxLeft),
      _clampDouble(anchorCenter.dy - b.height / 2, minTop, maxTop),
      b.width,
      b.height,
    );
  }
}

/// Menggambar segitiga kecil (pointer) yang menunjuk dari tepi bubble menuju
/// hotspot. Digambar di belakang kotak bubble; hanya bagian yang menonjol di
/// luar kotak yang terlihat.
class _BubblePointerPainter extends CustomPainter {
  final Offset anchorLocal;
  final Size bubbleSize;

  static const double _baseWidth = 14;
  static const double _height = 10;

  _BubblePointerPainter({
    required this.anchorLocal,
    required this.bubbleSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & bubbleSize;
    if (rect.contains(anchorLocal)) return;

    final clamped = Offset(
      anchorLocal.dx.clamp(rect.left, rect.right).toDouble(),
      anchorLocal.dy.clamp(rect.top, rect.bottom).toDouble(),
    );
    final dx = anchorLocal.dx - clamped.dx;
    final dy = anchorLocal.dy - clamped.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len < 0.001) return;

    final ux = dx / len;
    final uy = dy / len;
    final tip = Offset(clamped.dx + ux * _height, clamped.dy + uy * _height);

    final px = -uy * (_baseWidth / 2);
    final py = ux * (_baseWidth / 2);
    final p1 = Offset(clamped.dx + px, clamped.dy + py);
    final p2 = Offset(clamped.dx - px, clamped.dy - py);

    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xF21A1A2E));
  }

  @override
  bool shouldRepaint(_BubblePointerPainter oldDelegate) =>
      oldDelegate.anchorLocal != anchorLocal ||
      oldDelegate.bubbleSize != bubbleSize;
}
