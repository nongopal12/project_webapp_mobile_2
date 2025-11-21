import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'home.dart';

const String kBaseUrl = "http://172.27.13.156:3000";

class ApproveDetailPage extends StatefulWidget {
  final BookingItem item;
  const ApproveDetailPage({super.key, required this.item});

  @override
  State<ApproveDetailPage> createState() => _ApproveDetailPageState();
}

class _ApproveDetailPageState extends State<ApproveDetailPage> {
  bool _busy = false;

  /// ========================================================
  ///  UPDATE STATUS API (ส่ง approver_id + reason)
  /// ========================================================
  Future<void> _updateStatus(String statusCode, {String? reason}) async {
    setState(() => _busy = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final approverId = prefs.getInt("uid"); // 👈 สำคัญมาก ต้องมี!!

      if (approverId == null) {
        throw Exception("Approver ID not found (uid is null).");
      }

      final uri = Uri.parse('$kBaseUrl/api/approver/booking/${widget.item.id}');

      final body = {
        'status': statusCode,
        'approver_id': approverId, // 👈 ส่งคนอนุมัติจริง!!
        'reject_reason': reason ?? "", // ส่งเหตุผล (ถ้าปฏิเสธ)
      };

      final res = await http.put(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode != 200) {
        throw Exception('Update failed (${res.statusCode}) → ${res.body}');
      }

      if (!mounted) return;

      final msg = statusCode == "2"
          ? "Request #${widget.item.id} approved."
          : "Request #${widget.item.id} rejected${(reason != null) ? " (Reason: $reason)" : ""}";

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// ========================================================
  ///  APPROVE CONFIRMATION
  /// ========================================================
  Future<void> _confirmApprove() async {
    final it = widget.item;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Approval"),
        content: Text(
          "Do you want to approve this request?\n"
          "Room: ${it.room}\n"
          "Time : ${it.time}\n"
          "Requested by: ${it.userName}",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF2ECC71),
              foregroundColor: Colors.white,
            ),
            child: const Text("Approve"),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _updateStatus("2"); // Approve
    }
  }

  /// ========================================================
  ///  REJECT WITH REASON
  /// ========================================================
  Future<void> _promptRejectReason() async {
    final it = widget.item;
    final ctl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Request"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Reject request #${it.id}?\n"
                "Room: ${it.room}\n"
                "Time : ${it.time}\n"
                "Requested by: ${it.userName}",
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: ctl,
                maxLines: 3,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: "Reason",
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return "Please enter a reason";
                  }
                  if (v.trim().length < 3) {
                    return "At least 3 characters";
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
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFE74C3C),
              foregroundColor: Colors.white,
            ),
            child: const Text("Submit"),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _updateStatus("3", reason: ctl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final imgUrl = "$kBaseUrl/assets/${it.imagePath}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Details"),
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
            children: [
              /// ==== IMAGE ====
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    imgUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.meeting_room_outlined,
                        size: 48,
                        color: QColors.primaryRed,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// ==== DETAILS ====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row("Order Number", "#${it.id}"),
                    _row("Room", it.room),
                    _row("Time", it.time),
                    _row("Requested by", it.userName),
                  ],
                ),
              ),

              const Spacer(),

              /// ==== BUTTONS ====
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _busy ? null : _confirmApprove,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2ECC71),
                          foregroundColor: Colors.white,
                        ),
                        child: _busy
                            ? circular()
                            : const Text(
                                "Approve",
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _busy ? null : _promptRejectReason,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE74C3C),
                          foregroundColor: Colors.white,
                        ),
                        child: _busy
                            ? circular()
                            : const Text(
                                "Reject",
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

  Widget circular() => const SizedBox(
    height: 20,
    width: 20,
    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
  );

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text("$k :", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(v, style: TextStyle(color: QColors.text)),
          ),
        ],
      ),
    );
  }
}
