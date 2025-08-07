//
//  MovieSearchViewModel.swift
//  SetFlix
//
//  Created by Manoj on 07/08/2025.
//

import Combine
import Foundation

@MainActor
class MovieSearchViewModel: ObservableObject {

  // MARK: - Published Properties
  @Published var movies: [Movie] = []
  @Published var filteredMovies: [Movie] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var hasMorePages = true
  @Published var isSearching = false
  @Published var isEmptyState = false

  // MARK: - Private Properties
  private let repository: MovieRepository
  private var currentPage = 1
  private var currentQuery = ""
  private var searchTask: Task<Void, Never>?
  private var cancellables = Set<AnyCancellable>()

  // MARK: - Initialization
  init(repository: MovieRepository = MovieRepositoryFactory.createRepository()) {
    self.repository = repository
    setupBindings()
  }

  // MARK: - Setup
  private func setupBindings() {
    // Update empty state when filtered movies change
    $filteredMovies
      .map { $0.isEmpty }
      .assign(to: \.isEmptyState, on: self)
      .store(in: &cancellables)
  }

  // MARK: - Public Methods

  /// Load initial popular movies
  func loadInitialData() {
    Task {
      // Always try to load from API first when online
      if repository.isNetworkAvailable() {
        await loadPopularMovies()
      } else {
        // Only load from cache when offline
        await loadCachedData()
      }
    }
  }

  private func loadCachedData() async {
    let cachedResponse = repository.getCachedPopularMovies()
    if !cachedResponse.results.isEmpty {
      movies = cachedResponse.results
      filteredMovies = cachedResponse.results
      print("📱 Loaded \(cachedResponse.results.count) movies from cache (offline mode)")
    }
  }

  /// Search movies with query
  func searchMovies(query: String) {
    // Cancel previous search task
    searchTask?.cancel()

    currentQuery = query
    isSearching = !query.isEmpty

    guard !query.isEmpty else {
      // If query is empty, show popular movies
      filteredMovies = movies
      return
    }

    // Create new search task
    searchTask = Task {
      await performSearch(query: query, page: 1)
    }
  }

  /// Load more results for pagination
  func loadMoreResults() {
    guard !isLoading && hasMorePages else { return }

    Task {
      if currentQuery.isEmpty {
        await loadPopularMovies(page: currentPage + 1)
      } else {
        await performSearch(query: currentQuery, page: currentPage + 1)
      }
    }
  }

  /// Refresh current data
  func refreshData() {
    Task {
      if currentQuery.isEmpty {
        await loadPopularMovies()
      } else {
        await performSearch(query: currentQuery, page: 1)
      }
    }
  }

  /// Clear error message
  func clearError() {
    errorMessage = nil
  }

  /// Check if network is available
  func isNetworkAvailable() -> Bool {
    return repository.isNetworkAvailable()
  }

  // MARK: - Private Methods

  private func loadPopularMovies(page: Int = 1) async {
    do {
      isLoading = true
      errorMessage = nil  // Clear any previous errors

      let response = try await repository.getPopularMovies(page: page)

      // Only update if the task hasn't been cancelled
      if !Task.isCancelled {
        if page == 1 {
          // First page - replace all movies
          movies = response.results
          filteredMovies = response.results
        } else {
          // Subsequent pages - append to existing movies
          movies.append(contentsOf: response.results)
          filteredMovies.append(contentsOf: response.results)
        }

        currentPage = response.page
        hasMorePages = (response.totalPages ?? 1) > response.page
        isLoading = false
        errorMessage = nil  // Ensure error is cleared on success
      }
    } catch {
      // Only set error if the task hasn't been cancelled
      if !Task.isCancelled {
        isLoading = false
        errorMessage = "Failed to load popular movies: \(error.localizedDescription)"
      }
    }
  }

  private func performSearch(query: String, page: Int) async {
    do {
      isLoading = true
      errorMessage = nil

      let response = try await repository.searchMovies(query: query, page: page)

      // Check if task was cancelled
      if Task.isCancelled { return }

      if page == 1 {
        // First page - replace filtered movies
        filteredMovies = response.results
      } else {
        // Subsequent pages - append to existing filtered movies
        filteredMovies.append(contentsOf: response.results)
      }

      currentPage = response.page
      hasMorePages = (response.totalPages ?? 1) > response.page
      isLoading = false
      errorMessage = nil

    } catch {
      // Only set error if the task hasn't been cancelled
      if !Task.isCancelled {
        isLoading = false

        // Show error message for network issues
        if error is NetworkError {
          errorMessage = "Search failed: \(error.localizedDescription)"
        } else {
          errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
      }
    }
  }
}
