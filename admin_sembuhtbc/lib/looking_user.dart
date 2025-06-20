import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:admin_sembuhtbc/status_user.dart';

class LookingUserPage extends StatefulWidget {
  const LookingUserPage({super.key});

  @override
  State<LookingUserPage> createState() => _LookingUserPageState();
}

class _LookingUserPageState extends State<LookingUserPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;

  /// Fungsi pencarian yang telah dimodifikasi untuk mencari berdasarkan ID dan Username
  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      if (mounted) setState(() => _searchResults = []);
      return;
    }
    if (mounted) setState(() => _isLoading = true);

    try {
      // Buat map untuk menampung hasil unik (berdasarkan ID dokumen)
      Map<String, Map<String, dynamic>> uniqueResults = {};

      // 1. Pencarian berdasarkan Document ID (sangat cepat dan akurat)
      final idSearchFuture =
          FirebaseFirestore.instance
              .collection('users')
              .doc(query.trim())
              .get();

      // 2. Pencarian berdasarkan Username (prefix search)
      final usernameSearchFuture =
          FirebaseFirestore.instance
              .collection('users')
              .orderBy('username')
              .where('username', isGreaterThanOrEqualTo: query)
              .where('username', isLessThanOrEqualTo: '$query\uf8ff')
              .limit(10)
              .get();

      // Jalankan kedua pencarian secara paralel
      final results = await Future.wait([idSearchFuture, usernameSearchFuture]);

      // Proses hasil dari pencarian ID
      final idDoc = results[0] as DocumentSnapshot;
      if (idDoc.exists) {
        uniqueResults[idDoc.id] = {
          'id': idDoc.id,
          ...idDoc.data() as Map<String, dynamic>,
        };
      }

      // Proses hasil dari pencarian username
      final usernameDocs = results[1] as QuerySnapshot;
      for (var doc in usernameDocs.docs) {
        // Hanya tambahkan jika belum ada di hasil (untuk menghindari duplikat)
        if (!uniqueResults.containsKey(doc.id)) {
          uniqueResults[doc.id] = {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }
      }

      if (mounted) {
        setState(() {
          _searchResults = uniqueResults.values.toList();
        });
      }
    } catch (e) {
      print("Error searching users: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Terjadi kesalahan saat mencari: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.grey.shade100, // Latar belakang abu-abu muda untuk kontras
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildSearchBar(),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            const Expanded(
              child: Center(child: Text("Pasien tidak ditemukan.")),
            )
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return _buildUserCard(context, user);
                },
              ),
            ),
        ],
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text(
        'Cari Pasien',
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0072CE),
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 48,
            height: 48,
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
              child: const Icon(
                Icons.arrow_back,
                size: 24,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
      backgroundColor: Colors.grey.shade100,
      elevation: 0,
      centerTitle: true,
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _searchUsers,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Cari username pasien',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildUserCard(BuildContext context, Map<String, dynamic> user) {
    String profilePictureBase64 = user['profilePictureBase64'] ?? '';
    ImageProvider profileImage = const AssetImage("assets/images/avatar.png");
    if (profilePictureBase64.isNotEmpty) {
      try {
        profileImage = MemoryImage(base64Decode(profilePictureBase64));
      } catch (e) {
        /* fallback to default avatar */
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StatusUserPage(userId: user['id']),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(radius: 24, backgroundImage: profileImage),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['username'] ?? 'Tanpa Nama',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user['email'] ?? 'Tanpa Email',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontFamily: 'Urbanist',
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
