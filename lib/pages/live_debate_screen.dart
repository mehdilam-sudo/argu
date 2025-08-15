// lib/pages/live_debate_screen.dart

import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:argu/services/agora_service.dart';
import 'package:argu/widgets/debate_lifecycle_overlay.dart';
import 'package:argu/widgets/debate_video_view.dart';
import 'package:argu/utils/duration_formatter.dart';

// Enum to represent the distinct states of the debate lifecycle.
// This remains here as it is tightly coupled with the screen's logic.
enum DebateLifecycleState {
  waitingForOpponent,
  countdownToStart,
  inProgress,
  opponentDisconnected,
  finished,
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

  // State management
  DebateLifecycleState _lifecycleState = DebateLifecycleState.waitingForOpponent;
  StreamSubscription? _remoteUsersSubscription;
  List<int> _remoteUids = [];
  String? _debatorOneUsername;
  String? _debatorTwoUsername;

  // Timers
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
      _lifecycleState = DebateLifecycleState.inProgress;
    }
    _initializationFuture = _initializeScreen();
    _fetchDebateDetails();
  }

  @override
  void dispose() {
    _remoteUsersSubscription?.cancel();
    _mainDebateTimer?.cancel();
    _countdownTimer?.cancel();
    _disconnectionTimer?.cancel();
    _agoraService.dispose();
    super.dispose();
  }

  // --- Initialization and State Management ---

  Future<void> _fetchDebateDetails() async {
    try {
      final debateDoc = await FirebaseFirestore.instance.collection('debates').doc(widget.debateId).get();
      final data = debateDoc.data();
      if (data != null && mounted) {
        setState(() {
          _debatorOneUsername = data['debatorOne'];
          _debatorTwoUsername = data['debatorTwo'];
        });
      }
    } catch (e) {
      print("Error fetching debate details: $e");
    }
  }

  Future<void> _initializeScreen() async {
    try {
      await _agoraService.initAgora(
        role: widget.isSpectator ? ClientRoleType.clientRoleAudience : ClientRoleType.clientRoleBroadcaster,
      );
      _engine = _agoraService.getEngine();
      await _agoraService.joinChannel(widget.debateId);
      _listenToParticipants();
    } catch (error) {
      print("Error during screen initialization: $error");
      rethrow;
    }
  }

  void _listenToParticipants() {
    _remoteUsersSubscription = _agoraService.remoteUsers.listen((remoteUids) {
      if (!mounted) return;
      setState(() => _remoteUids = remoteUids);
      _handleParticipantChange(remoteUids.length);
    });
  }

  void _handleParticipantChange(int remoteParticipantCount) {
    if (widget.isSpectator || _lifecycleState == DebateLifecycleState.finished) return;

    if (remoteParticipantCount > 0 && _lifecycleState == DebateLifecycleState.waitingForOpponent) {
      _fetchDebateDetails(); // Fetch usernames when opponent joins
      _startCountdown();
    } else if (remoteParticipantCount == 0 && _lifecycleState == DebateLifecycleState.inProgress) {
      _startDisconnectionGracePeriod();
    } else if (remoteParticipantCount > 0 && _lifecycleState == DebateLifecycleState.opponentDisconnected) {
      _cancelDisconnectionGracePeriod();
    }
  }

  void _startCountdown() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opponent joined! Debate starting soon..."), duration: Duration(seconds: 2)));
    });
    setState(() => _lifecycleState = DebateLifecycleState.countdownToStart);
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

  Future<void> _startDebate() async {
    if (!mounted) return;
    try {
      final debateDoc = await FirebaseFirestore.instance.collection('debates').doc(widget.debateId).get();
      final data = debateDoc.data();
      
      // FIX: setState is called synchronously after the await.
      if (mounted) {
        setState(() => _lifecycleState = DebateLifecycleState.inProgress);
        if (data != null && data.containsKey('createdAt')) {
          _startMainTimer((data['createdAt'] as Timestamp).toDate());
        }
      }
    } catch (e) {
      print("Error fetching start time: $e");
    }
  }

  void _startDisconnectionGracePeriod() {
    if (!mounted) return;
    setState(() => _lifecycleState = DebateLifecycleState.opponentDisconnected);
    _disconnectionTimer?.cancel();
    _disconnectionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disconnectionSeconds > 0) {
        if (mounted) setState(() => _disconnectionSeconds--);
      } else {
        _disconnectionTimer?.cancel();
        _endDebateDueToDisconnect();
      }
    });
  }

  void _cancelDisconnectionGracePeriod() {
    if (!mounted) return;
    _disconnectionTimer?.cancel();
    setState(() => _lifecycleState = DebateLifecycleState.inProgress);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Opponent reconnected!"), duration: Duration(seconds: 2)));
    });
  }

  Future<void> _endDebateDueToDisconnect() async {
    if (!mounted || _lifecycleState == DebateLifecycleState.finished) return;

    setState(() => _lifecycleState = DebateLifecycleState.finished);
    await _updateDebateStatus('finished');

    final currentContext = context;
    if (!currentContext.mounted) return;

    await showDialog(
      context: currentContext,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Debate Ended"),
        content: const Text("Your opponent failed to reconnect in time."),
        actions: [TextButton(child: const Text("OK"), onPressed: () => Navigator.of(ctx).pop())],
      ),
    );
    
    if (!currentContext.mounted) return;
    Navigator.of(currentContext).pop();
  }

  void _startMainTimer(DateTime startTime) {
    _mainDebateTimer?.cancel();
    _mainDebateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedTime = DateTime.now().difference(startTime));
    });
  }

  // --- UI Actions ---

  /// Toggles the microphone. This is now an async function.
  Future<void> _toggleMic() async {
    // Await the async operation from the service first.
    await _agoraService.toggleMic(!_agoraService.isMicEnabled);
    // Then, update the state synchronously if the widget is still mounted.
    if (mounted) {
      setState(() {
        // The state is now sourced directly from the service.
      });
    }
  }

  /// Toggles the camera. This is now an async function.
  Future<void> _toggleCamera() async {
    // Await the async operation from the service first.
    await _agoraService.toggleCamera(!_agoraService.isCameraEnabled);
    // Then, update the state synchronously if the widget is still mounted.
    if (mounted) {
      setState(() {
        // The state is now sourced directly from the service.
      });
    }
  }

  Future<void> _updateDebateStatus(String status) async {
    if (!widget.isSpectator) {
      await FirebaseFirestore.instance.collection('debates').doc(widget.debateId).update({
        'status': status,
        'finishedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _endCall() async {
    if (_lifecycleState == DebateLifecycleState.finished) return;
    setState(() => _lifecycleState = DebateLifecycleState.finished);
    await _updateDebateStatus('finished');
    if (mounted) Navigator.of(context).pop();
  }

  // --- Widget Builders ---

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(formatDuration(_elapsedTime)),
          actions: _buildAppBarActions(),
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
            return StreamBuilder<Map<int, bool>>(
              stream: _agoraService.usersCameraStatus,
              builder: (context, cameraStatusSnapshot) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildVideoFeeds(_remoteUids, cameraStatusSnapshot.data ?? {}),
                    DebateLifecycleOverlay(
                      lifecycleState: _lifecycleState,
                      countdownSeconds: _countdownSeconds,
                      disconnectionSeconds: _disconnectionSeconds,
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      StreamBuilder<int>(
        stream: _agoraService.localMicVolume,
        builder: (context, snapshot) {
          final volume = snapshot.data ?? 0;
          return Container(
            margin: const EdgeInsets.only(right: 12.0),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: volume > 0 ? Colors.green.withAlpha((volume * 255 / 255.0).round()) : Colors.red,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(volume > 0 ? Icons.graphic_eq : Icons.mic_off, color: Colors.white, size: 18),
            ),
          );
        },
      ),
      IconButton(
        icon: Icon(_agoraService.isMicEnabled ? Icons.mic : Icons.mic_off),
        onPressed: widget.isSpectator ? null : _toggleMic,
      ),
      IconButton(
        icon: Icon(_agoraService.isCameraEnabled ? Icons.videocam : Icons.videocam_off),
        onPressed: widget.isSpectator ? null : _toggleCamera,
      ),
      if (!widget.isSpectator)
        IconButton(
          icon: const Icon(Icons.cameraswitch),
          onPressed: () => _agoraService.switchCamera(),
        ),
      IconButton(
        icon: const Icon(Icons.call_end, color: Colors.red),
        onPressed: _endCall,
      ),
    ];
  }

  Widget _buildVideoFeeds(List<int> remoteUids, Map<int, bool> usersCameraStatus) {
    if (_engine == null) return const Center(child: Text('Debate engine not ready.'));

    final remoteUser = remoteUids.isNotEmpty ? remoteUids.first : null;
    final localUser = !widget.isSpectator ? 0 : null;

    return Stack(
      children: [
        if (remoteUser != null)
          SizedBox.expand(
            child: _buildUserVideo(remoteUser, usersCameraStatus[remoteUser] ?? true, _debatorTwoUsername),
          ),
        if (localUser != null)
          Positioned(
            bottom: 20, right: 20, width: 120, height: 160,
            child: _buildUserVideo(localUser, usersCameraStatus[localUser] ?? true, _debatorOneUsername),
          ),
      ],
    );
  }

  Widget _buildUserVideo(int uid, bool isVideoEnabled, String? username) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2)),
      child: Stack(
        children: [
          DebateVideoView(
            uid: uid,
            isVideoEnabled: isVideoEnabled,
            engine: _engine!,
          ),
          if (username != null)
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                color: Colors.black.withAlpha(128),
                child: Text(
                  username,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}