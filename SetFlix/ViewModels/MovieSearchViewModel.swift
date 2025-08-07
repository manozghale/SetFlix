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
  @Published var isShowingCachedSearchResults = false

  // MARK: - Private Properties
  private let repository: MovieRepository
  private var currentPage = 1
  private var currentQuery = ""
  private var searchTask: Task<Void, Never>?
  private var cancellables = Set<AnyCancellable>()

  // MARK: - UserDefaults Keys
  private let lastSearchQueryKey = "LastSearchQuery"
  private let lastSearchResultsKey = "LastSearchResults"

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
      // Always try to load cached data first (offline-first approach)
      await loadOfflineData()

      // If online, try to refresh with fresh data in the background
      if repository.isNetworkAvailable() {
        await loadFreshDataInBackground()
      }
    }
  }

  /// Load fresh data in background without showing errors
  private func loadFreshDataInBackground() async {
    do {
      if currentQuery.isEmpty {
        let response = try await repository.getPopularMovies(page: 1)
        if !Task.isCancelled {
          movies = response.results
          filteredMovies = response.results
          currentPage = response.page
          hasMorePages = (response.totalPages ?? 1) > response.page
          isShowingCachedSearchResults = false
        }
      } else {
        let response = try await repository.searchMovies(query: currentQuery, page: 1)
        if !Task.isCancelled {
          filteredMovies = response.results
          saveLastSearchResults(response.results)
          currentPage = response.page
          hasMorePages = (response.totalPages ?? 1) > response.page
          isShowingCachedSearchResults = false
        }
      }
    } catch {
      // Silently fail - don't show error popup for background refresh
      print("🔄 Background refresh failed: \(error.localizedDescription)")
    }
  }

  private func loadOfflineData() async {
    print("📱 Starting offline data loading...")

    // First, try to load the last search results from UserDefaults
    if let lastQuery = getLastSearchQuery(), !lastQuery.isEmpty {
      print("📱 Found last search query: '\(lastQuery)'")
      let cachedSearchResults = getLastSearchResults()
      print("📱 Cached search results count: \(cachedSearchResults.count)")

      if !cachedSearchResults.isEmpty {
        movies = cachedSearchResults
        filteredMovies = cachedSearchResults
        currentQuery = lastQuery
        isSearching = true
        isShowingCachedSearchResults = true
        print(
          "📱 Loaded \(cachedSearchResults.count) search results for '\(lastQuery)' from UserDefaults (offline mode)"
        )
        return
      } else {
        print("📱 No cached search results found for '\(lastQuery)' in UserDefaults")
      }
    } else {
      print("📱 No last search query found")
    }

    // If no search results available, fall back to popular movies from Core Data
    print("📱 Falling back to popular movies from Core Data...")
    let cachedResponse = repository.getCachedPopularMovies()
    print("📱 Cached popular movies count: \(cachedResponse.results.count)")

    if !cachedResponse.results.isEmpty {
      movies = cachedResponse.results
      filteredMovies = cachedResponse.results
      currentQuery = ""
      isSearching = false
      isShowingCachedSearchResults = false
      print("📱 Loaded \(cachedResponse.results.count) popular movies from cache (offline mode)")
    } else {
      print("📱 No cached popular movies found")
    }
  }

  /// Search movies with query
  func searchMovies(query: String) {
    // Cancel previous search task
    searchTask?.cancel()

    currentQuery = query
    isSearching = !query.isEmpty

    // Save the search query for offline access
    if !query.isEmpty {
      saveLastSearchQuery(query)
    }

    guard !query.isEmpty else {
      // If query is empty, show popular movies
      filteredMovies = movies
      return
    }

    // Check if we're offline first
    if !repository.isNetworkAvailable() {
      // Offline mode - try to load cached search results
      let cachedResults = getLastSearchResults()
      if !cachedResults.isEmpty {
        filteredMovies = cachedResults
        isShowingCachedSearchResults = true
        print("📱 Showing cached search results for '\(query)' (offline mode)")
      } else {
        // No cached results available
        filteredMovies = []
        isShowingCachedSearchResults = false
        print("📱 No cached search results available for '\(query)' (offline mode)")
      }
      return
    }

    // Online mode - create new search task
    searchTask = Task {
      await performSearch(query: query, page: 1)
    }
  }

  /// Load more results for pagination
  func loadMoreResults() {
    guard !isLoading && hasMorePages else { return }

    // Check if we're offline
    if !repository.isNetworkAvailable() {
      print("📱 Cannot load more results - offline mode")
      return
    }

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
      // Check if we're offline first
      if !repository.isNetworkAvailable() {
        // Offline mode - load cached data directly
        await loadOfflineData()
        return
      }

      // Online mode - try to get fresh data
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
      isShowingCachedSearchResults = false  // Reset cache indicator

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
      isShowingCachedSearchResults = false  // Reset cache indicator

      let response = try await repository.searchMovies(query: query, page: page)

      // Check if task was cancelled
      if Task.isCancelled { return }

      if page == 1 {
        // First page - replace filtered movies
        filteredMovies = response.results
        // Save search results to UserDefaults for offline access
        saveLastSearchResults(response.results)
      } else {
        // Subsequent pages - append to existing filtered movies
        filteredMovies.append(contentsOf: response.results)
        // Update UserDefaults with all current results
        saveLastSearchResults(filteredMovies)
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

  // MARK: - UserDefaults Methods

  private func saveLastSearchQuery(_ query: String) {
    UserDefaults.standard.set(query, forKey: lastSearchQueryKey)
  }

  private func getLastSearchQuery() -> String? {
    return UserDefaults.standard.string(forKey: lastSearchQueryKey)
  }

  private func saveLastSearchResults(_ movies: [Movie]) {
    do {
      let data = try JSONEncoder().encode(movies)
      UserDefaults.standard.set(data, forKey: lastSearchResultsKey)
      print("💾 Saved \(movies.count) search results to UserDefaults")
    } catch {
      print("❌ Failed to save search results to UserDefaults: \(error)")
    }
  }

  private func getLastSearchResults() -> [Movie] {
    guard let data = UserDefaults.standard.data(forKey: lastSearchResultsKey) else {
      print("📱 No cached search results found in UserDefaults")
      return []
    }

    do {
      let movies = try JSONDecoder().decode([Movie].self, from: data)
      print("📱 Retrieved \(movies.count) search results from UserDefaults")
      return movies
    } catch {
      print("❌ Failed to decode search results from UserDefaults: \(error)")
      return []
    }
  }
}
