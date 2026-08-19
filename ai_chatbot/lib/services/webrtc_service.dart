import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;

import '../database/database_service.dart';

class WebRTCService {
  webrtc.RTCPeerConnection? peerConnection;
  webrtc.MediaStream? localStream;
  webrtc.MediaStream? remoteStream;

  bool _remoteDescriptionSet = false;
  bool _disposed = false;

  final List<webrtc.RTCIceCandidate> _pendingCandidates = [];

  StreamSubscription<QuerySnapshot>? _iceSubscription;
  StreamSubscription<DocumentSnapshot>? _answerSubscription;

  /// The UI can listen to this when the remote audio/video stream arrives.
  void Function(webrtc.MediaStream stream)? onRemoteStream;

  final Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302',
        ],
      },

      // IMPORTANT:
      // Add your TURN server here for reliable calls across
      // mobile networks, CGNAT, restrictive Wi-Fi, etc.
      //
      // Example:
      //
      // {
      //   'urls': 'turn:YOUR_TURN_SERVER:3478',
      //   'username': 'YOUR_USERNAME',
      //   'credential': 'YOUR_PASSWORD',
      // },
    ],
  };

  Future<void> createPeerConnection(
    DatabaseService dbService,
    String roomId,
    bool isCaller,
  ) async {
    peerConnection = await webrtc.createPeerConnection(configuration);

    peerConnection!.onTrack = (webrtc.RTCTrackEvent event) {
      if (_disposed) return;

      if (event.streams.isNotEmpty) {
        remoteStream = event.streams[0];

        onRemoteStream?.call(remoteStream!);
      }
    };

    peerConnection!.onIceCandidate = (webrtc.RTCIceCandidate candidate) async {
      if (_disposed) return;

      if (candidate.candidate != null) {
        try {
          await dbService.addIceCandidate(roomId, candidate.toMap(), isCaller);
        } catch (e) {
          print('Error saving ICE candidate: $e');
        }
      }
    };

    if (localStream != null) {
      for (final track in localStream!.getTracks()) {
        await peerConnection!.addTrack(track, localStream!);
      }
    }
  }

  Future<void> createCall(
    DatabaseService dbService,
    String roomId,
    String receiverId,
    bool isVideo,
    String callerName,
  ) async {
    if (peerConnection == null) {
      throw Exception('Peer connection has not been created.');
    }

    final offer = await peerConnection!.createOffer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideo,
    });

    await peerConnection!.setLocalDescription(offer);

    await dbService.createCallDocument(
      roomId,
      offer.toMap(),
      receiverId,
      isVideo,
      callerName,
    );
  }

  Future<void> joinCall(
    DatabaseService dbService,
    String roomId,
    Map<String, dynamic> offerData,
    bool isVideo,
  ) async {
    if (peerConnection == null) {
      throw Exception('Peer connection has not been created.');
    }

    final sdp = offerData['sdp'];
    final type = offerData['type'];

    if (sdp == null || type == null) {
      throw Exception('Invalid WebRTC offer.');
    }

    final remoteOffer = webrtc.RTCSessionDescription(sdp, type);

    await peerConnection!.setRemoteDescription(remoteOffer);

    _remoteDescriptionSet = true;

    await _flushPendingCandidates();

    final answer = await peerConnection!.createAnswer({
      'offerToReceiveAudio': true,
      'offerToReceiveVideo': isVideo,
    });

    await peerConnection!.setLocalDescription(answer);

    await dbService.answerCall(roomId, answer.toMap());
  }

  void listenForAnswer(DatabaseService dbService, String roomId) {
    _answerSubscription?.cancel();

    _answerSubscription = FirebaseFirestore.instance
        .collection('calls')
        .doc(roomId)
        .snapshots()
        .listen((snapshot) async {
          if (_disposed || !snapshot.exists) return;

          final data = snapshot.data();

          if (data == null) return;

          final answer = data['answer'];

          if (answer == null || _remoteDescriptionSet) {
            return;
          }

          final sdp = answer['sdp'];
          final type = answer['type'];

          if (sdp == null || type == null) {
            return;
          }

          try {
            final remoteAnswer = webrtc.RTCSessionDescription(sdp, type);

            await peerConnection!.setRemoteDescription(remoteAnswer);

            _remoteDescriptionSet = true;

            await _flushPendingCandidates();
          } catch (e) {
            print('Error setting remote answer: $e');
          }
        });
  }

  void listenForCandidates(
    DatabaseService dbService,
    String roomId,
    bool isCaller,
  ) {
    _iceSubscription?.cancel();

    _iceSubscription = dbService.getIceCandidates(roomId, !isCaller).listen((
      snapshot,
    ) async {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) {
          continue;
        }

        final data = change.doc.data();

        if (data == null) {
          continue;
        }

        try {
          final candidate = webrtc.RTCIceCandidate(
            data['candidate'] as String?,
            data['sdpMid'] as String?,
            data['sdpMLineIndex'] as int?,
          );

          if (_remoteDescriptionSet) {
            await peerConnection?.addCandidate(candidate);
          } else {
            _pendingCandidates.add(candidate);
          }
        } catch (e) {
          print('Error processing ICE candidate: $e');
        }
      }
    });
  }

  Future<void> _flushPendingCandidates() async {
    if (!_remoteDescriptionSet) return;

    if (_pendingCandidates.isEmpty) return;

    for (final candidate in List<webrtc.RTCIceCandidate>.from(
      _pendingCandidates,
    )) {
      try {
        await peerConnection?.addCandidate(candidate);
      } catch (e) {
        print('Error adding queued ICE candidate: $e');
      }
    }

    _pendingCandidates.clear();
  }

  Future<webrtc.MediaStream> openUserMedia(bool video) async {
    final constraints = <String, dynamic>{
      'audio': true,
      'video': video ? {'facingMode': 'user'} : false,
    };

    localStream = await webrtc.navigator.mediaDevices.getUserMedia(constraints);

    for (final track in localStream!.getAudioTracks()) {
      track.enabled = true;
    }

    for (final track in localStream!.getVideoTracks()) {
      track.enabled = true;
    }

    return localStream!;
  }

  void toggleMute(bool isMuted) {
    final audioTracks = localStream?.getAudioTracks();

    if (audioTracks == null) return;

    for (final track in audioTracks) {
      track.enabled = !isMuted;
    }
  }

  Future<void> switchCamera() async {
    final videoTracks = localStream?.getVideoTracks();

    if (videoTracks == null || videoTracks.isEmpty) {
      return;
    }

    await webrtc.Helper.switchCamera(videoTracks.first);
  }

  Future<void> dispose() async {
    _disposed = true;

    await _iceSubscription?.cancel();
    await _answerSubscription?.cancel();

    _iceSubscription = null;
    _answerSubscription = null;

    _pendingCandidates.clear();

    for (final track in localStream?.getTracks() ?? []) {
      await track.stop();
    }

    for (final track in remoteStream?.getTracks() ?? []) {
      await track.stop();
    }

    await peerConnection?.close();

    await localStream?.dispose();
    await remoteStream?.dispose();

    peerConnection = null;
    localStream = null;
    remoteStream = null;
  }
}
