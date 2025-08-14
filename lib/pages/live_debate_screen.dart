// lib/pages/live_debate_screen.dart

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:argu/services/agora_service.dart';

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

  @override
  void initState() {
    super.initState();
    _initializationFuture = _agoraService.initAgora(
      role: widget.isSpectator ? ClientRoleType.clientRoleAudience : ClientRoleType.clientRoleBroadcaster,
    ).then((_) {
      _engine = _agoraService.getEngine();
      return _agoraService.joinChannel(widget.debateId);
    }).catchError((error) {
      print("Erreur de connexion détaillée : $error");
      throw error;
    });
  }

  @override
  void dispose() {
    _agoraService.leaveChannel();
    _agoraService.dispose();
    super.dispose();
  }

  void _toggleMic() {
    setState(() {
      _agoraService.toggleMic(!_agoraService.isMicEnabled);
    });
  }

  void _toggleCamera() {
    setState(() {
      _agoraService.toggleCamera(!_agoraService.isCameraEnabled);
    });
  }

  Future<void> _endCall() async {
    if (!widget.isSpectator) {
      await FirebaseFirestore.instance.collection('debates').doc(widget.debateId).update({
        'status': 'finished',
        'finishedAt': FieldValue.serverTimestamp(),
      });
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // Crée un widget réutilisable pour afficher une vidéo
  Widget _videoView(int uid, bool isVideoEnabled, RtcEngine engine) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: Stack(
        children: [
          if (isVideoEnabled)
            AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: engine,
                canvas: VideoCanvas(uid: uid),
              ),
            ),
          if (!isVideoEnabled)
            Container(
              color: Colors.black,
              child: const Center(
                child: Icon(
                  Icons.videocam_off,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
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
                  child: Icon(
                    volume > 0 ? Icons.graphic_eq : Icons.mic_off,
                    color: Colors.white,
                    size: 18,
                  ),
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
        ],
      ),
      body: FutureBuilder<void>(
        future: _initializationFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erreur lors de la connexion : ${snapshot.error}'));
          }
          return StreamBuilder<List<int>>(
            stream: _agoraService.remoteUsers,
            builder: (context, remoteSnapshot) {
              final remoteUids = remoteSnapshot.data ?? [];
              final allUids = widget.isSpectator ? remoteUids : [0, ...remoteUids];

              if (_engine == null) {
                  return const Center(child: Text('Le moteur de débat n\'est pas prêt.'));
              }

              if (allUids.isEmpty) {
                return const Center(
                  child: Text(
                    'En attente de participants...',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              return StreamBuilder<Map<int, bool>>(
                stream: _agoraService.usersCameraStatus,
                builder: (context, cameraStatusSnapshot) {
                  final usersCameraStatus = cameraStatusSnapshot.data ?? {};
                  
                  // Identifie le participant local et distant
                  final remoteUser = remoteUids.isNotEmpty ? remoteUids.first : null;
                  final localUser = allUids.contains(0) ? 0 : null;

                  return Stack(
                    children: [
                      // Affichage du flux vidéo du participant distant en arrière-plan
                      if (remoteUser != null)
                        SizedBox.expand(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0.0),
                            child: _videoView(
                              remoteUser,
                              usersCameraStatus[remoteUser] ?? true,
                              _engine!,
                            ),
                          ),
                        ),

                      // Affichage de ton propre flux vidéo en bas à droite
                      if (localUser != null)
                        Positioned(
                          bottom: 20,
                          right: 20,
                          child: Container(
                            width: 120, // Taille de la petite vidéo
                            height: 160,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: _videoView(
                              localUser,
                              usersCameraStatus[localUser] ?? true,
                              _engine!,
                            ),
                          ),
                        ),
                    ],
                  );
                }
              );
            },
          );
        },
      ),
    );
  }
}