import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminQuizManagementScreen extends StatefulWidget {
  const AdminQuizManagementScreen({super.key});

  @override
  State<AdminQuizManagementScreen> createState() => _AdminQuizManagementScreenState();
}

class _AdminQuizManagementScreenState extends State<AdminQuizManagementScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _quizzes = [];

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
      final response = await ApiService.guruGetQuizzes();
      if (response['success'] == true && mounted) {
        setState(() {
          _quizzes = response['data'] ?? [];
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message'] ?? 'Gagal memuat data';
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

  void _showCreateQuizDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '10');
    final scoreCtrl = TextEditingController(text: '70');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Buat Quiz Baru',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Judul Quiz *',
                  hintText: 'Masukkan judul',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeCtrl,
                decoration: InputDecoration(
                  labelText: 'Batas Waktu (menit)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: scoreCtrl,
                decoration: InputDecoration(
                  labelText: 'Passing Score',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A8477),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (titleCtrl.text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Judul quiz wajib diisi')),
                );
                return;
              }
              try {
                await ApiService.guruCreateQuiz({
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'time_limit': int.tryParse(timeCtrl.text) ?? 10,
                  'passing_score': int.tryParse(scoreCtrl.text) ?? 70,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quiz berhasil dibuat')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Gagal membuat quiz')),
                  );
                }
              }
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  void _showEditQuizDialog(Map<String, dynamic> quiz) {
    final titleCtrl = TextEditingController(text: quiz['title'] ?? '');
    final descCtrl = TextEditingController(text: quiz['description'] ?? '');
    final timeCtrl = TextEditingController(text: (quiz['time_limit'] ?? 10).toString());
    final scoreCtrl = TextEditingController(text: (quiz['passing_score'] ?? 70).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Quiz',
            style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Judul Quiz *',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeCtrl,
                decoration: InputDecoration(
                  labelText: 'Batas Waktu (menit)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: scoreCtrl,
                decoration: InputDecoration(
                  labelText: 'Passing Score',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0A8477),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              if (titleCtrl.text.isEmpty) return;
              try {
                await ApiService.guruUpdateQuiz(quiz['id'], {
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'time_limit': int.tryParse(timeCtrl.text) ?? 10,
                  'passing_score': int.tryParse(scoreCtrl.text) ?? 70,
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _fetchData();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quiz berhasil diperbarui')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Gagal memperbarui quiz')),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showAddQuestionDialog(Map<String, dynamic> quiz) {
    final questionCtrl = TextEditingController();
    final List<Map<String, dynamic>> options = [
      {'text': '', 'is_correct': false},
      {'text': '', 'is_correct': false},
      {'text': '', 'is_correct': false},
      {'text': '', 'is_correct': false},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Tambah Soal - ${quiz['title']}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: questionCtrl,
                  decoration: InputDecoration(
                    labelText: 'Soal *',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ...List.generate(options.length, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: 'Opsi ${i + 1} *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (v) => options[i]['text'] = v,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () {
                          setDialogState(() {
                            for (var o in options) {
                              o['is_correct'] = false;
                            }
                            options[i]['is_correct'] = true;
                          });
                        },
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: options[i]['is_correct'] == true
                                  ? const Color(0xFF0A8477)
                                  : const Color(0xFFB0B8C1),
                              width: 2,
                            ),
                          ),
                          child: options[i]['is_correct'] == true
                              ? const Center(
                                  child: Icon(Icons.circle, size: 12, color: Color(0xFF0A8477)),
                                )
                              : null,
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A8477),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (questionCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Soal wajib diisi')),
                  );
                  return;
                }
                final correctIndex = options.indexWhere((o) => o['is_correct'] == true);
                if (correctIndex == -1) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Pilih opsi jawaban yang benar')),
                  );
                  return;
                }
                final hasEmpty = options.any((o) => (o['text'] as String).isEmpty);
                if (hasEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Semua opsi wajib diisi')),
                  );
                  return;
                }
                try {
                  await ApiService.guruAddQuestion(quiz['id'], {
                    'text': questionCtrl.text,
                    'options': options.map((o) => {'text': o['text'], 'is_correct': o['is_correct']}).toList(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetchData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Soal berhasil ditambahkan')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Gagal menambahkan soal')),
                    );
                  }
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteQuiz(Map<String, dynamic> quiz) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Quiz?'),
        content: Text('Yakin ingin menghapus "${quiz['title']}"?\nSemua soal dan hasil juga akan terhapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Color(0xFFC62828))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.guruDeleteQuiz(quiz['id']);
        _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Quiz berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus quiz')),
          );
        }
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kelola Quiz',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                    SizedBox(height: 4),
                    Text('Semua quiz di sistem',
                        style: TextStyle(fontSize: 12, color: Color(0xFF637080))),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE67E22).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_quizzes.length}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFFE67E22)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateQuizDialog,
        backgroundColor: const Color(0xFF0A8477),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Buat Quiz', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
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
              const Icon(Icons.error_outline, size: 56, color: Color(0xFFC62828)),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF637080))),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchData, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }
    if (_quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Belum ada quiz', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF637080))),
            const SizedBox(height: 8),
            const Text('Tap tombol + untuk membuat quiz baru', style: TextStyle(fontSize: 13, color: Color(0xFFB0B8C1))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF0A8477),
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: _quizzes.length,
        itemBuilder: (ctx, i) => _buildQuizCard(_quizzes[i]),
      ),
    );
  }

  Widget _buildQuizCard(Map<String, dynamic> quiz) {
    final questionsCount = quiz['questions_count'] ?? 0;
    final timeLimit = quiz['time_limit'] ?? 10;
    final passingScore = quiz['passing_score'] ?? 70;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE67E22).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.quiz, color: Color(0xFFE67E22), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quiz['title'] ?? '',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (quiz['description'] != null && (quiz['description'] as String).isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          quiz['description'],
                          style: const TextStyle(fontSize: 12, color: Color(0xFF637080)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF0A8477)),
                  onPressed: () => _showEditQuizDialog(quiz),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFC62828)),
                  onPressed: () => _confirmDeleteQuiz(quiz),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(Icons.help_outline, '$questionsCount soal', const Color(0xFF5B6ABF)),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.timer_outlined, '$timeLimit menit', const Color(0xFF0A8477)),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.grade_outlined, 'KKM $passingScore', const Color(0xFFE67E22)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAddQuestionDialog(quiz),
                icon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF0A8477)),
                label: const Text('Tambah Soal', style: TextStyle(color: Color(0xFF0A8477))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0A8477)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
