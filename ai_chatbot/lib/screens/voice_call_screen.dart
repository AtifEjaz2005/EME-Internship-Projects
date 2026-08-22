import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as webrtc;
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/webrtc_service.dart';
import '../database/database_service.dart';
import '../themes/app_theme.dart';

class VoiceCallScreen extends StatefulWidget {
  final String roomId;
  final bool isCaller;
  final String friendName;
  final DatabaseService dbService;
  final Map<String, dynamic>? offer;

  const VoiceCallScreen({
    super.key,
    required this.roomId,
    required this.isCaller,
    required this.dbService,
    required this.friendName,
    this.offer,
  });

  @override
  State<VoiceCallScreen> createState() => _VoiceCallScreenState();
}

class _VoiceCallScreenState extends State<VoiceCallScreen> {
  final WebRTCService _webrtcService = WebRTCService();

  bool _isMuted = false;
  bool _isSpeakerOn = false;
  final bool _isInitializing = true;

  @override
  void initState() {
    super.initState();

    _listenForEnd();
    _initVoice();
  }

  Future<void> _initVoice() async {
    try {
      webrtc.Helper.setSpeakerphoneOn(false);

      // Only the caller cleans old signaling data.
      if (widget.isCaller) {
        await widget.dbService.prepareCall(widget.roomId);
      }

      await _webrtcService.openUserMedia(false);

      await _webrtcService.createPeerConnection(
        widget.dbService,
        widget.roomId,
        widget.isCaller,
      );

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
          false,
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
          false,
        );
      }
    } catch (e) {
      print('Voice call initialization error: $e');

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
          // This prevents an old "ended" call from immediately closing
          // the new call screen.
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

    // Do not immediately delete the signaling document here.
    // Let cleanup happen separately.
  }

  @override
  void dispose() {
    _webrtcService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          CircleAvatar(
            radius: 60,
            backgroundColor: AppTheme.botBubble,
            child: const Icon(Icons.person, size: 80, color: Colors.white24),
          ),

          const SizedBox(height: 30),

          Text(
            widget.friendName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          Text(
            _isInitializing ? 'Connecting...' : 'Voice Call',
            style: const TextStyle(color: AppTheme.limeGreen, letterSpacing: 2),
          ),

          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _btn(
                _isMuted ? Icons.mic_off : Icons.mic,
                _isMuted ? Colors.red : Colors.white10,
                () {
                  setState(() {
                    _isMuted = !_isMuted;
                  });

                  _webrtcService.toggleMute(_isMuted);
                },
              ),

              const SizedBox(width: 30),

              _btn(Icons.call_end, Colors.red, _endCall),

              const SizedBox(width: 30),

              _btn(
                _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                _isSpeakerOn ? AppTheme.limeGreen : Colors.white10,
                () async {
                  setState(() {
                    _isSpeakerOn = !_isSpeakerOn;
                  });

                  await webrtc.Helper.setSpeakerphoneOn(_isSpeakerOn);
                },
              ),
            ],
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 35),
      ),
    );
  }
}
