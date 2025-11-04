import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Edit Room Page (Shows Floor, but doesn't edit it)
class EditRoom extends StatefulWidget {
  final String initialImagePath;
  final int initialRoomNumber;
  final int initialLocation; // To display Floor
  final int initialCapacity;

  const EditRoom({
    super.key,
    required this.initialImagePath,
    required this.initialRoomNumber,
    required this.initialLocation,
    required this.initialCapacity,
  });

  @override
  State<EditRoom> createState() => _EditRoomState();
}

class _EditRoomState extends State<EditRoom> {
  // ================================================================
  // Section 1: Controllers
  // ================================================================
  late TextEditingController _roomNumberController;
  late TextEditingController _capacityController;

  @override
  void initState() {
    super.initState();
    _roomNumberController = TextEditingController(
      text: widget.initialRoomNumber.toString(),
    );
    _capacityController = TextEditingController(
      text: widget.initialCapacity.toString(),
    );
  }

  @override
  void dispose() {
    _roomNumberController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  // ================================================================
  // Section 2: Accept Function
  // ================================================================
  void _onAcceptPressed() {
    final roomNum = _roomNumberController.text.trim();
    final capacity = _capacityController.text.trim();

    if (roomNum.isEmpty || capacity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Fields cannot be empty"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Return Map "without" location (as it wasn't edited)
    Navigator.of(context).pop({
      'room_number': int.parse(roomNum),
      'room_capacity': int.parse(capacity),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
          // Image
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

          // Input Fields

          // Read-only Floor display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[400]!),
            ),
            child: Text(
              "Floor: ${widget.initialLocation}",
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
          const SizedBox(height: 12),

          // Editable Room Number
          TextField(
            controller: _roomNumberController,
            decoration: InputDecoration(
              labelText: "Room Number (on this floor)",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 12),

          // Editable Capacity
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
