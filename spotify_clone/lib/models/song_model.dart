class SongModel {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String artworkUrl;
  final String audioUrl;
  final String duration; // e.g., "3:42"
  final bool isLiked;

  SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.artworkUrl,
    required this.audioUrl,
    required this.duration,
    this.isLiked = false,
  });

  // Convert Firestore Document to SongModel
  factory SongModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SongModel(
      id: documentId,
      title: map['title'] ?? '',
      artist: map['artist'] ?? '',
      album: map['album'] ?? '',
      artworkUrl: map['artworkUrl'] ?? '',
      audioUrl: map['audioUrl'] ?? '',
      duration: map['duration'] ?? '',
      isLiked: map['isLiked'] ?? false,
    );
  }
}
