import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// ===== Backend base URL =====
const String kBaseUrl = "http://172.27.13.156:3000";

/// ===== THEME (โทนสี QuickRoom) =====
class QColors {
  static const Color bg = Color(0xFFF7F7F9);
  static const Color primaryRed = Color(0xFF883C31);
  static const Color gold = Color(0xFFD7A04E);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF2E2E2E);
  static const Color free = Color(0xFF2ECC71);
  static const Color pending = Color(0xFFF4B400);
  static const reserved = Color(0xFFE74C3C);
  static const Color disabled = Color(0xFFB0B3B8);
}

/// ===== Model: Room + 4 time slots =====
class RoomRow {
  final int id;
  final int roomNumber;
  final int roomLocation;
  final int capacity;
  final String imagePath;
  final DateTime date;
  final int s8;
  final int s10;
  final int s13;
  final int s15;

  RoomRow({
    required this.id,
    required this.roomNumber,
    required this.roomLocation,
    required this.capacity,
    required this.imagePath,
    required this.date,
    required this.s8,
    required this.s10,
    required this.s13,
    required this.s15,
  });

  factory RoomRow.fromJson(Map<String, dynamic> j) {
    return RoomRow(
      id: j['room_id'] as int,
      roomNumber: j['room_number'] as int,
      roomLocation: j['room_location'] as int,
      capacity: j['room_capacity'] as int,
      imagePath: (j['room_img'] ?? '').toString(),
      date:
          DateTime.tryParse((j['room_date'] ?? '').toString()) ??
          DateTime.now(),
      s8: j['room_8AM'] as int,
      s10: j['room_10AM'] as int,
      s13: j['room_1PM'] as int,
      s15: j['room_3PM'] as int,
    );
  }
}

/// ===== Page: Room Browser (ตารางเวลาห้อง) =====
class RoomBrowserPage extends StatefulWidget {
  const RoomBrowserPage({super.key});
  @override
  State<RoomBrowserPage> createState() => _RoomBrowserPageState();
}

class _RoomBrowserPageState extends State<RoomBrowserPage> {
  bool _loading = true;
  String? _error;
  List<RoomRow> _rooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Uri.parse('$kBaseUrl/api/rooms');
      final res = await http.get(uri);
      if (res.statusCode != 200) {
        throw Exception('โหลดข้อมูลห้องไม่สำเร็จ (${res.statusCode})');
      }
      final list = (json.decode(res.body) as List)
          .map((e) => RoomRow.fromJson(e as Map<String, dynamic>))
          .toList();
      _rooms = list;
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Color _statusColor(int v) {
    switch (v) {
      case 1:
        return QColors.free;
      case 2:
        return QColors.pending;
      case 3:
        return QColors.reserved;
      case 4:
        return QColors.disabled;
      default:
        return QColors.text;
    }
  }

  String _statusText(int v) {
    switch (v) {
      case 1:
        return 'Free';
      case 2:
        return 'Pending';
      case 3:
        return 'Reserved';
      case 4:
        return 'Disabled';
      default:
        return '-';
    }
  }

  static const _slotLabels = ['8–10', '10–12', '13–15', '15–17'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QColors.bg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: RichText(
          text: const TextSpan(
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: 'Room',
                style: TextStyle(color: QColors.primaryRed),
              ),
              TextSpan(
                text: 'Browser',
                style: TextStyle(color: QColors.gold),
              ),
            ],
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: QColors.primaryRed,
        elevation: 1,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[300], height: 1.0),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _errorView()
          : RefreshIndicator(
              onRefresh: _loadRooms,
              color: QColors.primaryRed,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                children: [
                  _legend(),
                  const SizedBox(height: 16),
                  ..._rooms.map((r) => _roomCard(r)),
                ],
              ),
            ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('เกิดข้อผิดพลาด:\n$_error', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _loadRooms,
              child: const Text('ลองอีกครั้ง'),
            ),
          ],
        ),
      ),
    );
  }

  /// Legend
  Widget _legend() {
    Widget pill(Color c, String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(.6), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            t,
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: QColors.card,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, size: 16, color: QColors.primaryRed),
              SizedBox(width: 6),
              Text(
                'Room Status',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: QColors.text,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              pill(QColors.free, 'Free'),
              pill(QColors.pending, 'Pending'),
              pill(QColors.reserved, 'Reserved'),
              pill(QColors.disabled, 'Disabled'),
            ],
          ),
        ],
      ),
    );
  }

  /// Card ต่อห้อง + slot 4 ช่อง + "รูปภาพห้อง"
  Widget _roomCard(RoomRow r) {
    final roomName = 'Room ${r.roomLocation}0${r.roomNumber}';
    final slots = [r.s8, r.s10, r.s13, r.s15];
    final dateText =
        '${r.date.day.toString().padLeft(2, '0')}/${r.date.month.toString().padLeft(2, '0')}/${r.date.year}';

    final imgPath = 'assets/images/${r.imagePath}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== แถวบน: รูปห้อง + ข้อมูลห้อง =====
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // รูปห้อง
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      imgPath,
                      width: 90,
                      height: 75,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) {
                        return Container(
                          width: 90,
                          height: 75,
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.meeting_room_outlined,
                            color: Colors.grey,
                            size: 28,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  // ข้อมูลห้อง
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // header row
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                roomName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: QColors.text,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: QColors.primaryRed.withOpacity(.06),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: QColors.primaryRed.withOpacity(.4),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.stairs_rounded,
                                    size: 13,
                                    color: QColors.primaryRed,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    'Floor ${r.roomLocation}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: QColors.primaryRed,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // sub info
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people_alt_rounded,
                                  size: 15,
                                  color: QColors.text.withOpacity(.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Cap ${r.capacity}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: QColors.text.withOpacity(.7),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 13,
                                  color: QColors.text.withOpacity(.7),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  dateText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: QColors.text.withOpacity(.7),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black12.withOpacity(.02),
                      Colors.black12,
                      Colors.black12.withOpacity(.02),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ===== ตาราง time slot 4 ช่อง =====
              Row(
                children: List.generate(4, (i) {
                  final st = slots[i];
                  final color = _statusColor(st);
                  return Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 3,
                        vertical: 8,
                      ),
                      margin: EdgeInsets.only(right: i == 3 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(.07),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: color.withOpacity(.55),
                          width: 0.9,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              _slotLabels[i],
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: color,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: color.withOpacity(.5),
                                width: 0.7,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    st == 1
                                        ? Icons.check_circle_rounded
                                        : st == 2
                                        ? Icons.timelapse_rounded
                                        : st == 3
                                        ? Icons.event_busy_rounded
                                        : Icons.block_rounded,
                                    size: 11,
                                    color: color,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    _statusText(st),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w700,
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
