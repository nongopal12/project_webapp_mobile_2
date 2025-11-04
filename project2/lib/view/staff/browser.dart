import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project2/view/login.dart';
import 'package:project2/view/staff/add_room.dart';
import 'package:project2/view/staff/dashboard.dart';
import 'package:project2/view/staff/edit_room.dart';
import 'package:project2/view/staff/history_staff.dart';
import 'package:project2/view/staff/profile_staff.dart';

// -----------------------------------------------------------------
// Data Model for Room
// -----------------------------------------------------------------
class Room {
  final int id;
  final int roomNumber;
  final int roomLocation;
  final int roomCapacity;
  final String imagePath;
  final String name;
  final String location;
  final String status;

  Room({
    required this.id,
    required this.roomNumber,
    required this.roomLocation,
    required this.roomCapacity,
    required this.imagePath,
    required this.name,
    required this.location,
    required this.status,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'],
      roomNumber: json['room_number'],
      roomLocation: json['room_location'],
      roomCapacity: json['room_capacity'],
      imagePath: json['imagePath'],
      name: json['name'],
      location: json['location'],
      status: json['status'],
    );
  }
}

// -----------------------------------------------------------------
// Browser Page
// -----------------------------------------------------------------
class Browser extends StatefulWidget {
  final String username; // 👈 เพิ่มตัวแปรรับ username

  const Browser({super.key, required this.username});

  @override
  State<Browser> createState() => _BrowserState();
}

class _BrowserState extends State<Browser> {
  final String _baseUrl = 'http://192.168.1.123:3000/api/staff/rooms';
  late Future<List<Room>> _roomsFuture;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _fetchRooms();
  }

  Future<List<Room>> _fetchRooms() async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode == 200) {
        List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((json) {
          String imgPath = json['imagePath'];
          if (!imgPath.startsWith('assets/images/')) {
            imgPath = 'assets/images/$imgPath';
          }
          return Room.fromJson({...json, 'imagePath': imgPath});
        }).toList();
      } else {
        throw Exception('Failed to load rooms (Status ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('Failed to fetch rooms: $e');
    }
  }

  Future<void> _refreshRooms() async {
    setState(() {
      _roomsFuture = _fetchRooms();
    });
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF883C31),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logged out successfully.')),
              );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Dashboard(username: widget.username),
          ), // 👈 ส่ง username
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HistoryStaff(username: widget.username),
          ), // 👈 ส่ง username
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileStaff(username: widget.username),
          ), // 👈 ส่ง username
        );
        break;
    }
  }

  void _showAddRoomDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return const AlertDialog(
          contentPadding: EdgeInsets.all(20),
          content: AddRoom(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
        );
      },
    );

    if (result != null) {
      try {
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(result),
        );

        if (response.statusCode == 201) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Room added successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          _refreshRooms();
        } else {
          throw Exception(
            'Failed to add room: ${json.decode(response.body)['message']}',
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error adding room: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEditRoomDialog(Room currentRoom) async {
    if (currentRoom.status == "Pending" || currentRoom.status == "Reserved") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot edit this room (Pending or Reserved)."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(20),
          content: EditRoom(
            initialImagePath: currentRoom.imagePath,
            initialRoomNumber: currentRoom.roomNumber,
            initialLocation: currentRoom.roomLocation,
            initialCapacity: currentRoom.roomCapacity,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
        );
      },
    );

    if (result != null) {
      try {
        final response = await http.put(
          Uri.parse('$_baseUrl/${currentRoom.id}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(result),
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Room updated successfully!"),
              backgroundColor: Colors.green,
            ),
          );
          _refreshRooms();
        } else {
          throw Exception(
            'Failed to update room: ${json.decode(response.body)['message']}',
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating room: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _updateRoomStatus(int roomId, String currentStatus, String newStatus) {
    String dialogTitle = "Confirm $newStatus";
    String dialogContent = "Are you sure you want to $newStatus this room?";
    String snackbarText = "Room $newStatus successfully.";
    Color snackbarColor = newStatus == "Enable" ? Colors.green : Colors.orange;

    if ((newStatus == "Disable" && currentStatus != "Enable") ||
        (newStatus == "Enable" && currentStatus != "Disable")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Only rooms with $currentStatus status can be changed.",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: Text(dialogContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final response = await http.put(
                    Uri.parse('$_baseUrl/$roomId/status'),
                    headers: {'Content-Type': 'application/json'},
                    body: json.encode({'status': newStatus}),
                  );

                  if (response.statusCode == 200) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(snackbarText),
                        backgroundColor: snackbarColor,
                      ),
                    );
                    _refreshRooms();
                  } else {
                    throw Exception(
                      'Failed to $newStatus room: ${json.decode(response.body)['message']}',
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color mainAppColor = Theme.of(context).primaryColor;
    final Color accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            children: [
              TextSpan(
                text: 'Quick',
                style: TextStyle(color: mainAppColor),
              ),
              TextSpan(
                text: 'Room',
                style: TextStyle(color: accentColor),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Icon(Icons.exit_to_app, color: mainAppColor, size: 24),
            ),
            onPressed: _logout,
          ),
          const SizedBox(width: 10),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey[300], height: 1.0),
        ),
      ),
      body: FutureBuilder<List<Room>>(
        future: _roomsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _refreshRooms,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshRooms,
              child: ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.only(top: 100.0),
                    child: Center(
                      child: Text('No rooms found. Use (+) to add a new room.'),
                    ),
                  ),
                ],
              ),
            );
          }

          final roomList = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refreshRooms,
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: roomList.length,
              itemBuilder: (context, index) {
                final room = roomList[index];
                return _buildRoomCard(
                  context,
                  imageUrl: room.imagePath,
                  roomName: room.name,
                  location: room.location,
                  capacity: room.roomCapacity,
                  status: room.status,
                  onEdit: () => _showEditRoomDialog(room),
                  onDisable: () =>
                      _updateRoomStatus(room.id, room.status, "Disable"),
                  onEnable: () =>
                      _updateRoomStatus(room.id, room.status, "Enable"),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRoomDialog,
        backgroundColor: mainAppColor,
        foregroundColor: Colors.white,
        elevation: 8,
        child: const Icon(Icons.add, size: 30),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: mainAppColor,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Main'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Edit'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
        currentIndex: 1,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildRoomCard(
    BuildContext context, {
    required String imageUrl,
    required String roomName,
    required String location,
    required int capacity,
    required String status,
    required VoidCallback onEdit,
    required VoidCallback onDisable,
    required VoidCallback onEnable,
  }) {
    Color statusColor;
    switch (status) {
      case "Enable":
        statusColor = Colors.blue;
        break;
      case "Disable":
        statusColor = Colors.red;
        break;
      case "Pending":
        statusColor = Colors.orange;
        break;
      case "Reserved":
        statusColor = Colors.yellow.shade700;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      color: const Color.fromARGB(255, 223, 220, 220),
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Image.asset(
            imageUrl,
            width: 120,
            height: 110,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 120,
              height: 110,
              color: Colors.grey[200],
              child: Icon(Icons.broken_image, color: Colors.grey[400]),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    roomName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(location, style: TextStyle(color: Colors.grey[700])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "$capacity Seats",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: onEdit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Edit"),
                      ),
                      if (status == "Enable")
                        ElevatedButton(
                          onPressed: onDisable,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Disable"),
                        )
                      else if (status == "Disable")
                        ElevatedButton(
                          onPressed: onEnable,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Enable"),
                        )
                      else
                        ElevatedButton(
                          onPressed: null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: statusColor,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(status),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
