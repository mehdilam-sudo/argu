// lib/widgets/debate_lifecycle_overlay.dart

// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:argu/pages/live_debate_screen.dart'; // Import the enum

/// A widget that displays an overlay corresponding to the current state of the debate.
///
/// This includes states like waiting for an opponent, countdowns, and disconnection notices.
class DebateLifecycleOverlay extends StatelessWidget {
  /// The current state of the debate's lifecycle.
  final DebateLifecycleState lifecycleState;

  /// The remaining seconds for the pre-debate countdown.
  final int countdownSeconds;

  /// The remaining seconds for the disconnection grace period.
  final int disconnectionSeconds;

  const DebateLifecycleOverlay({
    super.key,
    required this.lifecycleState,
    required this.countdownSeconds,
    required this.disconnectionSeconds,
  });

  @override
  Widget build(BuildContext context) {
    // If the debate is in progress or finished, show nothing.
    if (lifecycleState == DebateLifecycleState.inProgress || lifecycleState == DebateLifecycleState.finished) {
      return const SizedBox.shrink();
    }

    // For all other states, show a blurred overlay with content.
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: Center(
            child: _buildOverlayContent(),
          ),
        ),
      ),
    );
  }

  /// Builds the specific content for the overlay based on the lifecycle state.
  Widget _buildOverlayContent() {
    switch (lifecycleState) {
      case DebateLifecycleState.waitingForOpponent:
        return const Text('Waiting for an opponent...', style: TextStyle(color: Colors.white, fontSize: 24));
      case DebateLifecycleState.countdownToStart:
        return Text(countdownSeconds.toString(), style: const TextStyle(color: Colors.white, fontSize: 96, fontWeight: FontWeight.bold));
      case DebateLifecycleState.opponentDisconnected:
        return Text('Opponent disconnected. Reconnecting in...\n$disconnectionSeconds', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22));
      default:
        // This case is handled by the check at the beginning of the build method.
        return const SizedBox.shrink();
    }
  }
}
