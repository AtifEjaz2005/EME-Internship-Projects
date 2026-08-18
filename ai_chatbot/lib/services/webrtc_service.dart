import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import '../database/database_service.dart';

class WebRTCService {
  webrtc.RTCPeerConnection? peerConnection;
  webrtc.MediaStream? localStream;
  webrtc.MediaStream? remoteStream;

  // The "Map" to help phones find each other
  final Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ],
      },
    ],
  };

  // --- INITIALIZE THE ENGINE ---
  Future<void> createPeerConnection(
    DatabaseService dbService,
    String roomId,
    bool isCaller,
  ) async {
    // This builds the "Radio Station" (The Bridge)
    peerConnection = await webrtc.createPeerConnection(configuration);

    // What to do when your friend's video/audio arrives
    peerConnection!.onTrack = (webrtc.RTCTrackEvent event) {
      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];
      }
    };

    // What to do when your phone finds its "Home Address"
    peerConnection!.onIceCandidate =
        (webrtc.RTCIceCandidate candidate) {
      if (candidate.candidate != null) {
        dbService.addIceCandidate(
          roomId,
          candidate.toMap(),
          isCaller,
        );
      }
    };

    // Add your camera/mic to the connection
    if (localStream != null) {
      for (final track in localStream!.getTracks()) {
        await peerConnection!.addTrack(
          track,
          localStream!,
        );
      }
    }
  }

  // --- MEDIA HARDWARE ---
  Future<webrtc.MediaStream> openUserMedia() async {
    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': {
        'facingMode': 'user',
      },
    };

    localStream =
        await webrtc.navigator.mediaDevices.getUserMedia(constraints);

    return localStream!;
  }

  // --- CLEANUP ---
  Future<void> dispose() async {
    // Stop local camera/microphone tracks
    if (localStream != null) {
      for (final track in localStream!.getTracks()) {
        track.stop();
      }
    }

    // Stop remote tracks
    if (remoteStream != null) {
      for (final track in remoteStream!.getTracks()) {
        track.stop();
      }
    }

    // Dispose peer connection
    await peerConnection?.dispose();

    // Dispose media streams
    await localStream?.dispose();
    await remoteStream?.dispose();

    // Clear references
    peerConnection = null;
    localStream = null;
    remoteStream = null;
  }
}
