import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'materi_detail_screen.dart';

class MateriListScreen extends StatefulWidget {
  final Map<String, dynamic> tpAtp;

  const MateriListScreen({super.key, required this.tpAtp});

  @override
  State<MateriListScreen> createState() => _MateriListScreenState();
}

class _MateriListScreenState extends State<MateriListScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _materiList = [];

  @override
  void initState() {
    super.initState();
    _fetchMateri();
  }

  Future<void> _fetchMateri() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response =
          await ApiService.getMateriList(tpAtpId: widget.tpAtp['id']);
      if (response['success'] == true && mounted) {
        setState(() {
          _materiList = response['data'] ?? [];
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _errorMessage = response['message'] ?? 'Gagal memuat materi';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.tpAtp['kode'] ?? 'Materi',
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 20, color: Color(0xFF1A1A2E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0A8477)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 60, color: Color(0xFFC62828)),
              const SizedBox(height: 14),
              Text(_errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF637080))),
              const SizedBox(height: 14),
              ElevatedButton(
                onPressed: _fetchMateri,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A8477),
                    foregroundColor: Colors.white),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF0A8477),
      onRefresh: _fetchMateri,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header info card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0A8477), Color(0xFF12A595)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.tpAtp['elemen'] ?? 'Informatika',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.tpAtp['judul'] ?? '',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                if ((widget.tpAtp['deskripsi'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.tpAtp['deskripsi'],
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Topik Materi',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E)),
              ),
              Text(
                '${_materiList.length} Topik',
                style: const TextStyle(fontSize: 13, color: Color(0xFF637080)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_materiList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text('Belum ada materi untuk TP/ATP ini',
                    style: TextStyle(color: Color(0xFF637080))),
              ),
            )
          else
            ..._materiList.asMap().entries.map((entry) {
              final index = entry.key;
              final materi = entry.value;
              return _buildMateriItem(index + 1, materi);
            }),
        ],
      ),
    );
  }

  Widget _buildMateriItem(int number, Map<String, dynamic> item) {
    final judul = item['judul'] ?? '';
    final ringkasan = item['ringkasan'] ?? '';
    final menit = item['estimasi_menit'] ?? 15;
    final hasAr = item['ar_model_id'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MateriDetailScreen(materiId: item['id']),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A8477).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0A8477),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        judul,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                          height: 1.3,
                        ),
                      ),
                      if (ringkasan.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          ringkasan,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF637080),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined,
                              size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '$menit Menit',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                          if (hasAr) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF5B6ABF)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.view_in_ar,
                                      size: 12, color: Color(0xFF5B6ABF)),
                                  SizedBox(width: 4),
                                  Text(
                                    'Objek 3D',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF5B6ABF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios,
                    size: 14, color: Color(0xFFD0D5D8)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
