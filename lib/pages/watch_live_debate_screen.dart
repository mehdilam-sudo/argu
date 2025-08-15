// lib/pages/watch_debate_screen.dart

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:argu/services/agora_service.dart';

class WatchDebateScreen extends StatefulWidget {
  final String debateId;

  const WatchDebateScreen({
    super.key,
    required this.debateId,
  });

  @override
  State<WatchDebateScreen> createState() => _WatchDebateScreenState();
}

class _WatchDebateScreenState extends State<WatchDebateScreen> {
  final AgoraService _agoraService = AgoraService();
  RtcEngine? _engine;
  late final Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    // Initialisation en mode spectateur
    _initializationFuture = _agoraService.initAgora(
      role: ClientRoleType.clientRoleAudience,
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
    // Nettoyage des ressources Agora
    _agoraService.leaveChannel();
    _agoraService.dispose();
    super.dispose();
  }

  // Crée un widget réutilisable pour afficher une vidéo
  Widget _videoView(int uid, bool isVideoEnabled, RtcEngine engine) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Débat en direct (Spectateur)'),
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
              final allUids = remoteUids;

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
                  
                  // Affiche tous les participants en tant que spectateur
                  return Column(
                    children: [
                      ...allUids.map((uid) {
                        return _videoView(uid, usersCameraStatus[uid] ?? true, _engine!);
                      }),
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