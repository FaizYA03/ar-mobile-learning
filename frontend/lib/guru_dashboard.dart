import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/models.dart';
import 'services/api_service.dart';
import 'services/secure_storage_service.dart';
import 'screens/guru_tp_atp_screen.dart';
import 'screens/guru_materi_screen.dart';
import 'screens/guru_ar_management_screen.dart';

class GuruDashboard extends StatefulWidget {
  const GuruDashboard({super.key});

  @override
  State<GuruDashboard> createState() => _GuruDashboardState();
}

class _GuruDashboardState extends State<GuruDashboard> {
  int _currentIndex = 0;
  String _userName = 'Guru';
  int _totalQuizzes = 0;
  int _totalMateri = 0;
  int _totalAr = 0;
  bool _isLoading = true;
  List<dynamic> _quizzes = [];
  String _lastSyncText = 'Belum pernah sync';
  int _cachedModelCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    _userName = await SecureStorageService.getUserName() ?? 'Guru';

    final prefs = await SharedPreferences.getInstance();
    final lastSyncMs = prefs.getInt('content_last_sync');
    if (lastSyncMs != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(lastSyncMs);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) {
        _lastSyncText = 'Baru saja';
      } else if (diff.inHours < 1) {
        _lastSyncText = '${diff.inMinutes} menit lalu';
      } else if (diff.inDays < 1) {
        _lastSyncText = '${diff.inHours} jam lalu';
      } else {
        _lastSyncText = '${diff.inDays} hari lalu';
      }
    }
    _cachedModelCount = prefs.getInt('cached_ar_model_count') ?? 0;

    try {
      final dashResult = await ApiService.getDashboard();
      final quizResult = await ApiService.guruGetQuizzes();
      if (mounted) {
        setState(() {
          _totalQuizzes = dashResult['data']['stats']['total_quizzes'] ?? 0;
          _totalMateri = dashResult['data']['stats']['total_materi'] ?? 0;
          _totalAr = dashResult['data']['stats']['total_ar_models'] ?? 0;
          _quizzes = quizResult['data'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin logout?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Logout',
                  style: TextStyle(color: Color(0xFFC62828)))),
        ],
      ),
    );
    if (confirm != true) return;
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _showCreateQuizDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final timeCtrl = TextEditingController(text: '10');
    final scoreCtrl = TextEditingController(text: '70');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buat Quiz Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Judul Quiz', hintText: 'Masukkan judul')),
              const SizedBox(height: 12),
              TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Deskripsi'),
                  maxLines: 2),
              const SizedBox(height: 12),
              TextField(
                  controller: timeCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Batas Waktu (menit)'),
                  keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(
                  controller: scoreCtrl,
                  decoration: const InputDecoration(labelText: 'Passing Score'),
                  keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (titleCtrl.text.isEmpty) return;
              await ApiService.guruCreateQuiz({
                'title': titleCtrl.text,
                'description': descCtrl.text,
                'time_limit': int.tryParse(timeCtrl.text) ?? 10,
                'passing_score': int.tryParse(scoreCtrl.text) ?? 70,
              });
              if (ctx.mounted) Navigator.pop(ctx);
              _loadData();
            },
            child: const Text('Buat'),
          ),
        ],
      ),
    );
  }

  void _showAddQuestionDialog(QuizItem quiz) {
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
          title: Text('Tambah Soal - ${quiz.title}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: questionCtrl,
                    decoration: const InputDecoration(labelText: 'Soal'),
                    maxLines: 2),
                const SizedBox(height: 16),
                ...List.generate(
                    options.length,
                    (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                      labelText: 'Opsi ${i + 1}'),
                                  onChanged: (v) => options[i]['text'] = v,
                                ),
                              ),
                              RadioGroup<bool>(
                                groupValue: options[i]['is_correct'],
                                onChanged: (v) {
                                  setDialogState(() {
                                    for (var o in options) {
                                      o['is_correct'] = false;
                                    }
                                    options[i]['is_correct'] = true;
                                  });
                                },
                                child: Radio<bool>(value: true),
                              ),
                            ],
                          ),
                        )),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (questionCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Soal wajib diisi')),
                  );
                  return;
                }
                if (options.any((o) => (o['text'] as String).trim().isEmpty)) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Semua opsi wajib diisi')),
                  );
                  return;
                }
                final correctIndex =
                    options.indexWhere((o) => o['is_correct'] == true);
                if (correctIndex == -1) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Pilih opsi jawaban yang benar')),
                  );
                  return;
                }
                try {
                  await ApiService.guruAddQuestion(quiz.id, {
                    'text': questionCtrl.text.trim(),
                    'options': options
                        .map((o) =>
                            {'text': o['text'], 'is_correct': o['is_correct']})
                        .toList(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Soal berhasil ditambahkan')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Gagal menambah soal: $e')),
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

  Future<void> _showQuestionsDialog(Map<String, dynamic> quiz) async {
    List<QuizQuestion> questions = [];
    bool loading = true;

    try {
      final response = await ApiService.getQuiz(quiz['id']);
      if (response['success'] == true) {
        final data = response['data'];
        questions = (data['questions'] as List<dynamic>? ?? [])
            .map((q) => QuizQuestion.fromJson(q))
            .toList();
      }
    } catch (_) {}

    loading = false;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Soal: ${quiz['title'] ?? ''}',
              style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                  fontSize: 16)),
          content: SizedBox(
            width: double.maxFinite,
            child: loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF0A8477)))
                : questions.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Belum ada soal',
                              style: TextStyle(color: Color(0xFF637080))),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: questions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final q = questions[i];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: const Color(0xFF5B6ABF)
                                      .withValues(alpha: 0.15),
                                  child: Text('${i + 1}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF5B6ABF))),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(q.text,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF1A1A2E)),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18, color: Color(0xFFC62828)),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: ctx,
                                      builder: (dCtx) => AlertDialog(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12)),
                                        title: const Text('Hapus Soal?'),
                                        content: Text(
                                            'Yakin ingin menghapus soal ${i + 1}?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(dCtx, false),
                                              child: const Text('Batal')),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(dCtx, true),
                                            child: const Text('Hapus',
                                                style: TextStyle(
                                                    color: Color(0xFFC62828))),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      try {
                                        await ApiService.guruDeleteQuestion(
                                            q.id);
                                        setDialogState(
                                            () => questions.removeAt(i));
                                        _loadData();
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Soal berhasil dihapus')),
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Gagal menghapus soal')),
                                          );
                                        }
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHome(),
            const GuruTpAtpScreen(),
            const GuruMateriScreen(),
            _buildQuizManagement(),
            const GuruArManagementScreen(),
            _buildProfile(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0A8477),
        unselectedItemColor: const Color(0xFFB0B8C1),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school),
              label: 'TP/ATP'),
          BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              activeIcon: Icon(Icons.menu_book),
              label: 'Materi'),
          BottomNavigationBarItem(
              icon: Icon(Icons.quiz_outlined),
              activeIcon: Icon(Icons.quiz),
              label: 'Quiz'),
          BottomNavigationBarItem(
              icon: Icon(Icons.view_in_ar_outlined),
              activeIcon: Icon(Icons.view_in_ar),
              label: 'AR'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A8477)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Halo, $_userName 👋',
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          const Text('Kelola pembelajaran Anda',
              style: TextStyle(fontSize: 14, color: Color(0xFF637080))),
          const SizedBox(height: 24),
          _buildSyncStatusCard(),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                    '$_totalQuizzes', 'Quiz', const Color(0xFFE67E22)),
                _buildSummaryItem(
                    '$_totalMateri', 'Materi', const Color(0xFF0A8477)),
                _buildSummaryItem('$_totalAr', 'AR', const Color(0xFF5B6ABF)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Aksi Cepat',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 14),
          _buildQuickAction(
              icon: Icons.add_circle_outline,
              title: 'Buat Quiz',
              color: const Color(0xFFE67E22),
              onTap: () => setState(() => _currentIndex = 3)),
          const SizedBox(height: 10),
          _buildQuickAction(
              icon: Icons.menu_book_outlined,
              title: 'Tambah Materi',
              color: const Color(0xFF0A8477),
              onTap: () => setState(() => _currentIndex = 2)),
          const SizedBox(height: 10),
          _buildQuickAction(
              icon: Icons.school_outlined,
              title: 'Kelola TP/ATP',
              color: const Color(0xFF5B6ABF),
              onTap: () => setState(() => _currentIndex = 1)),
          const SizedBox(height: 10),
          _buildQuickAction(
              icon: Icons.view_in_ar_outlined,
              title: 'Kelola AR',
              color: const Color(0xFF5B6ABF),
              onTap: () => setState(() => _currentIndex = 4)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String count, String label, Color color) {
    return Column(children: [
      Text(count,
          style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 4),
      Text(label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF637080))),
    ]);
  }

  Widget _buildQuickAction(
      {required IconData icon,
      required String title,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Text(title,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: color))
        ]),
      ),
    );
  }

  Widget _buildSyncStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: const Color(0xFF0A8477).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.sync, color: Color(0xFF0A8477), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sinkronisasi Konten',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text('Terakhir: $_lastSyncText',
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF637080))),
              ],
            ),
          ),
          if (_cachedModelCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: const Color(0xFF5B6ABF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6)),
              child: Text('$_cachedModelCount model',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5B6ABF))),
            ),
        ],
      ),
    );
  }

  Widget _buildQuizManagement() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF0A8477)));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quiz Saya',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              ElevatedButton.icon(
                onPressed: _showCreateQuizDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Buat Quiz'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A8477),
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _quizzes.isEmpty
              ? const Center(
                  child: Text('Belum ada quiz',
                      style: TextStyle(color: Color(0xFF637080))))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _quizzes.length,
                  itemBuilder: (ctx, i) {
                    final quiz = _quizzes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                                      color: const Color(0xFFE67E22)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.quiz,
                                      color: Color(0xFFE67E22), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(quiz['title'] ?? '',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      Text(
                                          '${quiz['questions_count'] ?? 0} soal',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF637080))),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20, color: Color(0xFFC62828)),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Hapus Quiz'),
                                        content:
                                            Text('Hapus "${quiz['title']}"?'),
                                        actions: [
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, false),
                                              child: const Text('Batal')),
                                          TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(ctx, true),
                                              child: const Text('Hapus',
                                                  style: TextStyle(
                                                      color:
                                                          Color(0xFFC62828)))),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await ApiService.guruDeleteQuiz(
                                          quiz['id']);
                                      _loadData();
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showQuestionsDialog(quiz),
                                    icon: const Icon(Icons.visibility_outlined,
                                        size: 16, color: Color(0xFF5B6ABF)),
                                    label: const Text('Lihat Soal',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF5B6ABF))),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: Color(0xFF5B6ABF)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showAddQuestionDialog(
                                        QuizItem(
                                            id: quiz['id'],
                                            title: quiz['title'] ?? '')),
                                    icon: const Icon(Icons.add_circle_outline,
                                        size: 16, color: Color(0xFF0A8477)),
                                    label: const Text('Tambah Soal',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF0A8477))),
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                          color: Color(0xFF0A8477)),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildProfile() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const SizedBox(height: 20),
        CircleAvatar(
            radius: 48,
            backgroundColor: const Color(0xFF0A8477).withValues(alpha: 0.1),
            child:
                const Icon(Icons.person, size: 48, color: Color(0xFF0A8477))),
        const SizedBox(height: 16),
        Text(_userName,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 4),
        const Text('Guru',
            style: TextStyle(fontSize: 14, color: Color(0xFF637080))),
        const SizedBox(height: 32),
        _buildProfileOption(
            icon: Icons.person_outline, title: 'Profil Saya', onTap: () {}),
        _buildProfileOption(
            icon: Icons.help_outline, title: 'Bantuan', onTap: () {}),
        _buildProfileOption(
            icon: Icons.info_outline, title: 'Tentang', onTap: () {}),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Color(0xFFC62828)),
            label: const Text('Logout',
                style: TextStyle(color: Color(0xFFC62828))),
            style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFC62828)),
                padding: const EdgeInsets.all(14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ]),
    );
  }

  Widget _buildProfileOption(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0A8477)),
        title: Text(title,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E))),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFD0D5D8)),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: Colors.white,
      ),
    );
  }
}
