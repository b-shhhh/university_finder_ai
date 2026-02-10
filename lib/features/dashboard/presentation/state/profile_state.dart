class ProfileState {
  final bool isLoading;
  final String? localImagePath;
  final String? imageUrl;
  final String? errorMessage;

  ProfileState({
    this.isLoading = false,
    this.localImagePath,
    this.imageUrl,
    this.errorMessage,
  });

  ProfileState copyWith({
    bool? isLoading,
    String? localImagePath,
    String? imageUrl,
    String? errorMessage,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      localImagePath: localImagePath ?? this.localImagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      errorMessage: errorMessage,
    );
  }
}
