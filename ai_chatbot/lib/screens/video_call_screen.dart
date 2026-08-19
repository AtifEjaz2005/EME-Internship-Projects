import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/webrtc_service.dart';
import '../database/database_service.dart';
import '../themes/app_theme.dart';

class VideoCallScreen extends StatefulWidget {
  final String roomId;
  final bool isCaller;
  final DatabaseService dbService;
  final Map<String, dynamic>? offer;

  const VideoCallScreen({
    super.key,
    required this.roomId,
    required this.isCaller,
    required this.dbService,
    this.offer,
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  final webrtc.RTCVideoRenderer _localRenderer = webrtc.RTCVideoRenderer();

  final webrtc.RTCVideoRenderer _remoteRenderer = webrtc.RTCVideoRenderer();

  final WebRTCService _webrtcService = WebRTCService();

  bool _isMuted = false;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();

    _listenForEnd();
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();

      webrtc.Helper.setSpeakerphoneOn(true);

      // Only the caller cleans old signaling data.
      if (widget.isCaller) {
        await widget.dbService.prepareCall(widget.roomId);
      }

      await _webrtcService.openUserMedia(true);

      _localRenderer.srcObject = _webrtcService.localStream;

      await _webrtcService.createPeerConnection(
        widget.dbService,
        widget.roomId,
        widget.isCaller,
      );

      _webrtcService.peerConnection!.onAddStream = (stream) {
        if (mounted) {
          setState(() {
            _remoteRenderer.srcObject = stream;
          });
        }
      };

      _webrtcService.listenForCandidates(
        widget.dbService,
        widget.roomId,
        widget.isCaller,
      );

      if (widget.isCaller) {
        String fId = widget.roomId
            .split('_')
            .firstWhere((id) => id != widget.dbService.uid);

        var roomSnap = await FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .get();

        String myName = roomSnap.data()?['name_$fId'] ?? "NEXA User";

        await _webrtcService.createCall(
          widget.dbService,
          widget.roomId,
          fId,
          true,
          myName,
        );

        _webrtcService.listenForAnswer(widget.dbService, widget.roomId);
      } else {
        var callDoc = await FirebaseFirestore.instance
            .collection('calls')
            .doc(widget.roomId)
            .get();

        if (!callDoc.exists || callDoc.data()?['offer'] == null) {
          throw Exception('Call offer not found.');
        }

        await _webrtcService.joinCall(
          widget.dbService,
          widget.roomId,
          Map<String, dynamic>.from(callDoc.data()!['offer']),
          true,
        );
      }
    } catch (e) {
      print('Video call initialization error: $e');

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _listenForEnd() {
    bool isFirstSnapshot = true;

    FirebaseFirestore.instance
        .collection('calls')
        .doc(widget.roomId)
        .snapshots()
        .listen((snap) {
          // Ignore the existing state when the screen first starts.
          if (isFirstSnapshot) {
            isFirstSnapshot = false;
            return;
          }

          if (snap.exists && snap.data()?['status'] == 'ended') {
            if (mounted) {
              Navigator.of(context).pop();
            }
          }
        });
  }

  Future<void> _endCall() async {
    try {
      await widget.dbService.updateCallStatus(widget.roomId, 'ended');
    } catch (e) {
      print('Error ending call: $e');
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _webrtcService.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: _remoteRenderer.srcObject == null
                ? const Center(
                    child: Text(
                      'Connecting video...',
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  )
                : webrtc.RTCVideoView(
                    _remoteRenderer,
                    objectFit:
                        webrtc.RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
          ),

          Positioned(
            top: 50,
            right: 20,
            child: Container(
              width: 120,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: AppTheme.limeGreen),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: _localRenderer.srcObject == null
                    ? const Center(child: CircularProgressIndicator())
                    : webrtc.RTCVideoView(
                        _localRenderer,
                        mirror: true,
                        objectFit: webrtc
                            .RTCVideoViewObjectFit
                            .RTCVideoViewObjectFitCover,
                      ),
              ),
            ),
          ),

          if (_isInitializing)
            const Positioned(
              top: 50,
              left: 20,
              child: Text(
                'Connecting...',
                style: TextStyle(color: Colors.white),
              ),
            ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _btn(
                  _isMuted ? Icons.mic_off : Icons.mic,
                  _isMuted ? Colors.red : Colors.white24,
                  () {
                    setState(() {
                      _isMuted = !_isMuted;
                    });

                    _webrtcService.toggleMute(_isMuted);
                  },
                ),

                const SizedBox(width: 20),

                _btn(Icons.call_end, Colors.red, _endCall),

                const SizedBox(width: 20),

                _btn(Icons.switch_camera, Colors.white24, () {
                  _webrtcService.switchCamera();
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 30),
      ),
    );
  }
}
