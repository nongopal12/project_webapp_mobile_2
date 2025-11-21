import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// ===== Server config =====
const String kBaseUrl = "http://172.27.13.156:3000";

/// ===== THEME =====
class QColors {
  static const Color bg = Color(0xFFF7F7F9);
  static const Color primaryRed = Color(0xFF7A2E22);
  static const Color gold = Color(0xFFCC9A2B);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF2E2E2E);
  static const Color free = Color(0xFF2ECC71);
  static const Color pending = Color(0xFFF1C40F);
  static const Color reserved = Color(0xFFE74C3C);  // 🔥 Red
  static const Color disabled = Color(0xFF9E9E9E);  // ⚪ Grey
}

/// ===== Model: room data from /api/rooms =====
class RoomFull {
  final int roomId;
  final int roomNumber;
  final int roomLocation;
  final int roomCapacity;
  final String roomImg;
  final int s8;  // room_8AM   (1=free 2=pending 3=reserved 4=disabled)
  final int s10; // room_10AM
  final int s13; // room_1PM
  final int s15; // room_3PM

  RoomFull({
    required this.roomId,
    required this.roomNumber,
    required this.roomLocation,
    required this.roomCapacity,
    required this.roomImg,
    required this.s8,
    required this.s10,
    required this.s13,
    required this.s15,
  });

  factory RoomFull.fromJson(Map<String, dynamic> j) => RoomFull(
        roomId: j['room_id'] as int,
        roomNumber: j['room_number'] as int,
        roomLocation: j['room_location'] as int,
        roomCapacity: j['room_capacity'] as int,
        roomImg: (j['room_img'] ?? '').toString(),
        s8: j['room_8AM'] as int,
        s10: j['room_10AM'] as int,
        s13: j['room_1PM'] as int,
        s15: j['room_3PM'] as int,
      );
}

/// Map numeric status code from DB → UI text
String mapCodeToUi(int code) {
  switch (code) {
    case 1:
      return 'Free';
    case 2:
      return 'Pending';
    case 3:
      return 'Reserved';
    case 4:
    case 5:
      return 'Disabled';
    default:
      return 'Unknown';
  }
}

Color statusColor(String s) {
  switch (s) {
    case 'Free':
      return QColors.free;
    case 'Pending':
      return QColors.pending;
    case 'Reserved':
      return QColors.reserved;
    case 'Disabled':
      return QColors.disabled;
    default:
      return QColors.text;
  }
}

/// ===== SLOT helper =====
class _SlotSpec {
  final String label;
  final int index; // 1=8AM, 2=10AM, 3=1PM, 4=3PM
  const _SlotSpec(this.label, this.index);
}

const _slots = <_SlotSpec>[
  _SlotSpec('8:00', 1),
  _SlotSpec('10:00', 2),
  _SlotSpec('13:00', 3),
  _SlotSpec('15:00', 4),
];

/// ===== API: load all rooms for today then filter by status + time slot =====
Future<List<RoomFull>> fetchRoomsBy(String uiStatus, int slotIndex) async {
  final uri = Uri.parse('$kBaseUrl/api/rooms');
  final res = await http.get(uri);
  if (res.statusCode != 200) {
    throw Exception('Failed to load rooms (${res.statusCode})');
  }
  final List data = json.decode(res.body) as List;
  final all =
      data.map((e) => RoomFull.fromJson(e as Map<String, dynamic>)).toList();

  // Pick status column by time slot
  int pickStatus(RoomFull r) {
    switch (slotIndex) {
      case 1:
        return r.s8;
      case 2:
        return r.s10;
      case 3:
        return r.s13;
      case 5:
      case 4:
        return r.s15;
      default:
        return r.s8;
    }
  }

  return all.where((r) => mapCodeToUi(pickStatus(r)) == uiStatus).toList();
}

/// ===== PAGE: show rooms by "status" + Tab for "time slot" =====
class StatusRoomPage extends StatefulWidget {
  final String status; // Free / Pending / Reserved / Disabled
  const StatusRoomPage({super.key, required this.status});

  @override
  State<StatusRoomPage> createState() => _StatusRoomPageState();
}

class _StatusRoomPageState extends State<StatusRoomPage>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  late Future<List<RoomFull>> _future;
  int _currentSlot = 1; // 1 = 8AM (default)

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _slots.length, vsync: this);
    _tab.addListener(() {
      if (_tab.indexIsChanging) return;
      _currentSlot = _slots[_tab.index].index;
      setState(() {
        _future = fetchRoomsBy(widget.status, _currentSlot);
      });
    });
    _future = fetchRoomsBy(widget.status, _currentSlot);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QColors.bg,
      appBar: AppBar(
        title: Text('Room Status: ${widget.status}'),
        backgroundColor: QColors.primaryRed,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 2,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: QColors.gold,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _slots.map((s) => Tab(text: s.label)).toList(),
        ),
      ),
      body: FutureBuilder<List<RoomFull>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text('Error: ${snap.error}'),
            );
          }
          final rooms = snap.data ?? [];
          if (rooms.isEmpty) {
            return Center(
              child: Text(
                'No rooms in status "${widget.status}"\n'
                'Time slot: ${_slots[_tab.index].label}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: QColors.text.withOpacity(0.65),
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: rooms.length,
            itemBuilder: (_, i) {
              final r = rooms[i];

              // Compute the status for current slot (for card display)
              final code = () {
                switch (_currentSlot) {
                  case 1:
                    return r.s8;
                  case 2:
                    return r.s10;
                  case 3:
                    return r.s13;
                  case 4:
                  case 5:
                    return r.s15;
                  default:
                    return r.s8;
                }
              }();
              final ui = mapCodeToUi(code);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: _RoomImage(imageName: r.roomImg),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              // Example: Room 101 / 203
                              'Room ${r.roomLocation}0${r.roomNumber}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Status: $ui',
                              style: TextStyle(
                                color: statusColor(ui),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Capacity: ${r.roomCapacity}, Floor ${r.roomLocation}',
                              style: TextStyle(
                                color: QColors.text.withOpacity(0.7),
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Room image widget:
/// 1) Try to load from local assets
/// 2) If not found, fallback to backend URL (/assets/<filename>)
class _RoomImage extends StatelessWidget {
  final String imageName;
  const _RoomImage({required this.imageName});

  @override
  Widget build(BuildContext context) {
    final assetGuess =
        'assets/images/${imageName.isEmpty ? 'Meeting-RoomA.jpg' : imageName}';
    return Image.asset(
      assetGuess,
      width: 90,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        if (imageName.isEmpty) {
          return Container(
            width: 90,
            height: 80,
            color: const Color(0x11000000),
            alignment: Alignment.center,
            child: const Icon(Icons.meeting_room),
          );
        }
        return Image.network(
          '$kBaseUrl/assets/$imageName',
          width: 90,
          height: 80,
          fit: BoxFit.cover,
        );
      },
    );
  }
}
