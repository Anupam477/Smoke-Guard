import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/profile_repository.dart';
import '../auth/auth_controller.dart';

class ProfileState {
  final bool isLoading;
  final UserProfile? profile;
  final String? errorMessage;

  const ProfileState({
    this.isLoading = false,
    this.profile,
    this.errorMessage,
  });

  ProfileState copyWith({
    bool? isLoading,
    UserProfile? profile,
    String? errorMessage,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      profile: profile ?? this.profile,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ProfileController extends StateNotifier<ProfileState> {
  final IProfileRepository _repository;
  final String? _userId;
  final String? _userEmail;

  ProfileController(this._repository, this._userId, this._userEmail)
      : super(const ProfileState()) {
    if (_userId != null) {
      loadProfile();
    }
  }

  Future<void> loadProfile() async {
    if (_userId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final profile = await _repository.getProfile(_userId!);
      state = state.copyWith(
        isLoading: false,
        profile: profile ??
            UserProfile.defaultProfile(
              id: _userId!,
              email: _userEmail ?? 'user@smokeguard.app',
            ),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> updateProfile({
    String? displayName,
    String? phone,
    String? ageGroup,
    SensitivityLevel? sensitivityLevel,
    List<String>? healthPreferences,
    String? preferredLanguage,
  }) async {
    if (state.profile == null && _userId == null) return false;

    final current = state.profile ??
        UserProfile.defaultProfile(
          id: _userId!,
          email: _userEmail ?? 'user@smokeguard.app',
        );

    final updated = current.copyWith(
      displayName: displayName,
      phone: phone,
      ageGroup: ageGroup,
      sensitivityLevel: sensitivityLevel,
      healthPreferences: healthPreferences,
      preferredLanguage: preferredLanguage,
      updatedAt: DateTime.now(),
    );

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await _repository.saveProfile(updated);
      state = state.copyWith(isLoading: false, profile: updated);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  return ProfileController(repo, user?.id, user?.email);
});
