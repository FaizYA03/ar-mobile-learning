import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminArManagementScreen extends StatefulWidget {
  const AdminArManagementScreen({super.key});

  @override
  State<AdminArManagementScreen> createState() => _AdminArManagementScreenState();
}

class _AdminArManagementScreenState extends State<AdminArManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<dynamic> _models = [];
  List<dynamic> _markers = [];
  List<dynamic> _hotspots = [];
  List<dynamic> _mappings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.arGetModels(),
        ApiService.arGetMarkers(),
        ApiService.arGetHotspots(),
        ApiService.arGetMappings(),
      ]);
      if (mounted) {
        setState(() {
          _models = results[0]['data'] ?? [];
          _markers = results[1]['data'] ?? [];
          _hotspots = results[2]['data'] ?? [];
          _mappings = results[3]['data']?['markers'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('AR Management', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF0A8477),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(icon: Icon(Icons.view_in_ar_outlined, size: 20), text: 'Model'),
            Tab(icon: Icon(Icons.qr_code_scanner, size: 20), text: 'Marker'),
            Tab(icon: Icon(Icons.place_outlined, size: 20), text: 'Hotspot'),
            Tab(icon: Icon(Icons.link, size: 20), text: 'Mapping'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0A8477)))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildModelsTab(),
                _buildMarkersTab(),
                _buildHotspotsTab(),
                _buildMappingsTab(),
              ],
            ),
    );
  }

  // ========== MODELS TAB ==========
  Widget _buildModelsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('3D Models (${_models.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              ElevatedButton.icon(
                onPressed: () => _showModelDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A8477), foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _models.isEmpty
              ? const Center(child: Text('Belum ada 3D model', style: TextStyle(color: Color(0xFF637080))))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _models.length,
                    itemBuilder: (ctx, i) => _buildModelCard(_models[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildModelCard(dynamic model) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5B6ABF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.view_in_ar, color: Color(0xFF5B6ABF), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model['model_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(model['category'] ?? '-', style: const TextStyle(fontSize: 12, color: Color(0xFF637080))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (model['is_active'] == true ? const Color(0xFF0A8477) : const Color(0xFFB0B8C1)).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    model['is_active'] == true ? 'Aktif' : 'Nonaktif',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      color: model['is_active'] == true ? const Color(0xFF0A8477) : const Color(0xFFB0B8C1),
                    ),
                  ),
                ),
              ],
            ),
            if (model['description'] != null && (model['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(model['description'], style: const TextStyle(fontSize: 13, color: Color(0xFF637080)), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _buildInfoChip(Icons.folder_open, model['glb_path'] ?? '-'),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.place, '${model['hotspots_count'] ?? 0} hotspot'),
                const SizedBox(width: 8),
                _buildInfoChip(Icons.qr_code, '${model['markers_count'] ?? 0} marker'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF637080)),
                  onPressed: () => _showModelDialog(model: model),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFC62828)),
                  onPressed: () => _confirmDeleteModel(model),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showModelDialog({dynamic model}) {
    final nameCtrl = TextEditingController(text: model?['model_name'] ?? '');
    final glbCtrl = TextEditingController(text: model?['glb_path'] ?? '');
    final thumbCtrl = TextEditingController(text: model?['thumbnail_path'] ?? '');
    final descCtrl = TextEditingController(text: model?['description'] ?? '');
    final catCtrl = TextEditingController(text: model?['category'] ?? '');
    bool isActive = model?['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(model == null ? 'Tambah 3D Model' : 'Edit 3D Model',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: InputDecoration(labelText: 'Nama Model', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 12),
                TextField(controller: glbCtrl, decoration: InputDecoration(labelText: 'GLB Path', hintText: 'models/nama_model.glb', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 12),
                TextField(controller: thumbCtrl, decoration: InputDecoration(labelText: 'Thumbnail Path', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), maxLines: 2),
                const SizedBox(height: 12),
                TextField(controller: catCtrl, decoration: InputDecoration(labelText: 'Kategori', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Aktif', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Switch(value: isActive, onChanged: (v) => setDialogState(() => isActive = v), activeThumbColor: const Color(0xFF0A8477)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A8477), foregroundColor: Colors.white),
              onPressed: () async {
                if (nameCtrl.text.isEmpty || glbCtrl.text.isEmpty) return;
                final data = {
                  'model_name': nameCtrl.text,
                  'glb_path': glbCtrl.text,
                  'thumbnail_path': thumbCtrl.text,
                  'description': descCtrl.text,
                  'category': catCtrl.text,
                  'is_active': isActive,
                };
                if (model == null) {
                  await ApiService.arCreateModel(data);
                } else {
                  await ApiService.arUpdateModel(model['id'], data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteModel(dynamic model) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Model'),
        content: Text('Hapus "${model['model_name']}"? Semua hotspot terkait juga akan dihapus.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Color(0xFFC62828)))),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.arDeleteModel(model['id']);
      _loadData();
    }
  }

  // ========== MARKERS TAB ==========
  Widget _buildMarkersTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('AR Markers (${_markers.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              ElevatedButton.icon(
                onPressed: () => _showMarkerDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A8477), foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _markers.isEmpty
              ? const Center(child: Text('Belum ada marker', style: TextStyle(color: Color(0xFF637080))))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _markers.length,
                    itemBuilder: (ctx, i) => _buildMarkerCard(_markers[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMarkerCard(dynamic marker) {
    final statusColor = marker['status'] == 'active' ? const Color(0xFF0A8477) : const Color(0xFFB0B8C1);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.qr_code_scanner, color: statusColor, size: 22),
        ),
        title: Text(marker['marker_id'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF5B6ABF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(marker['marker_type'] ?? '', style: const TextStyle(fontSize: 11, color: Color(0xFF5B6ABF))),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(marker['status'] ?? '', style: TextStyle(fontSize: 11, color: statusColor)),
                ),
                const SizedBox(width: 6),
                Text('${marker['models_count'] ?? 0} model', style: const TextStyle(fontSize: 11, color: Color(0xFF637080))),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF637080)),
              onPressed: () => _showMarkerDialog(marker: marker),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFC62828)),
              onPressed: () => _confirmDeleteMarker(marker),
            ),
          ],
        ),
      ),
    );
  }

  void _showMarkerDialog({dynamic marker}) {
    final markerIdCtrl = TextEditingController(text: marker?['marker_id'] ?? '');
    final imagePathCtrl = TextEditingController(text: marker?['image_path'] ?? '');
    String markerType = marker?['marker_type'] ?? 'pattern';
    String status = marker?['status'] ?? 'active';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(marker == null ? 'Tambah Marker' : 'Edit Marker',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: markerIdCtrl, decoration: InputDecoration(labelText: 'Marker ID', hintText: 'MARKER-XXX-001', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: markerType,
                  decoration: InputDecoration(labelText: 'Tipe', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: const [
                    DropdownMenuItem(value: 'pattern', child: Text('Pattern (Gambar)')),
                    DropdownMenuItem(value: 'image', child: Text('Image (Foto)')),
                  ],
                  onChanged: (v) => setDialogState(() => markerType = v!),
                ),
                const SizedBox(height: 12),
                TextField(controller: imagePathCtrl, decoration: InputDecoration(labelText: 'Path Gambar', hintText: 'markers/marker_xxx.png', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: status,
                  decoration: InputDecoration(labelText: 'Status', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: const [
                    DropdownMenuItem(value: 'active', child: Text('Aktif')),
                    DropdownMenuItem(value: 'inactive', child: Text('Nonaktif')),
                  ],
                  onChanged: (v) => setDialogState(() => status = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A8477), foregroundColor: Colors.white),
              onPressed: () async {
                if (markerIdCtrl.text.isEmpty || imagePathCtrl.text.isEmpty) return;
                final data = {
                  'marker_id': markerIdCtrl.text,
                  'marker_type': markerType,
                  'image_path': imagePathCtrl.text,
                  'status': status,
                };
                if (marker == null) {
                  await ApiService.arCreateMarker(data);
                } else {
                  await ApiService.arUpdateMarker(marker['id'], data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMarker(dynamic marker) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Marker'),
        content: Text('Hapus marker "${marker['marker_id']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Color(0xFFC62828)))),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.arDeleteMarker(marker['id']);
      _loadData();
    }
  }

  // ========== HOTSPOTS TAB ==========
  Widget _buildHotspotsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Hotspots (${_hotspots.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
              ElevatedButton.icon(
                onPressed: _models.isEmpty ? null : () => _showHotspotDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Tambah'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A8477), foregroundColor: Colors.white),
              ),
            ],
          ),
        ),
        Expanded(
          child: _hotspots.isEmpty
              ? const Center(child: Text('Belum ada hotspot', style: TextStyle(color: Color(0xFF637080))))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _hotspots.length,
                    itemBuilder: (ctx, i) => _buildHotspotCard(_hotspots[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHotspotCard(dynamic hotspot) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: const Color(0xFFE67E22).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.place, color: Color(0xFFE67E22), size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hotspot['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(height: 2),
                      Text('Model: ${hotspot['ar_model']?['model_name'] ?? '-'}', style: const TextStyle(fontSize: 12, color: Color(0xFF637080))),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (hotspot['is_active'] == true ? const Color(0xFF0A8477) : const Color(0xFFB0B8C1)).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(hotspot['is_active'] == true ? 'Aktif' : 'Nonaktif',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: hotspot['is_active'] == true ? const Color(0xFF0A8477) : const Color(0xFFB0B8C1))),
                ),
              ],
            ),
            if (hotspot['description'] != null && (hotspot['description'] as String).isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(hotspot['description'], style: const TextStyle(fontSize: 13, color: Color(0xFF637080)), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF637080)),
                  onPressed: () => _showHotspotDialog(hotspot: hotspot),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Color(0xFFC62828)),
                  onPressed: () => _confirmDeleteHotspot(hotspot),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHotspotDialog({dynamic hotspot}) {
    final titleCtrl = TextEditingController(text: hotspot?['title'] ?? '');
    final descCtrl = TextEditingController(text: hotspot?['description'] ?? '');
    final imagePathCtrl = TextEditingController(text: hotspot?['image_path'] ?? '');
    int? selectedModelId = hotspot?['ar_model_id'];
    bool isActive = hotspot?['is_active'] ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(hotspot == null ? 'Tambah Hotspot' : 'Edit Hotspot',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: selectedModelId,
                  decoration: InputDecoration(labelText: '3D Model', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                  items: _models.map<DropdownMenuItem<int>>((m) => DropdownMenuItem(value: m['id'], child: Text(m['model_name'] ?? ''))).toList(),
                  onChanged: (v) => setDialogState(() => selectedModelId = v),
                ),
                const SizedBox(height: 12),
                TextField(controller: titleCtrl, decoration: InputDecoration(labelText: 'Judul', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: InputDecoration(labelText: 'Deskripsi', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), maxLines: 3),
                const SizedBox(height: 12),
                TextField(controller: imagePathCtrl, decoration: InputDecoration(labelText: 'Path Gambar', hintText: 'hotspots/nama_hotspot.png', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Aktif', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 8),
                    Switch(value: isActive, onChanged: (v) => setDialogState(() => isActive = v), activeThumbColor: const Color(0xFF0A8477)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A8477), foregroundColor: Colors.white),
              onPressed: () async {
                if (titleCtrl.text.isEmpty || selectedModelId == null) return;
                final data = {
                  'ar_model_id': selectedModelId,
                  'title': titleCtrl.text,
                  'description': descCtrl.text,
                  'image_path': imagePathCtrl.text,
                  'is_active': isActive,
                };
                if (hotspot == null) {
                  await ApiService.arCreateHotspot(data);
                } else {
                  await ApiService.arUpdateHotspot(hotspot['id'], data);
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteHotspot(dynamic hotspot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Hotspot'),
        content: Text('Hapus "${hotspot['title']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Color(0xFFC62828)))),
        ],
      ),
    );
    if (confirm == true) {
      await ApiService.arDeleteHotspot(hotspot['id']);
      _loadData();
    }
  }

  // ========== MAPPINGS TAB ==========
  Widget _buildMappingsTab() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Marker ↔ Model Mappings',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          ),
        ),
        Expanded(
          child: _mappings.isEmpty
              ? const Center(child: Text('Belum ada mapping', style: TextStyle(color: Color(0xFF637080))))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _mappings.length,
                    itemBuilder: (ctx, i) => _buildMappingCard(_mappings[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildMappingCard(dynamic marker) {
    final models = marker['models'] as List<dynamic>? ?? [];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_scanner, color: Color(0xFF5B6ABF), size: 20),
                const SizedBox(width: 8),
                Text(marker['marker_id'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.link, size: 20, color: Color(0xFF0A8477)),
                  onPressed: () => _showAttachDialog(marker),
                ),
              ],
            ),
            const Divider(),
            if (models.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Belum ada model terhubung', style: TextStyle(fontSize: 13, color: Color(0xFF637080))),
              )
            else
              ...models.map<Widget>((model) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.view_in_ar, size: 16, color: Color(0xFF5B6ABF)),
                        const SizedBox(width: 8),
                        Expanded(child: Text(model['model_name'] ?? '', style: const TextStyle(fontSize: 13))),
                        IconButton(
                          icon: const Icon(Icons.link_off, size: 18, color: Color(0xFFC62828)),
                          onPressed: () async {
                            await ApiService.arDetachModel(marker['id'], model['id']);
                            _loadData();
                          },
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  void _showAttachDialog(dynamic marker) {
    final attachedIds = (marker['models'] as List<dynamic>? ?? []).map((m) => m['id']).toSet();
    final available = _models.where((m) => !attachedIds.contains(m['id'])).toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua model sudah terhubung ke marker ini'), backgroundColor: Color(0xFFE67E22)),
      );
      return;
    }

    int? selectedModelId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Hubungkan ke ${marker['marker_id']}',
              style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          content: DropdownButtonFormField<int>(
            initialValue: selectedModelId,
            decoration: InputDecoration(labelText: 'Pilih 3D Model', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            items: available.map<DropdownMenuItem<int>>((m) => DropdownMenuItem(value: m['id'], child: Text(m['model_name'] ?? ''))).toList(),
            onChanged: (v) => setDialogState(() => selectedModelId = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0A8477), foregroundColor: Colors.white),
              onPressed: () async {
                if (selectedModelId == null) return;
                await ApiService.arAttachModel(marker['id'], selectedModelId!);
                if (ctx.mounted) Navigator.pop(ctx);
                _loadData();
              },
              child: const Text('Hubungkan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF637080)),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, color: Color(0xFF637080))),
        ],
      ),
    );
  }
}
