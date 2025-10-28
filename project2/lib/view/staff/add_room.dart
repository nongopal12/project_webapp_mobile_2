import 'package:flutter/material.dart';

/// หน้า Add Room (แบบจำลองยังไม่เชื่อม Database)
/// Add Room screen (Frontend mock-up only)
class AddRoom extends StatefulWidget {
  const AddRoom({super.key});

  @override
  State<AddRoom> createState() => _AddRoomState();
}

class _AddRoomState extends State<AddRoom> {
  // ================================================================
  // Section 1: ตัวแปรควบคุม (Controllers & Data)
  // ================================================================
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();

  // รายการรูปภาพของห้อง
  final List<String> roomImages = [
    "assets/images/Meeting-RoomA.jpg",
    "assets/images/Meeting-Room-B.jpg",
    "assets/images/Meeting-RoomC.jpg",
    "assets/images/MeetingRoomD.jpg",
    "assets/images/MeetingRoomE.jpg",
    "assets/images/Meeting-RoomF.jpg",
    "assets/images/Meeting-RoomG.jpg",
    "assets/images/Meeting-RoomH.jpg",
  ];

  int _currentImageIndex = 0;

  // ================================================================
  // Section 2: ฟังก์ชันควบคุมการแสดงผล (Functions)
  // ================================================================

  /// เปลี่ยนภาพถัดไปหรือก่อนหน้า
  /// Switch to next or previous image.
  void _changeImage(bool next) {
    setState(() {
      if (next) {
        _currentImageIndex = (_currentImageIndex + 1) % roomImages.length;
      } else {
        _currentImageIndex =
            (_currentImageIndex - 1 + roomImages.length) % roomImages.length;
      }
    });
  }

  /// ฟังก์ชันเมื่อกด Accept (เพิ่มห้อง)
  /// Validate input and return room data to parent.
  void _acceptRoom() {
    final name = _nameController.text.trim();
    final location = _locationController.text.trim();

    // ตรวจสอบว่ากรอกครบหรือไม่
    if (name.isEmpty || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in both room name and location."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
        ),
      );
      return;
    }

    // แสดง SnackBar แจ้งเตือนว่าบันทึกสำเร็จ
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Room added successfully!"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.fixed,
      ),
    );

    // ส่งข้อมูลกลับไปยังหน้า Browser หลังจากดีเลย์เล็กน้อย
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.of(context).pop({
          'name': name,
          'location': location,
          'imagePath': roomImages[_currentImageIndex],
          'status': 'Enable',
        });
      }
    });
  }

  // ================================================================
  // Section 3: ส่วนแสดงผลหลักของหน้า (UI)
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ------------------------------------------------------------
          // Header
          // ------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add New Room',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------------
          // Room Image Viewer
          // ------------------------------------------------------------
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  height: (MediaQuery.of(context).size.width - 80) * (9 / 16),
                  color: Colors.grey[200],
                  child: Image.asset(
                    roomImages[_currentImageIndex],
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              ),
              // ปุ่มเปลี่ยนภาพซ้าย
              Positioned(
                left: 8,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => _changeImage(false),
                  style: IconButton.styleFrom(backgroundColor: Colors.black38),
                ),
              ),
              // ปุ่มเปลี่ยนภาพขวา
              Positioned(
                right: 8,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                  onPressed: () => _changeImage(true),
                  style: IconButton.styleFrom(backgroundColor: Colors.black38),
                ),
              ),
              // ตัวเลขล่างแสดงลำดับภาพ
              Positioned(
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "Image ${_currentImageIndex + 1} / ${roomImages.length}",
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ------------------------------------------------------------
          // Room Name Input
          // ------------------------------------------------------------
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Room Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ------------------------------------------------------------
          // Location Input
          // ------------------------------------------------------------
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: "Location",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ------------------------------------------------------------
          // Buttons (Cancel & Accept)
          // ------------------------------------------------------------
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Cancel"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _acceptRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Accept"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
