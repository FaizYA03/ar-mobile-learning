import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/models.dart';
import 'package:frontend/widgets/ar_hotspot_speech_bubble.dart';

void main() {
  group('ArHotspotData (backend hotspot)', () {
    test('parses position_x/y/z, scale and sort_order', () {
      final hotspot = ArHotspotData.fromJson({
        'id': 1,
        'model_id': 10,
        'title': 'ALU',
        'description': 'Unit yang melakukan operasi matematika dan logika.',
        'position_x': 0.35,
        'position_y': 0.12,
        'position_z': 0.78,
        'scale': 1.5,
        'sort_order': 2,
      });
      expect(hotspot.id, 1);
      expect(hotspot.title, 'ALU');
      expect(hotspot.positionX, 0.35);
      expect(hotspot.positionY, 0.12);
      expect(hotspot.positionZ, 0.78);
      expect(hotspot.hotspotScale, 1.5);
      expect(hotspot.sortOrder, 2);
    });

    test('ArResolveResult parses nested hotspots from /ar/resolve', () {
      final result = ArResolveResult.fromJson({
        'marker': {
          'id': 1,
          'marker_id': 'CPU-001',
          'ar_uco_id': 3,
          'aruco_dictionary': 'DICT_4X4_50',
          'marker_type': 'aruco',
          'status': 'active',
        },
        'model': {
          'id': 10,
          'model_name': 'CPU 3D',
          'description': 'CPU',
          'category': 'Hardware',
          'version': 2,
          'glb_url': 'http://example.com/cpu.glb',
          'glb_path': 'models/cpu.glb',
        },
        'hotspots': [
          {
            'id': 1,
            'title': 'ALU',
            'description': 'Arithmetic Logic Unit',
            'position_x': 0.35,
            'position_y': 0.12,
            'position_z': 0.78,
            'rotation_x': 0,
            'rotation_y': 0,
            'rotation_z': 0,
            'scale': 1.0,
          }
        ],
      });
      expect(result.model.id, 10);
      expect(result.hotspots.length, 1);
      expect(result.hotspots.first.title, 'ALU');
      expect(result.hotspots.first.positionX, 0.35);
    });
  });

  group('ArHotspotSpeechBubble', () {
    Future<void> pumpBubble(
      WidgetTester tester, {
      required Offset anchor,
      Size viewport = const Size(800, 600),
      VoidCallback? onClose,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: viewport.width,
                height: viewport.height,
                child: Stack(
                  children: [
                    Positioned.fill(child: Container()),
                    ArHotspotSpeechBubble(
                      anchorCenter: anchor,
                      viewport: viewport,
                      title: 'ALU',
                      description:
                          'Unit yang melakukan operasi matematika dan logika.',
                      onClose: onClose ?? () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    void expectInsideSurface(Rect rect, Size viewport) {
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(viewport.width));
      expect(rect.bottom, lessThanOrEqualTo(viewport.height));
    }

    testWidgets('renders title and description from data', (tester) async {
      await pumpBubble(tester, anchor: const Offset(400, 300));
      expect(find.text('ALU'), findsOneWidget);
      expect(
        find.text('Unit yang melakukan operasi matematika dan logika.'),
        findsOneWidget,
      );
    });

    testWidgets('stays inside viewport near right edge', (tester) async {
      const viewport = Size(800, 600);
      await pumpBubble(tester,
          anchor: const Offset(780, 300), viewport: viewport);
      final rect = tester.getRect(find.byType(ArHotspotSpeechBubble));
      expectInsideSurface(rect, viewport);
    });

    testWidgets('stays inside viewport near top-right corner', (tester) async {
      const viewport = Size(800, 600);
      await pumpBubble(tester,
          anchor: const Offset(785, 8), viewport: viewport);
      final rect = tester.getRect(find.byType(ArHotspotSpeechBubble));
      expectInsideSurface(rect, viewport);
    });

    testWidgets('stays inside viewport near bottom-left corner',
        (tester) async {
      const viewport = Size(800, 600);
      await pumpBubble(tester,
          anchor: const Offset(6, 590), viewport: viewport);
      final rect = tester.getRect(find.byType(ArHotspotSpeechBubble));
      expectInsideSurface(rect, viewport);
    });

    testWidgets('close button calls onClose', (tester) async {
      var closed = false;
      await pumpBubble(
        tester,
        anchor: const Offset(400, 300),
        onClose: () => closed = true,
      );
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      expect(closed, true);
    });
  });
}
