import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminTpAtpScreen extends StatefulWidget {
  const AdminTpAtpScreen({super.key});

  @override
  State<AdminTpAtpScreen> createState() => _AdminTpAtpScreenState();
}

class _AdminTpAtpScreenState extends State<AdminTpAtpScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _tpAtpList = [];

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
      final response = await ApiService.getTpAtpList();
      if (response['success'] == true && mounted) {
        setState(() {
          _tpAtpList = response['data'] ?? [];
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

  void _showFormDialog({Map<String, dynamic>? existing}) {
    final isEdit = existing != null;
    final kodeCtrl = TextEditingController(text: existing?['kode'] ?? '');
    final faseCtrl = TextEditingController(text: existing?['fase'] ?? 'E');
    final elemenCtrl = TextEditingController(text: existing?['elemen'] ?? '');
    final judulCtrl = TextEditingController(text: existing?['judul'] ?? '');
    final deskripsiCtrl =
        TextEditingController(text: existing?['deskripsi'] ?? '');
    bool isActive = existing?['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isEdit ? 'Edit TP/ATP' : 'Tambah TP/ATP',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: kodeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Kode *',
                    hintText: 'e.g. TP-SK-01',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: faseCtrl,
                  decoration: InputDecoration(
                    labelText: 'Fase',
                    hintText: 'e.g. E',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: elemenCtrl,
                  decoration: InputDecoration(
                    labelText: 'Elemen *',
                    hintText: 'e.g. Sistem Komputer',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: judulCtrl,
                  decoration: InputDecoration(
                    labelText: 'Judul *',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: deskripsiCtrl,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Status Aktif',
                      style: TextStyle(fontSize: 14)),
                  value: isActive,
                  activeTrackColor: const Color(0xFF0A8477),
                  onChanged: (v) => setDialogState(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A8477),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (kodeCtrl.text.isEmpty ||
                    elemenCtrl.text.isEmpty ||
                    judulCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                        content: Text('Kode, Elemen, dan Judul wajib diisi')),
                  );
                  return;
                }
                final data = {
                  'kode': kodeCtrl.text,
                  'fase': faseCtrl.text,
                  'elemen': elemenCtrl.text,
                  'judul': judulCtrl.text,
                  'deskripsi': deskripsiCtrl.text,
                  'is_active': isActive ? 1 : 0,
                };
                try {
                  if (isEdit) {
                    await ApiService.guruUpdateTpAtp(existing['id'], data);
                  } else {
                    await ApiService.guruCreateTpAtp(data);
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  _fetchData();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(isEdit
                              ? 'TP/ATP berhasil diperbarui'
                              : 'TP/ATP berhasil ditambahkan')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Gagal menyimpan data')),
                    );
                  }
                }
              },
              child: Text(isEdit ? 'Simpan' : 'Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus TP/ATP?'),
        content: Text(
            'Yakin ingin menghapus "${item['judul']}"?\nSemua materi terkait juga akan terhapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child:
                const Text('Hapus', style: TextStyle(color: Color(0xFFC62828))),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await ApiService.guruDeleteTpAtp(item['id']);
        _fetchData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('TP/ATP berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus data')),
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
                    Text('Kelola TP/ATP',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E))),
                    SizedBox(height: 4),
                    Text('Semua Tujuan Pembelajaran di sistem',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF637080))),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A8477).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_tpAtpList.length}',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A8477)),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(),
        backgroundColor: const Color(0xFF0A8477),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Tambah TP/ATP',
            style: TextStyle(fontWeight: FontWeight.w600)),
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
    if (_tpAtpList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_open_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Belum ada TP/ATP',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF637080))),
            const SizedBox(height: 8),
            const Text('Tap tombol + untuk menambahkan',
                style: TextStyle(fontSize: 13, color: Color(0xFFB0B8C1))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF0A8477),
      onRefresh: _fetchData,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: _tpAtpList.length,
        itemBuilder: (ctx, i) => _buildTpAtpCard(_tpAtpList[i]),
      ),
    );
  }

  Widget _buildTpAtpCard(Map<String, dynamic> item) {
    final isActive = item['is_active'] == true || item['is_active'] == 1;
    final materiCount = item['materi_count'] ??
        (item['materi'] is List ? (item['materi'] as List).length : 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showFormDialog(existing: item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A8477).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item['kode'] ?? '',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0A8477)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item['fase'] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B6ABF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Fase ${item['fase']}',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF5B6ABF)),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF27AE60).withValues(alpha: 0.1)
                            : const Color(0xFFC62828).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isActive ? 'Aktif' : 'Nonaktif',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? const Color(0xFF27AE60)
                              : const Color(0xFFC62828),
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          size: 20, color: Color(0xFF0A8477)),
                      onPressed: () => _showFormDialog(existing: item),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Color(0xFFC62828)),
                      onPressed: () => _confirmDelete(item),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  item['elemen'] ?? '',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF637080)),
                ),
                const SizedBox(height: 4),
                Text(
                  item['judul'] ?? '',
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item['deskripsi'] != null &&
                    (item['deskripsi'] as String).isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item['deskripsi'],
                    style:
                        const TextStyle(fontSize: 12, color: Color(0xFF637080)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.menu_book_outlined,
                        size: 16, color: Color(0xFF0A8477)),
                    const SizedBox(width: 6),
                    Text(
                      '$materiCount materi',
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0A8477)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
