// lib/pages/live_debate_screen.dart

import 'dart:async';
import 'dart:ui';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:argu/services/agora_service.dart';
import 'package:argu/pages/home_page.dart';

// Enum to represent the distinct states of the debate lifecycle.
enum DebateLifecycleState {
  waitingForOpponent,
  countdownToStart,
  inProgress,
  opponentDisconnected,
}

class LiveDebateScreen extends StatefulWidget {
  final String debateId;
  final bool isSpectator;

  const LiveDebateScreen({
    super.key,
    required this.debateId,
    this.isSpectator = false,
  });

  @override
  State<LiveDebateScreen> createState() => _LiveDebateScreenState();
}

class _LiveDebateScreenState extends State<LiveDebateScreen> {
  final AgoraService _agoraService = AgoraService();
  RtcEngine? _engine;
  late final Future<void> _initializationFuture;

  // State management for the debate lifecycle
  DebateLifecycleState _lifecycleState = DebateLifecycleState.waitingForOpponent;
  Timer? _mainDebateTimer;
  Duration _elapsedTime = Duration.zero;
  Timer? _countdownTimer;
  int _countdownSeconds = 3;
  Timer? _disconnectionTimer;
  int _disconnectionSeconds = 15;

  @override
  void initState() {
    super.initState();
    if (widget.isSpectator) {
      _lifecycleState = DebateLifecycleState.inProgress; // Spectators just watch
    }
    _initializationFuture = _initializeScreen();
  }

  @override
  void dispose() {
    _mainDebateTimer?.cancel();
    _countdownTimer?.cancel();
    _disconnectionTimer?.cancel();
    _agoraService.leaveChannel();
    _agoraService.dispose();
    super.dispose();
  }

  // --- Initialization and State Management ---

  Future<void> _initializeScreen() async {
    try {
      await _agoraService.initAgora(
        role: widget.isSpectator ? ClientRoleType.clientRoleAudience : ClientRoleType.clientRoleBroadcaster,
      );
      _engine = _agoraService.getEngine();
      await _agoraService.joinChannel(widget.debateId);

      // The main timer is now started by the state machine, not on init.
    } catch (error) {
      print("Error during screen initialization: $error");
      rethrow;
    }
  }

  void _handleParticipantChange(int remoteParticipantCount) {
    if (widget.isSpectator) return; // State logic doesn't apply to spectators

    // --- Opponent Joins ---
    if (remoteParticipantCount > 0 && _lifecycleState == DebateLifecycleState.waitingForOpponent) {
      _startCountdown();
    }
    // --- Opponent Leaves ---
    else if (remoteParticipantCount == 0 && _lifecycleState == DebateLifecycleState.inProgress) {
      _startDisconnectionGracePeriod();
    }
    // --- Opponent Rejoins ---
    else if (remoteParticipantCount > 0 && _lifecycleState == DebateLifecycleState.opponentDisconnected) {
      _cancelDisconnectionGracePeriod();
    }
  }

