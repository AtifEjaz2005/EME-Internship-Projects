import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/song_model.dart';
import 'mock_data_service.dart';

// State definition
abstract class SongState {}
class SongLoading extends SongState {}
class SongLoaded extends SongState {
  final List<SongModel> songs;
  SongLoaded(this.songs);
}
class SongError extends SongState {
  final String message;
  SongError(this.message);
}

// Cubit definition
class SongCubit extends Cubit<SongState> {
  SongCubit() : super(SongLoading());

  void fetchSongs() async {
    try {
      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));
      final songs = MockDataService.getSongs();
      emit(SongLoaded(songs));
    } catch (e) {
      emit(SongError("Failed to fetch songs"));
    }
  }
}
