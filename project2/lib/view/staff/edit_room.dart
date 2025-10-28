import 'package:flutter/material.dart';

/// หน้าแก้ไขข้อมูลห้อง (Edit Room)
/// ใช้ในฝั่ง Staff เพื่อจำลองการแก้ไขชื่อห้อง
class EditRoom extends StatefulWidget {
  final String initialImagePath;

  const EditRoom({
    super.key,
    this.initialImagePath = "assets/images/Meeting-RoomF.jpg",
  });

  @override
  State<EditRoom> createState() => _EditRoomState();
}

class _EditRoomState extends State<EditRoom> {
  // ================================================================
  // Section 1: ตัวแปรและการตั้งค่าเริ่มต้น (State & Controller)
  // ================================================================
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: "Room ");
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // ================================================================
  // Section 2: ฟังก์ชันเมื่อกดปุ่ม Accept
  // ================================================================
  void _onAcceptPressed() {
    final name = _nameController.text.trim();

    // ตรวจสอบการกรอกข้อมูล
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Name cannot be empty"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ส่งค่าชื่อห้องใหม่กลับไปหน้า Browser
    Navigator.of(context).pop(name);
  }

  // ================================================================
  // Section 3: ส่วนสร้าง UI หลัก (Build Method)
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ------------------------------------------------------------
          // Header (ชื่อหน้า + ปุ่มปิด)
          // ------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Room',
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
          // รูปภาพของห้อง
          // ------------------------------------------------------------
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: double.infinity,
              height: 150,
              color: Colors.grey[200],
              child: Image.asset(
                widget.initialImagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, size: 50),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ------------------------------------------------------------
          // ช่องกรอกชื่อห้อง (Text Field)
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
          const SizedBox(height: 20),

          // ------------------------------------------------------------
          // ปุ่ม Cancel และ Accept
          // ------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ปุ่ม Cancel
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                child: const Text("Cancel"),
              ),
              const SizedBox(width: 16),

              // ปุ่ม Accept
              ElevatedButton(
                onPressed: _onAcceptPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 24,
                  ),
                ),
                child: const Text("Accept"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
