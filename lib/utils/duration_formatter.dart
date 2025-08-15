// lib/utils/duration_formatter.dart

import 'dart:core';

/// Formats a [Duration] into a readable mm:ss string format.
///
/// For example, a duration of 75 seconds will be formatted as "01:15".
String formatDuration(Duration duration) {
  // Helper to pad a number with a leading zero if it's less than 10.
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  // Extracts minutes from the duration, ensuring it wraps around every 60 minutes.
  final minutes = twoDigits(duration.inMinutes.remainder(60));
  // Extracts seconds from the duration, ensuring it wraps around every 60 seconds.
  final seconds = twoDigits(duration.inSeconds.remainder(60));
  return '$minutes:$seconds';
}
