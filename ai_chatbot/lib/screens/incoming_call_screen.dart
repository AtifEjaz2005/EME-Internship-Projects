import 'package:flutter/material.dart';

import '../database/database_service.dart';
import '../themes/app_theme.dart';
import 'video_call_screen.dart';
import 'voice_call_screen.dart';

class IncomingCallScreen extends StatelessWidget {
  final String callerName;
  final String roomId;
  final Map<String, dynamic> offer;
  final DatabaseService dbService;
  final bool isVideo;

  const IncomingCallScreen({
    super.key,
    required this.callerName,
    required this.roomId,
    required this.offer,
    required this.dbService,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          CircleAvatar(
            radius: 50,
            backgroundColor: AppTheme.limeGreen.withValues(alpha: 0.1),
            child: const Icon(
              Icons.person,
              size: 60,
              color: AppTheme.limeGreen,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            callerName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          Text(
            isVideo ? 'Incoming Video Call...' : 'Incoming Voice Call...',
            style: const TextStyle(color: Colors.white54),
          ),

          const Spacer(),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildCallBtn(Icons.call_end, Colors.redAccent, () async {
                try {
                  await dbService.updateCallStatus(roomId, 'ended');
                } catch (e) {
                  print('Error declining call: $e');
                }

                if (context.mounted) {
                  Navigator.pop(context);
                }
              }),

              _buildCallBtn(
                isVideo ? Icons.videocam : Icons.call,
                AppTheme.limeGreen,
                () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (c) {
                        if (isVideo) {
                          return VideoCallScreen(
                            roomId: roomId,
                            isCaller: false,
                            dbService: dbService,
                            offer: offer,
                          );
                        }

                        return VoiceCallScreen(
                          roomId: roomId,
                          isCaller: false,
                          friendName: callerName,
                          dbService: dbService,
                          offer: offer,
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildCallBtn(IconData icon, Color color, VoidCallback onTap) {
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
