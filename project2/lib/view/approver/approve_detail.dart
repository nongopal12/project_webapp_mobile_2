import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Use QColors + BookingItem from home.dart
import 'home.dart';

const String kBaseUrl = "http://192.168.1.123:3000";

class ApproveDetailPage extends StatefulWidget {
  final BookingItem item;
  const ApproveDetailPage({super.key, required this.item});

  @override
  State<ApproveDetailPage> createState() => _ApproveDetailPageState();
}

class _ApproveDetailPageState extends State<ApproveDetailPage> {
  bool _busy = false;

  /// ====== Call API to update status (2 = approve, 3 = reject) ======
  Future<void> _updateStatus(String statusCode, {String? reason}) async {
    setState(() => _busy = true);
    try {
      final uri = Uri.parse('$kBaseUrl/api/approver/booking/${widget.item.id}');
      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': statusCode}),
      );
      if (res.statusCode != 200) {
        throw Exception('Update failed (${res.statusCode})');
      }

      if (!mounted) return;

      final msg = statusCode == "2"
          ? 'Request #${widget.item.id} has been approved.'
          : 'Request #${widget.item.id} has been rejected'
              '${(reason != null && reason.trim().isNotEmpty) ? ' (Reason: ${reason.trim()})' : ''}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );

      Navigator.pop(context, true); // go back to previous page
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// ====== Confirm approve (same logic as approve.dart) ======
  Future<void> _confirmApprove() async {
    final it = widget.item;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Approval'),
        content: Text(
          'Do you want to approve request #${it.id}?\n'
          'Room: ${it.room}\n'
          'Time: ${it.time}\n'
          'Requested by: ${it.userName}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2ECC71),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _updateStatus("2");
    }
  }

  /// ====== Reject: always require a reason ======
  Future<void> _promptRejectReason() async {
    final it = widget.item;
    final ctl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Rejection'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Do you want to reject request #${it.id}?\n'
                'Room: ${it.room}\n'
                'Time: ${it.time}\n'
                'Requested by: ${it.userName}',
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ctl,
                autofocus: true,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Rejection reason',
                  hintText:
                      'e.g., schedule conflict / incomplete documents / overlapping usage',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a reason';
                  }
                  if (v.trim().length < 5) {
                    return 'Please enter at least 5 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit Reason'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _updateStatus("3", reason: ctl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    // Image from DB: room_img stores a file name e.g., "Meeting-RoomA.jpg"
    final imgUrl = '$kBaseUrl/assets/${it.imagePath}';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Details'),
        backgroundColor: QColors.primaryRed,
        foregroundColor: Colors.white,
      ),
      backgroundColor: QColors.bg,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: QColors.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              /// ====== Room image at the top (from DB) ======
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    imgUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.meeting_room_outlined,
                        size: 48,
                        color: QColors.primaryRed,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// ====== Request information ======
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('Order Number', '#${it.id}'),
                    const SizedBox(height: 8),
                    _row('Room', it.room),
                    const SizedBox(height: 8),
                    _row('Time', it.time),
                    const SizedBox(height: 8),
                    _row('Requested by', it.userName),
                  ],
                ),
              ),

              const Spacer(),

              /// ====== Approve / Reject buttons ======
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _busy ? null : _confirmApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2ECC71),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Approve',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _busy ? null : _promptRejectReason,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE74C3C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _busy
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Reject',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String k, String v) {
    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$k :',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Expanded(
          child: Text(
            v,
            style: const TextStyle(color: QColors.text),
          ),
        ),
      ],
    );
  }
}
