import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class AdminMateriScreen extends StatefulWidget {
  const AdminMateriScreen({super.key});

  @override
  State<AdminMateriScreen> createState() => _AdminMateriScreenState();
}

class _AdminMateriScreenState extends State<AdminMateriScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _materiList = [];
  List<dynamic> _tpAtpList = [];
  int? _filterTpAtpId;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final tpRes = await ApiService.getTpAtpList();
      final matRes = await ApiService.getMateriList(tpAtpId: _filterTpAtpId);
      if (mounted) {
        setState(() {
          _tpAtpList = tpRes['data'] ?? [];
          _materiList = matRes['data'] ?? [];
          _isLoading = false;
        });
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
    final judulCtrl = TextEditingController(text: existing?['judul'] ?? '');
    final ringkasanCtrl = TextEditingController(text: existing?['ringkasan'] ?? '');
    final kontenCtrl = TextEditingController(text: existing?['konten'] ?? '');
    final estimasiCtrl = TextEditingController(text: (existing?['estimasi_menit'] ?? 15).toString());
    int? selectedTpAtpId = existing?['tp_atp_id'];
    bool isPublished = (existing?['is_published'] == true || existing?['is_published'] == 1) ? true : (existing == null ? true : false);
    String? pickedFilePath;
    String? existingCover = existing?['gambar_cover'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              isEdit ? 'Edit Materi' : 'Tambah Materi',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: selectedTpAtpId,
                      decoration: InputDecoration(
                        labelText: 'Tujuan Pembelajaran (TP/ATP) *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: _tpAtpList.map<DropdownMenuItem<int>>((tp) {
                        return DropdownMenuItem<int>(
                          value: tp['id'],
                          child: Text('${tp['kode']} — ${tp['judul']}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (v) => setDialogState(() => selectedTpAtpId = v),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: judulCtrl,
                      decoration: InputDecoration(
                        labelText: 'Judul Materi *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: ringkasanCtrl,
                      decoration: InputDecoration(
                        labelText: 'Ringkasan',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: kontenCtrl,
                      decoration: InputDecoration(
                        labelText: 'Konten Materi *',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      maxLines: 6,
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: estimasiCtrl,
                      decoration: InputDecoration(
                        labelText: 'Estimasi Waktu (menit)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 14),
                    const Text('Gambar Cover', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF637080))),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final picker = ImagePicker();
                        final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200);
                        if (picked != null) {
                          setDialogState(() => pickedFilePath = picked.path);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE9ECEF)),
                        ),
                        child: pickedFilePath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(File(pickedFilePath!), fit: BoxFit.cover, width: double.infinity),
                              )
                            : existingCover != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.network(
                                      '${ApiService.baseUrl.replaceAll('/api', '')}/storage/$existingCover',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                                    ),
                                  )
                                : _buildImagePlaceholder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      title: const Text('Published', style: TextStyle(fontSize: 14)),
                      value: isPublished,
                      activeTrackColor: const Color(0xFF0A8477),
                      onChanged: (v) => setDialogState(() => isPublished = v),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (selectedTpAtpId == null || judulCtrl.text.isEmpty || kontenCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('TP/ATP, Judul, dan Konten wajib diisi')),
                    );
                    return;
                  }
                  final data = {
                    'tp_atp_id': selectedTpAtpId,
                    'judul': judulCtrl.text,
                    'ringkasan': ringkasanCtrl.text,
                    'konten': kontenCtrl.text,
                    'estimasi_menit': int.tryParse(estimasiCtrl.text) ?? 15,
                    'is_published': isPublished ? 1 : 0,
                  };
                  try {
                    if (isEdit) {
                      await ApiService.guruUpdateMateri(existing['id'], data, filePath: pickedFilePath);
                    } else {
                      await ApiService.guruCreateMateri(data, filePath: pickedFilePath);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);
                    _fetchAll();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(isEdit ? 'Materi berhasil diperbarui' : 'Materi berhasil ditambahkan')),
                      );
                    }
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Gagal menyimpan materi')),
                      );
                    }
                  }
                },
                child: Text(isEdit ? 'Simpan' : 'Tambah'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_outlined, size: 36, color: Color(0xFFB0B8C1)),
        SizedBox(height: 6),
        Text('Tap untuk pilih gambar', style: TextStyle(fontSize: 12, color: Color(0xFFB0B8C1))),
      ],
    );
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Materi?'),
        content: Text('Yakin ingin menghapus "${item['judul']}"?'),
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
        await ApiService.guruDeleteMateri(item['id']);
        _fetchAll();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Materi berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus materi')),
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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kelola Materi',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A8477).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_materiList.length}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0A8477)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<int?>(
                    initialValue: _filterTpAtpId,
                    decoration: InputDecoration(
                      labelText: 'Filter TP/ATP',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('Semua TP/ATP', style: TextStyle(fontSize: 13))),
                      ..._tpAtpList.map<DropdownMenuItem<int?>>((tp) {
                        return DropdownMenuItem<int?>(
                          value: tp['id'],
                          child: Text('${tp['kode']}', style: const TextStyle(fontSize: 13)),
                        );
                      }),
                    ],
                    onChanged: (v) {
                      setState(() => _filterTpAtpId = v);
                      _fetchAll();
                    },
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
        label: const Text('Tambah Materi', style: TextStyle(fontWeight: FontWeight.w600)),
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
              ElevatedButton(onPressed: _fetchAll, child: const Text('Coba Lagi')),
            ],
          ),
        ),
      );
    }
    if (_materiList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text('Belum ada materi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF637080))),
            const SizedBox(height: 8),
            const Text('Tap tombol + untuk menambahkan', style: TextStyle(fontSize: 13, color: Color(0xFFB0B8C1))),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: const Color(0xFF0A8477),
      onRefresh: _fetchAll,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        itemCount: _materiList.length,
        itemBuilder: (ctx, i) => _buildMateriCard(_materiList[i]),
      ),
    );
  }

  Widget _buildMateriCard(Map<String, dynamic> item) {
    final isPublished = item['is_published'] == true || item['is_published'] == 1;
    final hasAr = item['ar_model_id'] != null;
    final tpAtp = item['tp_atp'];
    final estimasi = item['estimasi_menit'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
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
                    if (tpAtp != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B6ABF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          tpAtp['kode'] ?? '',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF5B6ABF)),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPublished
                            ? const Color(0xFF27AE60).withValues(alpha: 0.1)
                            : const Color(0xFFE67E22).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPublished ? 'Published' : 'Draft',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isPublished ? const Color(0xFF27AE60) : const Color(0xFFE67E22),
                        ),
                      ),
                    ),
                    if (hasAr) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A8477).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.view_in_ar, size: 12, color: Color(0xFF0A8477)),
                            SizedBox(width: 3),
                            Text('AR 3D', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF0A8477))),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF0A8477)),
                      onPressed: () => _showFormDialog(existing: item),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFC62828)),
                      onPressed: () => _confirmDelete(item),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item['judul'] ?? '',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (item['ringkasan'] != null && (item['ringkasan'] as String).isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item['ringkasan'],
                    style: const TextStyle(fontSize: 12, color: Color(0xFF637080)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: Color(0xFFB0B8C1)),
                    const SizedBox(width: 4),
                    Text('$estimasi menit', style: const TextStyle(fontSize: 11, color: Color(0xFFB0B8C1))),
                    if (tpAtp != null) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.school_outlined, size: 14, color: Color(0xFFB0B8C1)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          tpAtp['judul'] ?? '',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFB0B8C1)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
