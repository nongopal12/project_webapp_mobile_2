import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter

/// Add Room Page (Matches Database)
class AddRoom extends StatefulWidget {
  const AddRoom({super.key});

  @override
  State<AddRoom> createState() => _AddRoomState();
}

class _AddRoomState extends State<AddRoom> {
  // ================================================================
  // Section 1: Controllers & Data
  // ================================================================
  final _roomNumberController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();

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
  // Section 2: Functions
  // ================================================================

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

  /// Validate and return data
  void _acceptRoom() {
    final roomNum = _roomNumberController.text.trim();
    final location = _locationController.text.trim();
    final capacity = _capacityController.text.trim();

    if (roomNum.isEmpty || location.isEmpty || capacity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields."),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.fixed,
        ),
      );
      return;
    }

    // Return the correct Map data
    Navigator.of(context).pop({
      'room_number': int.parse(roomNum),
      'room_location': int.parse(location),
      'room_capacity': int.parse(capacity),
      'room_img': roomImages[_currentImageIndex],
    });
  }

  // ================================================================
  // Section 3: UI Build
  // ================================================================
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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

          // Image Viewer with Fixed Aspect Ratio
          AspectRatio(
            aspectRatio: 16 / 9, // ล็อคสัดส่วน 16:9
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: Colors.grey[200],
                    child: Image.asset(
                      roomImages[_currentImageIndex],
                      fit: BoxFit.cover, // ครอบคลุมพื้นที่ทั้งหมดโดยตัดส่วนเกิน
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
                Positioned(
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () => _changeImage(false),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                    ),
                  ),
                ),
                Positioned(
                  right: 8,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                    ),
                    onPressed: () => _changeImage(true),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                    ),
                  ),
                ),
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
          ),
          const SizedBox(height: 16),

          // Input Fields
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: "Floor (e.g., 1, 2, 3...)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _roomNumberController,
            decoration: InputDecoration(
              labelText: "Room Number (e.g., 1, 2, 3...)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _capacityController,
            decoration: InputDecoration(
              labelText: "Capacity (e.g., 4, 6, 8...)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 20),

          // Buttons
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
