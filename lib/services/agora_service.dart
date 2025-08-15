// lib/services/agora_service.dart

import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// This is now a regular class. A new instance will be created for each debate.
class AgoraService {
  RtcEngine? _engine;
  final String _agoraAppId = "1f30c822357e4bb6b134faa84a0ebac1";
  final String _tokenServerUrl = 'http://192.168.0.45:8080';

  bool isMicEnabled = true;
  bool isCameraEnabled = true;

  // Use BehaviorSubject to get the last emitted value upon subscription.
  // These are re-initialized for each new instance of the service.
  final _remoteUsers = BehaviorSubject<List<int>>.seeded([]);
  final _localMicVolume = BehaviorSubject<int>.seeded(0);
  final _usersCameraStatus = BehaviorSubject<Map<int, bool>>.seeded({});

  // Public streams for widgets to listen to.
  Stream<List<int>> get remoteUsers => _remoteUsers.stream;
  Stream<int> get localMicVolume => _localMicVolume.stream;
  Stream<Map<int, bool>> get usersCameraStatus => _usersCameraStatus.stream;

  RtcEngine? getEngine() => _engine;

  Future<void> initAgora({required ClientRoleType role}) async {
    _engine = createAgoraRtcEngine();
    
    await _engine!.initialize(RtcEngineContext(
      appId: _agoraAppId,
    ));

    await _engine!.setAINSMode(enabled: true, mode: AudioAinsMode.ainsModeAggressive);

    _engine!.enableAudioVolumeIndication(
      interval: 200,
      smooth: 3,
      reportVad: true,
    );

    await _engine!.enableVideo();
    await _engine!.setClientRole(role: role);
    _setupAgoraListeners();
  }

  void _setupAgoraListeners() {
    _engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          print("Local user ${connection.localUid} joined the channel.");
          // FIX: Check if the stream controller is closed before adding events.
          if (_usersCameraStatus.isClosed) return;
          final currentStatus = _usersCameraStatus.value;
          _usersCameraStatus.add({
            ...currentStatus,
            connection.localUid!: true,
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          print("Remote user $remoteUid joined the channel.");
          if (!_remoteUsers.isClosed) {
            final currentUsers = _remoteUsers.value;
            _remoteUsers.add([...currentUsers, remoteUid]);
          }
          if (!_usersCameraStatus.isClosed) {
            final currentStatus = _usersCameraStatus.value;
            _usersCameraStatus.add({
              ...currentStatus,
              remoteUid: true,
            });
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          print("Remote user $remoteUid left the channel.");
          if (!_remoteUsers.isClosed) {
            final currentUsers = _remoteUsers.value;
            _remoteUsers.add(currentUsers.where((uid) => uid != remoteUid).toList());
          }
          if (!_usersCameraStatus.isClosed) {
            final currentStatus = _usersCameraStatus.value;
            currentStatus.remove(remoteUid);
            _usersCameraStatus.add(currentStatus);
          }
        },
        onLeaveChannel: (connection, stats) {
          print("User left the channel.");
          if (!_remoteUsers.isClosed) _remoteUsers.add([]);
          if (!_usersCameraStatus.isClosed) _usersCameraStatus.add({});
        },
        onAudioVolumeIndication: (connection, speakers, totalVolume, speakerNumber) {
          if (_localMicVolume.isClosed) return;
          for (var speaker in speakers) {
            if (speaker.uid == 0) { // 0 is the local user
              if (speaker.vad == 1) {
                _localMicVolume.add(speaker.volume ?? 0);
              } else {
                _localMicVolume.add(0);
              }
              break;
            }
          }
        },
        onUserEnableVideo: (connection, remoteUid, enabled) {
          if (_usersCameraStatus.isClosed) return;
          final currentStatus = _usersCameraStatus.value;
          _usersCameraStatus.add({
            ...currentStatus,
            remoteUid: enabled,
          });
        },
        onUserMuteVideo: (connection, remoteUid, muted) {
          if (_usersCameraStatus.isClosed) return;
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
        throw Exception('Server Error: ${response.statusCode}, ${response.body}');
      }

      final token = jsonDecode(response.body)['token'];

      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: 0, // Local user ID is 0
        options: const ChannelMediaOptions(),
      );
    } catch (e) {
      print("Token fetch error: $e");
      rethrow;
    }
  }

  Future<void> leaveChannel() async {
    if (_engine == null) return;
    await _engine!.leaveChannel();
    print("Client left the channel.");
  }

  Future<void> toggleMic(bool enabled) async {
    if (_engine == null) return;
    isMicEnabled = enabled;
    await _engine!.muteLocalAudioStream(!enabled);
  }

  Future<void> toggleCamera(bool enabled) async {
    if (_engine == null) return;
    isCameraEnabled = enabled;
    await _engine!.enableLocalVideo(enabled);
    
    // FIX: Check if the stream controller is closed before adding events.
    if (!_usersCameraStatus.isClosed) {
      final currentStatus = _usersCameraStatus.value;
      _usersCameraStatus.add({
        ...currentStatus,
        0: enabled, // 0 is the local user
      });
    }
  }

  Future<void> switchCamera() async {
    if (_engine == null) return;
    await _engine!.switchCamera();
  }

  Future<void> dispose() async {
    if (_engine != null) {
      // Close all stream controllers to prevent memory leaks.
      _remoteUsers.close();
      _localMicVolume.close();
      _usersCameraStatus.close();
      
      // Leave the channel and release the engine resources.
      await _engine!.leaveChannel();
      await _engine!.release();
      _engine = null;
    }
  }
}