  void _startCountdown() {
    if (!mounted) return;
    // Schedule the SnackBar to show after the current build frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opponent joined! Debate starting soon..."), duration: Duration(seconds: 2)));
      }
    });
    setState(() {
      _lifecycleState = DebateLifecycleState.countdownToStart;
      _countdownSeconds = 3;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_countdownSeconds > 1) {
        if (mounted) setState(() => _countdownSeconds--);
      } else {
        _countdownTimer?.cancel();
        _startDebate();
      }
    });
  }

  void _startDebate() async {
    if (!mounted) return;
    setState(() => _lifecycleState = DebateLifecycleState.inProgress);
    try {
      final debateDoc = await FirebaseFirestore.instance.collection('debates').doc(widget.debateId).get();
      final data = debateDoc.data();
      if (data != null && data.containsKey('createdAt')) {
        _startMainTimer((data['createdAt'] as Timestamp).toDate());
      }
    } catch (e) {
      print("Error fetching start time: $e");
    }
  }

  void _startDisconnectionGracePeriod() {
    if (!mounted) return;
    setState(() {
      _lifecycleState = DebateLifecycleState.opponentDisconnected;
      _disconnectionSeconds = 15;
    });
    _disconnectionTimer?.cancel();
    _disconnectionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disconnectionSeconds > 0) {
        if (mounted) setState(() => _disconnectionSeconds--);
      }
    });
  }

  void _cancelDisconnectionGracePeriod() {
    if (!mounted) return;
    _disconnectionTimer?.cancel();
    setState(() => _lifecycleState = DebateLifecycleState.inProgress);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opponent reconnected!"), duration: Duration(seconds: 2)));
  }

  Future<void> _endDebateDueToDisconnect() async {
    if (mounted) {
      // Prevent user interaction while ending
      setState(() => _lifecycleState = DebateLifecycleState.waitingForOpponent);
      await _updateDebateStatus('finished');
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Debate Ended"),
          content: const Text("Your opponent failed to reconnect in time."),
          actions: [TextButton(child: const Text("OK"), onPressed: () => Navigator.of(ctx).pop())],
        ),
      ).then((_) => Navigator.of(context).pop());
    }
  }

  // --- Timers and Formatters ---

  void _startMainTimer(DateTime startTime) {
    _mainDebateTimer?.cancel();
    _mainDebateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedTime = DateTime.now().difference(startTime));
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  // --- UI Actions ---

  void _toggleMic() => setState(() => _agoraService.toggleMic(!_agoraService.isMicEnabled));
  void _toggleCamera() => setState(() => _agoraService.toggleCamera(!_agoraService.isCameraEnabled));

  Future<void> _updateDebateStatus(String status) async {
    if (!widget.isSpectator) {
      await FirebaseFirestore.instance.collection('debates').doc(widget.debateId).update({
        'status': status,
        'finishedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _endCall() async {
    await _updateDebateStatus('finished');
    if (mounted) Navigator.of(context).pop();
  }

  // --- Widget Builders ---

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_formatDuration(_elapsedTime)),
          actions: [/*... existing actions ...*/],
        ),
        body: FutureBuilder<void>(
          future: _initializationFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error during connection: ${snapshot.error}'));
            }
            return StreamBuilder<List<int>>(
              stream: _agoraService.remoteUsers,
              builder: (context, remoteSnapshot) {
                final remoteUids = remoteSnapshot.data ?? [];
                _handleParticipantChange(remoteUids.length);

                return StreamBuilder<Map<int, bool>>(
                  stream: _agoraService.usersCameraStatus,
                  builder: (context, cameraStatusSnapshot) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildVideoFeeds(remoteUids, cameraStatusSnapshot.data ?? {}),
                        _buildLifecycleOverlay(),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoFeeds(List<int> remoteUids, Map<int, bool> usersCameraStatus) {
    if (_engine == null) return const Center(child: Text('Debate engine not ready.'));

    final remoteUser = remoteUids.isNotEmpty ? remoteUids.first : null;
    final localUser = !widget.isSpectator ? 0 : null;

    return Stack(
      children: [
        if (remoteUser != null)
          SizedBox.expand(
            child: _videoView(remoteUser, usersCameraStatus[remoteUser] ?? true, _engine!),
          ),
        if (localUser != null)
          Positioned(
            bottom: 20, right: 20, width: 120, height: 160,
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
              child: _videoView(localUser, usersCameraStatus[localUser] ?? true, _engine!),
            ),
          ),
      ],
    );
  }

  Widget _buildLifecycleOverlay() {
    if (_lifecycleState == DebateLifecycleState.inProgress) {
      return const SizedBox.shrink();
    }
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

  Widget _buildOverlayContent() {
    switch (_lifecycleState) {
      case DebateLifecycleState.waitingForOpponent:
        return const Text('Waiting for an opponent...', style: TextStyle(color: Colors.white, fontSize: 24));
      case DebateLifecycleState.countdownToStart:
        return Text(_countdownSeconds.toString(), style: const TextStyle(color: Colors.white, fontSize: 96, fontWeight: FontWeight.bold));
      case DebateLifecycleState.opponentDisconnected:
        return Text('Opponent disconnected. Reconnecting in...\n$_disconnectionSeconds', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _videoView(int uid, bool isVideoEnabled, RtcEngine engine) {
    return ClipRRect(
      child: Stack(
        children: [
          if (isVideoEnabled)
            AgoraVideoView(
              controller: VideoViewController(rtcEngine: engine, canvas: VideoCanvas(uid: uid)),
            ),
          if (!isVideoEnabled)
            Container(
              color: Colors.black,
              child: const Center(child: Icon(Icons.videocam_off, color: Colors.white, size: 48)),
            ),
        ],
      ),
    );
  }
}