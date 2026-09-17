import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'quiz_result_screen.dart';

class QuizTakeScreen extends StatefulWidget {
  final int quizId;
  final String quizTitle;

  const QuizTakeScreen({super.key, required this.quizId, required this.quizTitle});

  @override
  State<QuizTakeScreen> createState() => _QuizTakeScreenState();
}

class _QuizTakeScreenState extends State<QuizTakeScreen> {
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<dynamic> _questions = [];
  int _currentIndex = 0;
  final Map<int, int> _selectedOptions = {}; // question_id -> option_id

  @override
  void initState() {
    super.initState();
    _fetchQuizDetail();
  }

  Future<void> _fetchQuizDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.getQuiz(widget.quizId);
      if (response['success'] == true && mounted) {
        final quizData = response['data'];
        setState(() {
          _questions = quizData['questions'] ?? [];
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message'] ?? 'Gagal memuat soal quiz';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal terhubung ke server.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmSubmit() async {
    final total = _questions.length;
    final answered = _selectedOptions.length;
    final unanswered = total - answered;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Kumpulkan Jawaban?'),
        content: Text(
          unanswered > 0
              ? 'Ada $unanswered dari $total soal yang belum dijawab. Apakah Anda yakin ingin mengumpulkan?'
              : 'Semua $total soal sudah dijawab. Kumpulkan jawaban sekarang?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Periksa Lagi')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A8477),
              foregroundColor: Colors.white,
            ),
            child: const Text('Kumpulkan'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _submitQuiz();
    }
  }

  Future<void> _submitQuiz() async {
    setState(() => _isSubmitting = true);

    final answers = _selectedOptions.entries.map((e) => {
      'question_id': e.key,
      'option_id': e.value,
    }).toList();

    try {
      final response = await ApiService.submitQuiz(widget.quizId, answers);
      if (response['success'] == true && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => QuizResultScreen(
              quizTitle: widget.quizTitle,
              resultData: response['data'],
            ),
          ),
        );
      } else {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Gagal mengumpulkan quiz')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan jaringan saat submit.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.quizTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1A1A2E)),
          onPressed: () async {
            final exit = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Keluar Quiz?'),
                content: const Text('Progres jawaban Anda saat ini tidak akan tersimpan.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Lanjut Mengerjakan')),
                  TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Keluar', style: TextStyle(color: Color(0xFFC62828)))),
                ],
              ),
            );
            if (exit == true && context.mounted) {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _questions.isEmpty || _isLoading ? null : _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF0A8477)));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Color(0xFFC62828)),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: _fetchQuizDetail, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return const Center(child: Text('Quiz ini belum memiliki pertanyaan.'));
    }

    final currentQuestion = _questions[_currentIndex];
    final questionId = currentQuestion['id'];
    final questionText = currentQuestion['text'] ?? '';
    final options = (currentQuestion['options'] as List<dynamic>?) ?? [];
    final selectedOptionId = _selectedOptions[questionId];

    return Column(
      children: [
        // Progress header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.white,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Soal ${_currentIndex + 1} dari ${_questions.length}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                  ),
                  Text(
                    'Terjawab ${_selectedOptions.length}/${_questions.length}',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF0A8477), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentIndex + 1) / _questions.length,
                backgroundColor: const Color(0xFFE9ECEF),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0A8477)),
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pertanyaan Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Text(
                    questionText,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E), height: 1.4),
                  ),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Pilih Jawaban:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF637080)),
                ),
                const SizedBox(height: 12),

                // Options list
                ...options.asMap().entries.map((entry) {
                  final optIndex = entry.key;
                  final option = entry.value;
                  final optId = option['id'];
                  final optText = option['text'] ?? '';
                  final isSelected = selectedOptionId == optId;
                  final letter = String.fromCharCode(65 + optIndex); // A, B, C, D

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE8F5F3) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF0A8477) : const Color(0xFFE9ECEF),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          setState(() {
                            _selectedOptions[questionId] = optId;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF0A8477) : const Color(0xFFF5F7FA),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? Colors.white : const Color(0xFF637080),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  optText,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? const Color(0xFF075A51) : const Color(0xFF1A1A2E),
                                  ),
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: Color(0xFF0A8477), size: 22),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final isLast = _currentIndex == _questions.length - 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (_currentIndex > 0)
              OutlinedButton(
                onPressed: () => setState(() => _currentIndex--),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Sebelumnya'),
              ),
            const Spacer(),
            if (!isLast)
              ElevatedButton.icon(
                onPressed: () => setState(() => _currentIndex++),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Berikutnya'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A8477),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _confirmSubmit,
                icon: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.check, size: 18),
                label: Text(_isSubmitting ? 'Mengirim...' : 'Selesai & Kumpulkan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A8477),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}