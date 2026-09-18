import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/api_service.dart';
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
  bool _isLoading = true;
  List<dynamic> _quizzes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('userName') ?? 'Guru';
    try {
      final dashResult = await ApiService.getDashboard();
      final quizResult = await ApiService.guruGetQuizzes();
      if (mounted) {
        setState(() {
          _totalQuizzes = dashResult['data']['stats']['total_quizzes'] ?? 0;
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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout', style: TextStyle(color: Color(0xFFC62828)))),
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
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Judul Quiz', hintText: 'Masukkan judul')),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Deskripsi'), maxLines: 2),
              const SizedBox(height: 12),
              TextField(controller: timeCtrl, decoration: const InputDecoration(labelText: 'Batas Waktu (menit)'), keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              TextField(controller: scoreCtrl, decoration: const InputDecoration(labelText: 'Passing Score'), keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
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

  void _showAddQuestionDialog(Quiz quiz) {
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
                TextField(controller: questionCtrl, decoration: const InputDecoration(labelText: 'Soal'), maxLines: 2),
                const SizedBox(height: 16),
                ...List.generate(options.length, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(labelText: 'Opsi ${i + 1}'),
                          onChanged: (v) => options[i]['text'] = v,
                        ),
                      ),
                      Radio<bool>(
                        value: true,
                        groupValue: options[i]['is_correct'],
                        onChanged: (v) {
                          setDialogState(() {
                            for (var o in options) {
                              o['is_correct'] = false;
                            }
                            options[i]['is_correct'] = true;
                          });
                        },
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
              onPressed: () async {
                if (questionCtrl.text.isEmpty) return;
                final correctIndex = options.indexWhere((o) => o['is_correct'] == true);
                if (correctIndex == -1) return;
                await ApiService.guruAddQuestion(quiz.id!, {
                  'text': questionCtrl.text,
                  'options': options.map((o) => {'text': o['text'], 'is_correct': o['is_correct']}).toList(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Tambah'),
            ),
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.school_outlined), activeIcon: Icon(Icons.school), label: 'TP/ATP'),
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), activeIcon: Icon(Icons.menu_book), label: 'Materi'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz_outlined), activeIcon: Icon(Icons.quiz), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.view_in_ar_outlined), activeIcon: Icon(Icons.view_in_ar), label: 'AR'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildHome() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF0A8477)));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Halo, $_userName 👋', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          const Text('Kelola pembelajaran Anda', style: TextStyle(fontSize: 14, color: Color(0xFF637080))),
          const SizedBox(height: 24),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('$_totalQuizzes', 'Quiz', const Color(0xFFE67E22)),
                _buildSummaryItem('0', 'Materi', const Color(0xFF0A8477)),
                _buildSummaryItem('0', 'AR', const Color(0xFF5B6ABF)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Aksi Cepat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 14),
          _buildQuickAction(icon: Icons.add_circle_outline, title: 'Buat Quiz', color: const Color(0xFFE67E22), onTap: () => setState(() => _currentIndex = 3)),
          const SizedBox(height: 10),
          _buildQuickAction(icon: Icons.menu_book_outlined, title: 'Tambah Materi', color: const Color(0xFF0A8477), onTap: () => setState(() => _currentIndex = 2)),
          const SizedBox(height: 10),
          _buildQuickAction(icon: Icons.school_outlined, title: 'Kelola TP/ATP', color: const Color(0xFF5B6ABF), onTap: () => setState(() => _currentIndex = 1)),
          const SizedBox(height: 10),
          _buildQuickAction(icon: Icons.view_in_ar_outlined, title: 'Kelola AR', color: const Color(0xFF5B6ABF), onTap: () => setState(() => _currentIndex = 4)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String count, String label, Color color) {
    return Column(children: [
      Text(count, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF637080))),
    ]);
  }

  Widget _buildQuickAction({required IconData icon, required String title, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [Icon(icon, color: color, size: 22), const SizedBox(width: 12), Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color))]),
      ),
    );
  }

  Widget _buildQuizManagement() {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF0A8477)));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quiz Saya', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              ElevatedButton.icon(
                onPressed: _showCreateQuizDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Buat Quiz'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A8477), foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _quizzes.isEmpty
              ? const Center(child: Text('Belum ada quiz', style: TextStyle(color: Color(0xFF637080))))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _quizzes.length,
                  itemBuilder: (ctx, i) {
                    final quiz = _quizzes[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: const Color(0xFFE67E22).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.quiz, color: Color(0xFFE67E22), size: 20),
                        ),
                        title: Text(quiz['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${quiz['questions_count'] ?? 0} soal'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF0A8477)),
                              onPressed: () => _showAddQuestionDialog(Quiz.fromMap(quiz)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFC62828)),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Hapus Quiz'),
                                    content: Text('Hapus "${quiz['title']}"?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Color(0xFFC62828)))),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await ApiService.guruDeleteQuiz(quiz['id']);
                                  _loadData();
                                }
                              },
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
        CircleAvatar(radius: 48, backgroundColor: const Color(0xFF0A8477).withValues(alpha: 0.1), child: const Icon(Icons.person, size: 48, color: Color(0xFF0A8477))),
        const SizedBox(height: 16),
        Text(_userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 4),
        const Text('Guru', style: TextStyle(fontSize: 14, color: Color(0xFF637080))),
        const SizedBox(height: 32),
        _buildProfileOption(icon: Icons.person_outline, title: 'Profil Saya', onTap: () {}),
        _buildProfileOption(icon: Icons.help_outline, title: 'Bantuan', onTap: () {}),
        _buildProfileOption(icon: Icons.info_outline, title: 'Tentang', onTap: () {}),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Color(0xFFC62828)),
            label: const Text('Logout', style: TextStyle(color: Color(0xFFC62828))),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFFC62828)), padding: const EdgeInsets.all(14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          ),
        ),
      ]),
    );
  }

  Widget _buildProfileOption({required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF0A8477)),
        title: Text(title, style: const TextStyle(fontSize: 15, color: Color(0xFF1A1A2E))),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFD0D5D8)),
        onTap: onTap, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), tileColor: Colors.white,
      ),
    );
  }
}

class Quiz {
  final int? id;
  final String? title;
  Quiz({this.id, this.title});
  factory Quiz.fromMap(Map<String, dynamic> m) => Quiz(id: m['id'], title: m['title']);
}