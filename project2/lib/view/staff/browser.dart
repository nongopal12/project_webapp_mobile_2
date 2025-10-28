import 'package:flutter/material.dart';
import 'package:project2/view/login.dart';
import 'package:project2/view/staff/add_room.dart';
import 'package:project2/view/staff/dashboard.dart';
import 'package:project2/view/staff/edit_room.dart';
import 'package:project2/view/staff/history_staff.dart';
import 'package:project2/view/staff/profile_staff.dart';

class Browser extends StatefulWidget {
  const Browser({super.key});

  @override
  State<Browser> createState() => _BrowserState();
}

class _BrowserState extends State<Browser> {
  // ================================================================
  // Section 1: จำลองข้อมูลห้องในระบบ (Mock Data)
  // ================================================================
  List<Map<String, dynamic>> rooms = [
    {
      'imagePath': "assets/images/Meeting-RoomA.jpg",
      'name': "Room 1",
      'location': "1st Floor",
      'status': "Enable",
    },
    {
      'imagePath': "assets/images/Meeting-Room-B.jpg",
      'name': "Room 2",
      'location': "2nd Floor",
      'status': "Pending",
    },
    {
      'imagePath': "assets/images/Meeting-RoomC.jpg",
      'name': "Room 3",
      'location': "3rd Floor",
      'status': "Reserved",
    },
    {
      'imagePath': "assets/images/MeetingRoomD.jpg",
      'name': "Room 4",
      'location': "4th Floor",
      'status': "Disable",
    },
  ];

  // ================================================================
  // Section 2: ฟังก์ชัน Logout
  // ================================================================
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

  // ================================================================
  // Section 3: Navigation ระหว่างหน้า
  // ================================================================
  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Dashboard()),
        );
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HistoryStaff()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileStaff()),
        );
        break;
    }
  }

  // ================================================================
  // Section 4: ฟังก์ชัน Add Room
  // ================================================================
  void _showAddRoomDialog() async {
    final result = await showDialog(
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

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        rooms.add(result);
      });
    }
  }

  // ================================================================
  // Section 5: ฟังก์ชัน Edit Room
  // ================================================================
  void _showEditRoomDialog(int index) async {
    final currentRoom = rooms[index];
    final status = currentRoom['status'];

    if (status == "Pending" || status == "Reserved") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cannot edit this room (Pending or Reserved)."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(20),
          content: EditRoom(initialImagePath: currentRoom['imagePath']),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
          ),
        );
      },
    );

    if (result != null && result is String) {
      setState(() {
        rooms[index]['name'] = result;
      });
    }
  }

  // ================================================================
  // Section 6: ฟังก์ชัน Disable / Enable Room
  // ================================================================
  void _disableRoom(int index) {
    final currentStatus = rooms[index]['status'];
    if (currentStatus == "Enable") {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Confirm Disable"),
            content: const Text("Are you sure you want to disable this room?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => rooms[index]['status'] = "Disable");
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Room disabled successfully."),
                      backgroundColor: Colors.orange,
                    ),
                  );
                },
                child: const Text("Yes"),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Only rooms with Enable status can be disabled."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _enableRoom(int index) {
    final currentStatus = rooms[index]['status'];
    if (currentStatus == "Disable") {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Confirm Enable"),
            content: const Text("Do you want to enable this room again?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() => rooms[index]['status'] = "Enable");
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Room enabled successfully."),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text("Yes"),
              ),
            ],
          );
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Only rooms with Disable status can be enabled."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ================================================================
  // Section 7: Build UI
  // ================================================================
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

      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];
          return _buildRoomCard(
            context,
            imageUrl: room['imagePath'],
            roomName: room['name'],
            location: room['location'],
            status: room['status'],
            onEdit: () => _showEditRoomDialog(index),
            onDisable: () => _disableRoom(index),
            onEnable: () => _enableRoom(index),
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

  // ================================================================
  // Section 8: Room Card Builder
  // ================================================================
  Widget _buildRoomCard(
    BuildContext context, {
    required String imageUrl,
    required String roomName,
    required String location,
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
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 120,
              height: 100,
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
