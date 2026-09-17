import 'package:flutter/material.dart';

class QuizResultScreen extends StatelessWidget {
  final String quizTitle;
  final Map<String, dynamic> resultData;

  const QuizResultScreen({
    super.key,
    required this.quizTitle,
    required this.resultData,
  });

  @override
  Widget build(BuildContext context) {
    final score = resultData['score'] ?? 0;
    final correct = resultData['correct'] ?? 0;
    final total = resultData['total'] ?? 0;
    final passed = resultData['passed'] ?? false;
    final wrong = total - correct;

    final primaryColor = passed ? const Color(0xFF0A8477) : const Color(0xFFC62828);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Hasil Evaluasi Quiz', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Result Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      passed ? Icons.emoji_events_rounded : Icons.replay,
                      color: primaryColor,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    passed ? 'Selamat, Anda Lulus!' : 'Perlu Belajar Lebih Giat',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: primaryColor),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    quizTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF637080)),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FA),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text('Skor Akhir Anda', style: TextStyle(fontSize: 12, color: Color(0xFF637080), fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(
                          '$score',
                          style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: primaryColor),
                        ),
                        Text(
                          passed ? 'Di atas KKM' : 'Di bawah KKM',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('Benar', '$correct', const Color(0xFF0A8477), Icons.check_circle_outline),
                      _buildDivider(),
                      _buildStatItem('Salah', '$wrong', const Color(0xFFC62828), Icons.cancel_outlined),
                      _buildDivider(),
                      _buildStatItem('Total', '$total', const Color(0xFF1A1A2E), Icons.help_outline),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Navigation Buttons
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamedAndRemoveUntil('/siswa', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A8477),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Kembali ke Dashboard', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 36, color: const Color(0xFFE9ECEF));
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 6),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF637080))),
      ],
    );
  }
}