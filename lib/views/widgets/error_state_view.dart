import 'package:flutter/material.dart';

class ErrorStateView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorStateView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              friendlyMessage(message),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

String friendlyMessage(String rawError) {
  final lower = rawError.toLowerCase();
  if (lower.contains('timed out')) {
    return 'Connection is too slow. Please check your internet and try again.';
  }
  if (lower.contains('failed host lookup') || lower.contains('socketexception') || lower.contains('network')) {
    return 'No internet connection. Please check your network and try again.';
  }
  if (lower.contains('request failed')) {
    return 'Something went wrong loading this content. Please try again.';
  }
  return 'Something went wrong. Please try again.';
}
