import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';

class StatusUserPage extends StatefulWidget {
  final String userId;
  const StatusUserPage({super.key, required this.userId});

  @override
  State<StatusUserPage> createState() => _StatusUserPageState();
}

class _StatusUserPageState extends State<StatusUserPage> {
  // State untuk menampung semua data
  Map<String, dynamic>? _userData;
  List<Map<String, dynamic>> _allDoseEvents = [];
  List<Map<String, dynamic>> _displayHistory = [];

  // State untuk filter dropdown
  String _selectedFilter = 'terbaru';
  List<String> _dateFilterOptions = ['terbaru', 'terlama'];

  @override
  void initState() {
    super.initState();
    _loadAndProcessUserData();
  }

  // --- LOGIKA UTAMA PENGAMBILAN & PEMROSESAN DATA ---
  Future<void> _loadAndProcessUserData() async {
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .get();
    final schedulesSnapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('medication_schedules')
            .get();

    int totalExpectedDoses = 0;
    int totalTakenDoses = 0;
    List<Map<String, dynamic>> allDoseEvents = [];
    Set<DateTime> uniqueDates = {};

    for (var scheduleDoc in schedulesSnapshot.docs) {
      final scheduleData = scheduleDoc.data();
      final List<dynamic> scheduledTimes = scheduleData['scheduledTimes'] ?? [];
      final int daysDuration = scheduleData['daysDuration'] ?? 0;
      final DateTime? startDate =
          scheduleData['startDate'] != null
              ? DateTime.tryParse(scheduleData['startDate'])
              : null;
      if (startDate == null) continue;

      totalExpectedDoses += (scheduledTimes.length * daysDuration);

      final takenDosesSnapshot =
          await scheduleDoc.reference.collection('taken_doses').get();
      Map<String, Timestamp> takenDosesMap = {};
      for (var doseDoc in takenDosesSnapshot.docs) {
        final takenAtData = doseDoc.data()['takenAt'];
        if (takenAtData is Map<String, dynamic>) {
          takenAtData.forEach((time, timestamp) {
            if (timestamp is Timestamp) {
              String key = "${doseDoc.id} $time";
              takenDosesMap[key] = timestamp;
            }
          });
        }
      }
      totalTakenDoses += takenDosesMap.values.length;

      for (int day = 0; day < daysDuration; day++) {
        for (String timeStr in scheduledTimes) {
          final currentDay = startDate.add(Duration(days: day));
          final timeParts = timeStr.split(':');
          final scheduledDateTime = DateTime(
            currentDay.year,
            currentDay.month,
            currentDay.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          uniqueDates.add(DateUtils.dateOnly(scheduledDateTime));

          String lookupKey =
              "${DateFormat('yyyy-MM-dd').format(scheduledDateTime)} $timeStr";
          Timestamp? takenAtTimestamp = takenDosesMap[lookupKey];

          allDoseEvents.add({
            'medicineName': scheduleData['medicineName'] ?? 'Tanpa Nama',
            'scheduledDateTime': scheduledDateTime,
            'isTaken': takenAtTimestamp != null,
            'takenAt': takenAtTimestamp?.toDate(),
          });
        }
      }
    }

    List<String> sortedUniqueDateStrings =
        uniqueDates.map((d) => DateFormat('yyyy-MM-dd').format(d)).toList();
    sortedUniqueDateStrings.sort((a, b) => b.compareTo(a));

    if (mounted) {
      setState(() {
        _userData = {
          'profile': userDoc.data() ?? {},
          'overallProgress': {
            'taken': totalTakenDoses,
            'total': totalExpectedDoses,
          },
          'allDoseEvents': allDoseEvents,
        };
        _dateFilterOptions = ['terbaru', 'terlama', ...sortedUniqueDateStrings];
        _applyFilterAndSort();
      });
    }
  }

  void _applyFilterAndSort() {
    if (_userData == null) return;

    final allEvents = List<Map<String, dynamic>>.from(
      _userData!['allDoseEvents'],
    );
    List<Map<String, dynamic>> filteredEvents;

    if (_selectedFilter == 'terbaru' || _selectedFilter == 'terlama') {
      filteredEvents = List.from(allEvents);
    } else {
      filteredEvents =
          allEvents.where((event) {
            return DateFormat(
                  'yyyy-MM-dd',
                ).format(event['scheduledDateTime']) ==
                _selectedFilter;
          }).toList();
    }

    if (_selectedFilter == 'terlama') {
      filteredEvents.sort(
        (a, b) => (a['scheduledDateTime'] as DateTime).compareTo(
          b['scheduledDateTime'] as DateTime,
        ),
      );
    } else {
      filteredEvents.sort(
        (a, b) => (b['scheduledDateTime'] as DateTime).compareTo(
          a['scheduledDateTime'] as DateTime,
        ),
      );
    }

    setState(() {
      _displayHistory = filteredEvents;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userData == null) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: _buildAppBar(context, 'Memuat Data...'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final profile = _userData!['profile'];
    final progress = _userData!['overallProgress'];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: _buildAppBar(context, "Data Riwayat User"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(profile),
            const SizedBox(height: 24),
            _buildOverallProgressCard(progress['taken'], progress['total']),
            const SizedBox(height: 24),
            _buildHistorySection(),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, String title) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
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

  Widget _buildProfileCard(Map<String, dynamic> profile) {
    String profilePictureBase64 = profile['profilePictureBase64'] ?? '';
    ImageProvider profileImage = const AssetImage("assets/images/avatar.png");
    if (profilePictureBase64.isNotEmpty) {
      try {
        profileImage = MemoryImage(base64Decode(profilePictureBase64));
      } catch (e) {
        /* fallback */
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 30, backgroundImage: profileImage),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile['username'] ?? 'Tanpa Nama',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  profile['email'] ?? 'Tanpa Email',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: ${widget.userId.substring(0, 7).toUpperCase()}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallProgressCard(int taken, int total) {
    double percentage = total > 0 ? (taken / total) : 0.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Progres Kepatuhan Total",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    color: const Color(0xFF0072CE),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "${(percentage * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "$taken dari $total total dosis telah diminum.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // --- WIDGET YANG TELAH DIPERBAIKI ---
  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Detail Riwayat Minum Obat",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedFilter,
              isExpanded: true,
              items:
                  _dateFilterOptions.map((value) {
                    String displayText;
                    if (value == 'terbaru') {
                      displayText = 'Urutkan Terbaru';
                    } else if (value == 'terlama') {
                      displayText = 'Urutkan Terlama';
                    } else {
                      // Menggunakan format aman yang tidak memerlukan inisialisasi lokalisasi
                      displayText =
                          'Filter: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(value))}';
                    }
                    return DropdownMenuItem(
                      value: value,
                      child: Text(displayText, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedFilter = value;
                    _applyFilterAndSort();
                  });
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildGroupedByDateList(),
      ],
    );
  }

  Widget _buildGroupedByDateList() {
    if (_displayHistory.isEmpty) return _buildEmptyHistoryCard();

    Map<DateTime, List<Map<String, dynamic>>> groupedHistory = {};
    for (var item in _displayHistory) {
      DateTime dateKey = DateUtils.dateOnly(item['scheduledDateTime']);
      if (groupedHistory[dateKey] == null) {
        groupedHistory[dateKey] = [];
      }
      groupedHistory[dateKey]!.add(item);
    }

    var sortedDates = groupedHistory.keys.toList();
    if (_selectedFilter == 'terlama') {
      sortedDates.sort((a, b) => a.compareTo(b));
    } else {
      sortedDates.sort((a, b) => b.compareTo(a));
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final itemsForDate = groupedHistory[date]!;
        return _buildDateGroupCard(date, itemsForDate);
      },
    );
  }

  Widget _buildDateGroupCard(DateTime date, List<Map<String, dynamic>> doses) {
    int takenCount = doses.where((d) => d['isTaken']).length;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF0072CE),
          child: Icon(Icons.calendar_month, color: Colors.white, size: 22),
        ),
        title: Text(
          DateFormat('dd-MM-yyyy').format(date),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          "Selesai $takenCount dari ${doses.length} dosis",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        children: doses.map((dose) => _buildHistoryItem(dose)).toList(),
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final bool isTaken = item['isTaken'];
    final DateTime scheduledDateTime = item['scheduledDateTime'];
    final bool isMissed =
        !isTaken && scheduledDateTime.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.only(left: 24, right: 16),
        leading: Icon(
          isTaken
              ? Icons.check_circle
              : (isMissed ? Icons.cancel : Icons.alarm),
          color: isTaken ? Colors.green : (isMissed ? Colors.red : Colors.grey),
        ),
        title: Text(
          item['medicineName'],
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        trailing: Text(
          DateFormat('HH:mm').format(scheduledDateTime),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isTaken ? Colors.green : Colors.grey,
          ),
        ),
        children: [
          if (isTaken)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 16, 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.task_alt,
                    color: Color(0xFF0072CE),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Diverifikasi pada:\n${DateFormat('dd-MM-yyyy, HH:mm:ss').format(item['takenAt'])}",
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 16, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: isMissed ? Colors.red : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isMissed
                          ? "Dosis ini terlewat (tidak diminum)."
                          : "Menunggu konfirmasi dari pasien.",
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyHistoryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text(
          "Tidak ada data riwayat untuk ditampilkan pada filter ini.",
        ),
      ),
    );
  }
}
