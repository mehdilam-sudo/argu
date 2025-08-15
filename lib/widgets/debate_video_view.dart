// lib/widgets/debate_video_view.dart

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

/// A widget that displays a user's video stream from the Agora engine.
///
/// It shows the video if it's enabled, otherwise it displays a
/// "video off" icon.
class DebateVideoView extends StatelessWidget {
  /// The user ID (uid) from Agora. Use 0 for the local user.
  final int uid;

  /// A boolean to determine if the video is currently enabled for the user.
  final bool isVideoEnabled;

  /// The instance of the Agora RTC engine.
  final RtcEngine engine;

  const DebateVideoView({
    super.key,
    required this.uid,
    required this.isVideoEnabled,
    required this.engine,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: Stack(
        children: [
          // If video is enabled, show the AgoraVideoView.
          if (isVideoEnabled)
            AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: engine,
                canvas: VideoCanvas(uid: uid),
              ),
            ),
          // If video is disabled, show a placeholder.
          if (!isVideoEnabled)
            Container(
              color: Colors.black,
              child: const Center(
                child: Icon(Icons.videocam_off, color: Colors.white, size: 48),
              ),
            ),
        ],
      ),
    );
  }
}
