import 'package:flutter/material.dart';
import '../services/app_config_service.dart';

/// Banner pengumuman dari CMS. Sembunyi otomatis bila
/// teks kosong atau flag aktif mati.
class AnnouncementBanner extends StatelessWidget {
  const AnnouncementBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final config = AppConfigService.config;
    final text = config?.announcementText.trim() ?? '';
    final active = config?.announcementActive ?? false;
    if (!active || text.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9A825).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: const Color(0xFFF9A825).withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.campaign_outlined,
              color: Color(0xFFE67E22), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, height: 1.5, color: Color(0xFF1A1A2E))),
          ),
        ],
      ),
    );
  }
}
