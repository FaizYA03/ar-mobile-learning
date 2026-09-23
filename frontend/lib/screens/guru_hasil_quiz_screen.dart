import 'package:flutter/material.dart';
import '../services/api_service.dart';

/// [Guru] Lihat hasil pengerjaan quiz siswa + statistik.
/// Mendukung filter per quiz. Data dari GET /api/guru/quiz-attempts.
class GuruHasilQuizScreen extends StatefulWidget {
  const GuruHasilQuizScreen({super.key});

  @override
  State<GuruHasilQuizScreen> createState() => _GuruHasilQuizScreenState();
}

class _GuruHasilQuizScreenState extends State<GuruHasilQuizScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _attempts = [];
  List<dynamic> _quizzes = [];
  int? _selectedQuizId;
  int _totalAttempts = 0;
  int _passedCount = 0;
  int _failedCount = 0;
  double _avgScore = 0;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        ApiService.guruGetQuizzes(),
        ApiService.guruGetQuizAttempts(quizId: _selectedQuizId),
      ]);
      if (!mounted) return;
      final quizRes = results[0];
      final attemptRes = results[1];
      if (attemptRes['success'] == true) {
        final data = (attemptRes['data'] ?? []) as List;
        int passed = 0;
        int failed = 0;
        double totalScore = 0;
        for (var attempt in data) {
          if (attempt['passed'] == true) {
            passed++;
          } else {
            failed++;
          }
          totalScore += ((attempt['score'] ?? 0) as num).toDouble();
        }
        setState(() {
          if (quizRes['success'] == true) {
            _quizzes = (quizRes['data'] ?? []) as List;
          }
          _attempts = data;
          _totalAttempts = data.length;
          _passedCount = passed;
          _failedCount = failed;
          _avgScore =
              data.isNotEmpty ? (totalScore / data.length).roundToDouble() : 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = '${attemptRes['message'] ?? 'Gagal memuat data'}';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal terhubung ke server.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Hasil Quiz Siswa',
                            style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E))),
                        SizedBox(height: 4),
                        Text('Pengerjaan quiz oleh siswa',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF637080))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE67E22).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$_totalAttempts',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFE67E22)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int?>(
                  isExpanded: true,
                  initialValue: _selectedQuizId,
                  decoration: const InputDecoration(
                    labelText: 'Filter quiz',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                        value: null, child: Text('Semua quiz')),
                    ..._quizzes.map((q) => DropdownMenuItem<int?>(
                          value: q['id'] as int?,
                          child: Text('${q['title'] ?? 'Quiz'}',
                              overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (v) {
                    setState(() => _selectedQuizId = v);
                    _fetchData();
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildSummaryChip(
                        'Lulus', '$_passedCount', const Color(0xFF27AE60)),
                    const SizedBox(width: 8),
                    _buildSummaryChip('Tidak Lulus', '$_failedCount',
                        const Color(0xFFC62828)),
                    const SizedBox(width: 8),
                    _buildSummaryChip('Rata-rata', '${_avgScore.round()}',
                        const Color(0xFFE67E22)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A8477)));
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 56, color: Color(0xFFC62828)),
              const SizedBox(height: 12),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF637080))),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: _fetchData, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }
    if (_attempts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Belum ada hasil quiz',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF637080))),
            const SizedBox(height: 8),
            const Text('Hasil pengerjaan siswa akan muncul di sini',
                style: TextStyle(fontSize: 13, color: Color(0xFFB0B8C1))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF0A8477),
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: _attempts.length,
        itemBuilder: (ctx, i) =>
            _buildAttemptCard(Map<String, dynamic>.from(_attempts[i] as Map)),
      ),
    );
  }

  Widget _buildAttemptCard(Map<String, dynamic> attempt) {
    final score = attempt['score'] ?? 0;
    final passed = attempt['passed'] == true;
    final user = attempt['user'] as Map?;
    final quiz = attempt['quiz'] as Map?;
    final createdAt = attempt['created_at'];

    String dateStr = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse('$createdAt');
        dateStr =
            '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        dateStr = '$createdAt';
      }
    }

    final okColor = passed ? const Color(0xFF27AE60) : const Color(0xFFC62828);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: okColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$score',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: okColor)),
                  Text(passed ? 'LULUS' : 'GAGAL',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: okColor)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${user?['name'] ?? 'Siswa'}',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 2),
                  Text('${quiz?['title'] ?? 'Quiz'}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF637080))),
                  const SizedBox(height: 4),
                  Text(dateStr,
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFB0B8C1))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: okColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(passed ? 'Lulus' : 'Tidak Lulus',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: okColor)),
            ),
          ],
        ),
      ),
    );
  }
}
