// lib/incoming_call_popup.dart
import 'package:flutter/material.dart';

class IncomingCallPopup extends StatelessWidget {
  final String callerId;
  final bool isVideo;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const IncomingCallPopup({
    super.key,
    required this.callerId,
    required this.isVideo,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Incoming Call'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isVideo ? Icons.videocam : Icons.call, size: 48, color: Colors.deepPurple),
          const SizedBox(height: 12),
          Text('$callerId is calling'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: onReject,
          child: const Text('Reject', style: TextStyle(color: Colors.red)),
        ),
        ElevatedButton(
          onPressed: onAccept,
          child: const Text('Accept'),
        ),
      ],
    );
  }
}