// lib/services/agora_service.dart

import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();

  factory AgoraService() {
    return _instance;
  }

  AgoraService._internal();

  RtcEngine? _engine;
  final String _agoraAppId = "1f30c822357e4bb6b134faa84a0ebac1";
  final String _tokenServerUrl = 'http://192.168.0.45:8080';

  bool isMicEnabled = true;
  bool isCameraEnabled = true;

  final _remoteUsers = BehaviorSubject<List<int>>.seeded([]);
  final _localMicVolume = BehaviorSubject<int>.seeded(0);
  final _usersCameraStatus = BehaviorSubject<Map<int, bool>>.seeded({});

  Stream<List<int>> get remoteUsers => _remoteUsers.stream;
  Stream<int> get localMicVolume => _localMicVolume.stream;
  Stream<Map<int, bool>> get usersCameraStatus => _usersCameraStatus.stream;

  RtcEngine? getEngine() => _engine;

  Future<void> initAgora({required ClientRoleType role}) async {
    _engine = createAgoraRtcEngine();
    
    await _engine!.initialize(RtcEngineContext(
      appId: _agoraAppId,
    ));

    _engine!.enableAudioVolumeIndication(
      interval: 200,
      smooth: 3,
      reportVad: false,
    );

    await _engine!.enableVideo();
    await _engine!.setClientRole(role: role);
    _setupAgoraListeners();
  }

  void _setupAgoraListeners() {
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          print("L'utilisateur ${connection.localUid} a rejoint le canal.");
          final currentStatus = _usersCameraStatus.value;
          _usersCameraStatus.add({
            ...currentStatus,
            connection.localUid!: true,
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          print("L'utilisateur distant $remoteUid a rejoint le canal.");
          final currentUsers = _remoteUsers.value;
          _remoteUsers.add([...currentUsers, remoteUid]);
          final currentStatus = _usersCameraStatus.value;
          _usersCameraStatus.add({
            ...currentStatus,
            remoteUid: true,
          });
        },
        onUserOffline: (connection, remoteUid, reason) {
          print("L'utilisateur distant $remoteUid a quitté le canal.");
          final currentUsers = _remoteUsers.value;
          _remoteUsers.add(currentUsers.where((uid) => uid != remoteUid).toList());
          final currentStatus = _usersCameraStatus.value;
          currentStatus.remove(remoteUid);
          _usersCameraStatus.add(currentStatus);
        },
        onLeaveChannel: (connection, stats) {
          print("L'utilisateur a quitté le canal.");
          _remoteUsers.add([]);
          _usersCameraStatus.add({});
        },
        onAudioVolumeIndication: (connection, speakers, totalVolume, speakerNumber) {
          for (var speaker in speakers) {
            if (speaker.uid == 0) {
              _localMicVolume.add(speaker.volume ?? 0);
              break;
            }
          }
        },
        onUserEnableVideo: (connection, remoteUid, enabled) {
          final currentStatus = _usersCameraStatus.value;
          _usersCameraStatus.add({
            ...currentStatus,
            remoteUid: enabled,
          });
        },
        onUserMuteVideo: (connection, remoteUid, muted) {
          final currentStatus = _usersCameraStatus.value;
          _usersCameraStatus.add({
            ...currentStatus,
            remoteUid: !muted,
          });
        }
      ),
    );
  }

  Future<void> joinChannel(String channelName) async {
    try {
      final response = await http.get(Uri.parse('$_tokenServerUrl/rtc/$channelName/0'));

      if (response.statusCode != 200) {
        throw Exception('Erreur serveur: ${response.statusCode}, ${response.body}');
      }

      final token = jsonDecode(response.body)['token'];

      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0,
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      print("Erreur de récupération de jeton : $e");
      rethrow;
    }
  }

  Future<void> leaveChannel() async {
    if (_engine == null) return;
    final state = await _engine!.getConnectionState();
    if (state != ConnectionStateType.connectionStateConnected &&
        state != ConnectionStateType.connectionStateConnecting) {
      print("Le client n'est pas dans un canal. Pas besoin de le quitter.");
      return;
    }
    await _engine!.leaveChannel();
    print("Le client a quitté le canal.");
  }

  Future<void> toggleMic(bool enabled) async {
    if (_engine == null) return;
    isMicEnabled = enabled;
    await _engine!.muteLocalAudioStream(!enabled);
  }

  Future<void> toggleCamera(bool enabled) async {
    if (_engine == null) return;
    isCameraEnabled = enabled;
    await _engine!.enableLocalVideo(enabled); // CORRECTION ICI
    
    final currentStatus = _usersCameraStatus.value;
    _usersCameraStatus.add({
      ...currentStatus,
      0: enabled,
    });
  }

  Future<void> switchCamera() async {
    if (_engine == null) return;
    await _engine!.switchCamera();
  }

  Future<void> dispose() async {
    if (_engine != null) {
      _remoteUsers.close();
      _localMicVolume.close();
      _usersCameraStatus.close();
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
    }
  }
}