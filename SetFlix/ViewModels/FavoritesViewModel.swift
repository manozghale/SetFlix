//
//  FavoritesViewModel.swift
//  SetFlix
//
//  Created by Manoj on 08/08/2025.
//

import Combine
import Foundation

@MainActor
class FavoritesViewModel: ObservableObject {

  // MARK: - Published Properties
  @Published var movies: [Movie] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  // MARK: - Private Properties
  private let repository: MovieRepository
  private var cancellables = Set<AnyCancellable>()

  // MARK: - Initialization
  init(repository: MovieRepository = MovieRepositoryFactory.createRepository()) {
    self.repository = repository
  }

  // MARK: - Public Methods

  /// Load favorite movies
  func loadFavorites() {
    Task {
      await fetchFavorites()
    }
  }

  /// Remove movie from favorites
  func removeFromFavorites(_ movie: Movie) {
    Task {
      do {
        try await repository.removeFromFavorites(movie.id)
        await fetchFavorites()  // Reload the list
      } catch {
        errorMessage = "Failed to remove from favorites: \(error.localizedDescription)"
      }
    }
  }

  /// Clear error message
  func clearError() {
    errorMessage = nil
  }

  // MARK: - Private Methods

  private func fetchFavorites() async {
    do {
      isLoading = true
      errorMessage = nil

      let favorites = try await repository.getFavorites()
      movies = favorites
      isLoading = false

    } catch {
      isLoading = false
      errorMessage = "Failed to load favorites: \(error.localizedDescription)"
    }
  }
}
