import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'widgets/server_settings_dialog.dart';
import 'screens/admin_tp_atp_screen.dart';
import 'screens/admin_materi_screen.dart';
import 'screens/admin_quiz_management_screen.dart';
import 'screens/admin_hasil_quiz_screen.dart';
import 'screens/admin_ar_management_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/info_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;
  int _totalUsers = 0;
  int _totalGuru = 0;
  int _totalSiswa = 0;
  int _totalQuizzes = 0;
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _users = [];
  String? _userRoleFilter;
  bool _isLoadingUsers = false;
  final TextEditingController _userSearchCtrl = TextEditingController();
  int _arModelCount = 0;
  int _arMarkerCount = 0;
  int _arHotspotCount = 0;
  int _contentVersion = 0;

  @override
  void dispose() {
    _userSearchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final results = await Future.wait(
          [ApiService.getDashboard(), ApiService.adminGetUsers()]).timeout(
        const Duration(seconds: 30),
      );
      if (!mounted) return;
      final dashResult = results[0];
      final usersResult = results[1];
      if (dashResult['unauthorized'] == true ||
          usersResult['unauthorized'] == true) {
        await ApiService.clearToken();
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }
      if (dashResult['success'] == true) {
        final data = dashResult['data'];
        final stats = (data is Map ? data['stats'] : null) as Map? ?? {};
        final udata = usersResult['data'];
        setState(() {
          _totalUsers = (stats['total_users'] as num?)?.toInt() ?? 0;
          _totalGuru = (stats['total_guru'] as num?)?.toInt() ?? 0;
          _totalSiswa = (stats['total_siswa'] as num?)?.toInt() ?? 0;
          _totalQuizzes = (stats['total_quizzes'] as num?)?.toInt() ?? 0;
          _users = udata is List ? udata : [];
          _isLoading = false;
        });
      } else {
        final udata = usersResult['data'];
        setState(() {
          _users = udata is List ? udata : [];
          _isLoading = false;
          _errorMessage =
              (dashResult['message'] as String?) ?? 'Gagal memuat dashboard.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Gagal terhubung ke server. Periksa koneksi lalu coba lagi.';
        });
      }
    }
    _fetchArContentStats();
  }

  Future<void> _fetchArContentStats() async {
    try {
      final versionResult = await ApiService.v1GetContentVersion();
      if (versionResult['success'] == true && mounted) {
        final data = versionResult['data'];
        setState(() {
          _contentVersion = data['content_version'] ?? 0;
        });
      }
      final arContent = await ApiService.v1GetArContent();
      if (arContent['success'] == true && mounted) {
        final data = arContent['data'];
        setState(() {
          _arModelCount = (data['models'] as List?)?.length ?? 0;
          _arMarkerCount = (data['markers'] as List?)?.length ?? 0;
          _arHotspotCount = (data['hotspots'] as List?)?.length ?? 0;
        });
      }
    } catch (_) {}
  }

  Future<void> _openProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final res = await ApiService.adminGetUsers(
        search: _userSearchCtrl.text.trim().isEmpty
            ? null
            : _userSearchCtrl.text.trim(),
        role: _userRoleFilter,
      );
      if (res['success'] == true && mounted) {
        setState(() {
          _users = (res['data'] as List?) ?? [];
          _isLoadingUsers = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingUsers = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingUsers = false);
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

  void _showAddUserDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedRole = 'siswa';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tambah User',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'siswa', child: Text('Siswa')),
                    DropdownMenuItem(value: 'guru', child: Text('Guru')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A8477),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (nameCtrl.text.isEmpty ||
                    emailCtrl.text.isEmpty ||
                    passCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Semua field wajib diisi')),
                  );
                  return;
                }
                final result = await ApiService.adminCreateUser({
                  'name': nameCtrl.text,
                  'email': emailCtrl.text,
                  'password': passCtrl.text,
                  'role': selectedRole,
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                        content: Text(result['message'] ?? 'User ditambahkan'),
                        backgroundColor: const Color(0xFF0A8477)),
                  );
                }
                _loadData();
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(dynamic user) {
    final nameCtrl = TextEditingController(text: user['name']);
    final emailCtrl = TextEditingController(text: user['email']);
    String selectedRole = user['role'] ?? 'siswa';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit User',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'siswa', child: Text('Siswa')),
                    DropdownMenuItem(value: 'guru', child: Text('Guru')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedRole = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A8477),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                final result = await ApiService.adminUpdateUser(user['id'], {
                  'name': nameCtrl.text,
                  'email': emailCtrl.text,
                  'role': selectedRole,
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(
                        content: Text(result['message'] ?? 'User diperbarui'),
                        backgroundColor: const Color(0xFF0A8477)),
                  );
                }
                _loadData();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteUser(dynamic user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus User'),
        content: Text('Hapus "${user['name']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus',
                  style: TextStyle(color: Color(0xFFC62828)))),
        ],
      ),
    );
    if (confirm != true) return;
    await ApiService.adminDeleteUser(user['id']);
    _loadData();
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
            const AdminTpAtpScreen(),
            const AdminMateriScreen(),
            const AdminQuizManagementScreen(),
            const AdminHasilQuizScreen(),
            const AdminArManagementScreen(),
            _buildUsersPage(),
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
        selectedFontSize: 10,
        unselectedFontSize: 10,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Beranda'),
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
              icon: Icon(Icons.assessment_outlined),
              activeIcon: Icon(Icons.assessment),
              label: 'Hasil'),
          BottomNavigationBarItem(
              icon: Icon(Icons.view_in_ar_outlined),
              activeIcon: Icon(Icons.view_in_ar),
              label: 'AR'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outlined),
              activeIcon: Icon(Icons.people),
              label: 'Users'),
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
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined,
                  size: 48, color: Color(0xFFB0B8C1)),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF637080)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A8477),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Admin Panel 👋',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 4),
          const Text('Kelola seluruh sistem',
              style: TextStyle(fontSize: 14, color: Color(0xFF637080))),
          const SizedBox(height: 24),
          const Text('User Management',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          _buildStatCard(
              icon: Icons.people_outline,
              title: 'Total Users',
              count: '$_totalUsers',
              color: const Color(0xFF0A8477)),
          const SizedBox(height: 10),
          _buildStatCard(
              icon: Icons.school_outlined,
              title: 'Guru',
              count: '$_totalGuru',
              color: const Color(0xFF5B6ABF)),
          const SizedBox(height: 10),
          _buildStatCard(
              icon: Icons.person_outline,
              title: 'Siswa',
              count: '$_totalSiswa',
              color: const Color(0xFFE67E22)),
          const SizedBox(height: 24),
          const Text('Sistem',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          _buildStatCard(
              icon: Icons.quiz_outlined,
              title: 'Quiz',
              count: '$_totalQuizzes',
              color: const Color(0xFFC62828)),
          const SizedBox(height: 24),
          const Text('Konten AR',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 12),
          _buildStatCard(
              icon: Icons.view_in_ar_outlined,
              title: '3D Models',
              count: '$_arModelCount',
              color: const Color(0xFF5B6ABF)),
          const SizedBox(height: 10),
          _buildStatCard(
              icon: Icons.qr_code_scanner,
              title: 'Markers',
              count: '$_arMarkerCount',
              color: const Color(0xFFE67E22)),
          const SizedBox(height: 10),
          _buildStatCard(
              icon: Icons.place_outlined,
              title: 'Hotspots',
              count: '$_arHotspotCount',
              color: const Color(0xFF0A8477)),
          const SizedBox(height: 10),
          _buildStatCard(
              icon: Icons.numbers,
              title: 'Content Version',
              count: '$_contentVersion',
              color: const Color(0xFF637080)),
          const SizedBox(height: 20),
          const Text('Aksi Cepat',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 14),
          _buildQuickAction(
              icon: Icons.school_outlined,
              title: 'Kelola TP/ATP',
              color: const Color(0xFF5B6ABF),
              onTap: () => setState(() => _currentIndex = 1)),
          const SizedBox(height: 10),
          _buildQuickAction(
              icon: Icons.menu_book_outlined,
              title: 'Kelola Materi',
              color: const Color(0xFF0A8477),
              onTap: () => setState(() => _currentIndex = 2)),
          const SizedBox(height: 10),
          _buildQuickAction(
              icon: Icons.quiz_outlined,
              title: 'Kelola Quiz',
              color: const Color(0xFFE67E22),
              onTap: () => setState(() => _currentIndex = 3)),
          const SizedBox(height: 10),
          _buildQuickAction(
              icon: Icons.assessment_outlined,
              title: 'Lihat Hasil Quiz',
              color: const Color(0xFFC62828),
              onTap: () => setState(() => _currentIndex = 4)),
          const SizedBox(height: 10),
          _buildQuickAction(
              icon: Icons.view_in_ar_outlined,
              title: 'Kelola AR',
              color: const Color(0xFF5B6ABF),
              onTap: () => setState(() => _currentIndex = 5)),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      {required IconData icon,
      required String title,
      required String count,
      required Color color}) {
    return Container(
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
      child: Row(children: [
        Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24)),
        const SizedBox(width: 16),
        Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E)))),
        Text(count,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
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

  Widget _buildUsersPage() {
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
              const Text('Semua Users',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              ElevatedButton.icon(
                onPressed: _showAddUserDialog,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A8477),
                    foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userSearchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Cari nama/email...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _fetchUsers(),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<String?>(
                value: _userRoleFilter,
                hint: const Text('Role'),
                items: const [
                  DropdownMenuItem<String?>(value: null, child: Text('Semua')),
                  DropdownMenuItem<String?>(
                      value: 'admin', child: Text('Admin')),
                  DropdownMenuItem<String?>(value: 'guru', child: Text('Guru')),
                  DropdownMenuItem<String?>(
                      value: 'siswa', child: Text('Siswa')),
                ],
                onChanged: (v) {
                  setState(() => _userRoleFilter = v);
                  _fetchUsers();
                },
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _isLoadingUsers ? null : _fetchUsers,
                icon: _isLoadingUsers
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                tooltip: 'Cari',
              ),
            ],
          ),
        ),
        Expanded(
          child: _users.isEmpty
              ? const Center(
                  child: Text('Belum ada user',
                      style: TextStyle(color: Color(0xFF637080))))
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _users.length,
                  itemBuilder: (ctx, i) {
                    final user = _users[i];
                    final roleColor = user['role'] == 'admin'
                        ? const Color(0xFFC62828)
                        : user['role'] == 'guru'
                            ? const Color(0xFF5B6ABF)
                            : const Color(0xFF0A8477);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: roleColor.withValues(alpha: 0.1),
                          child: Text(
                            (user['name'] ?? '?')[0].toUpperCase(),
                            style: TextStyle(
                                color: roleColor, fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(user['name'] ?? '',
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(user['email'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(user['role'] ?? '',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: roleColor)),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined,
                                  size: 20, color: Color(0xFF637080)),
                              onPressed: () => _showEditUserDialog(user),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20, color: Color(0xFFC62828)),
                              onPressed: () => _deleteUser(user),
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
            backgroundColor: const Color(0xFFC62828).withValues(alpha: 0.1),
            child: const Icon(Icons.admin_panel_settings,
                size: 48, color: Color(0xFFC62828))),
        const SizedBox(height: 16),
        const Text('Admin',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E))),
        const SizedBox(height: 4),
        const Text('Administrator',
            style: TextStyle(fontSize: 14, color: Color(0xFF637080))),
        const SizedBox(height: 32),
        _buildProfileOption(
            icon: Icons.person_outline,
            title: 'Profil Saya',
            onTap: _openProfile),
        _buildProfileOption(
            icon: Icons.help_outline,
            title: 'Bantuan',
            onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InfoScreen.help()),
                )),
        _buildProfileOption(
            icon: Icons.info_outline,
            title: 'Tentang',
            onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InfoScreen.about()),
                )),
        // Hanya admin yang boleh ubah URL server (disembunyikan dari
        // layar Login/Register agar tidak diutak-atik siswa).
        _buildProfileOption(
            icon: Icons.dns_outlined,
            title: 'Pengaturan Server',
            onTap: () async {
              await ServerSettingsDialog.show(context);
              if (mounted) setState(() {});
            }),
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
