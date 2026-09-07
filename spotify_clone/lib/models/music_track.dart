class MusicTrack {
  final String id;              // Unique ID for Musiki (e.g., Firestore ID or Audius ID)
  final String title;
  final String artist;
  final String artworkUrl;
  final String provider;        // 'audius' or 'firebase'
  final String providerTrackId; // The ID inside the Audius system
  final Duration? duration;
  final String? audioUrl;       // Can be null until resolved

  MusicTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.artworkUrl,
    required this.provider,
    required this.providerTrackId,
    this.duration,
    this.audioUrl,
  });
}
