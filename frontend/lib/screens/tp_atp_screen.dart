import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'materi_list_screen.dart';

class TpAtpScreen extends StatefulWidget {
  final bool isTab;
  const TpAtpScreen({super.key, this.isTab = true});

  @override
  State<TpAtpScreen> createState() => _TpAtpScreenState();
}

class _TpAtpScreenState extends State<TpAtpScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _tpAtpList = [];

  @override
  void initState() {
    super.initState();
    _fetchTpAtp();
  }

  Future<void> _fetchTpAtp() async {
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
            _errorMessage = response['message'] ?? 'Gagal memuat data Tujuan Pembelajaran';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi backend.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(color: Color(0xFF0A8477)),
      );
    } else if (_errorMessage != null) {
      content = Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 64, color: Color(0xFFC62828)),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Color(0xFF637080)),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchTpAtp,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0A8477),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    } else if (_tpAtpList.isEmpty) {
      content = const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_outlined, size: 64, color: Color(0xFFB0B8C1)),
            SizedBox(height: 12),
            Text(
              'Belum ada Tujuan Pembelajaran',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
            ),
          ],
        ),
      );
    } else {
      content = RefreshIndicator(
        color: const Color(0xFF0A8477),
        onRefresh: _fetchTpAtp,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          itemCount: _tpAtpList.length,
          itemBuilder: (context, index) {
            final item = _tpAtpList[index];
            return _buildTpAtpCard(item);
          },
        ),
      );
    }

    if (widget.isTab) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        appBar: AppBar(
          title: const Text(
            'Tujuan Pembelajaran',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
          ),
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: content,
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Pilih TP / ATP',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: content,
    );
  }

  Widget _buildTpAtpCard(Map<String, dynamic> item) {
    final kode = item['kode'] ?? '';
    final elemen = item['elemen'] ?? '';
    final judul = item['judul'] ?? '';
    final deskripsi = item['deskripsi'] ?? '';
    final materiCount = item['materi_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MateriListScreen(tpAtp: item),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A8477).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        kode,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0A8477),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        elemen,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF637080),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  judul,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                    height: 1.3,
                  ),
                ),
                if (deskripsi.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    deskripsi,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF637080),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(height: 1, color: Color(0xFFF0F2F5)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu_book, size: 16, color: Color(0xFF0A8477)),
                        const SizedBox(width: 6),
                        Text(
                          '$materiCount Materi Pembelajaran',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A8477),
                          ),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward, size: 18, color: Color(0xFFD0D5D8)),
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