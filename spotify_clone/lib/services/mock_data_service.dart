import '../models/song_model.dart';
import '../models/artist_model.dart';

class MockDataService {
  static List<SongModel> getSongs() {
    return [
      SongModel(
        id: '1',
        title: 'Midnight City',
        artist: 'M83',
        album: 'Hurry Up, We\'re Dreaming',
        artworkUrl: 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=500',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        duration: '4:03',
      ),
      SongModel(
        id: '2',
        title: 'Neon Horizon',
        artist: 'Synthwave Syndicate',
        album: 'Analog Dreams',
        artworkUrl: 'https://images.unsplash.com/photo-1619983081563-430f63602796?w=500',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        duration: '3:42',
      ),
      SongModel(
        id: '3',
        title: 'Digital Dreams',
        artist: 'Neon Voyager',
        album: 'Midnight Signals',
        artworkUrl: 'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?w=500',
        audioUrl: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        duration: '4:15',
      ),
    ];
  }

  static List<ArtistModel> getArtists() {
    return [
      ArtistModel(
        id: 'a1',
        name: 'Neon Voyager',
        imageUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=500',
        monthlyListeners: '2.4M',
        bio: 'Sonic architect from the future.',
      ),
    ];
  }
}
