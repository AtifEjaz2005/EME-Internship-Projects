class MusicTrack {
  final String id;
  final String title;
  final String artist;
  final String artworkUrl;
  final String provider;
  final String providerTrackId;
  final Duration? duration;
  final String? audioUrl;

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'artworkUrl': artworkUrl,
      'provider': provider,
      'providerTrackId': providerTrackId,
      'duration': duration?.inSeconds ?? 0,
      'audioUrl': audioUrl,
    };
  }

  factory MusicTrack.fromMap(Map<String, dynamic> map) {
    return MusicTrack(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? 'Unknown Track',
      artist: map['artist'] ?? 'Unknown Artist',
      artworkUrl: map['artworkUrl'] ?? '',
      provider: map['provider'] ?? 'audius',
      providerTrackId: map['providerTrackId']?.toString() ?? '',
      duration: Duration(seconds: map['duration'] ?? 0),
      audioUrl: map['audioUrl'],
    );
  }
}
