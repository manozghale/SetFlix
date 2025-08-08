//
//  MovieSearchViewModel.swift
//  SetFlix
//
//  Created by Manoj on 07/08/2025.
//

import Combine
import CoreData
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
  @Published var isOnline = true

  // MARK: - Private Properties
  private let repository: MovieRepository
  internal var currentPage = 1
  internal var currentQuery = ""
  private var searchTask: Task<Void, Never>?
  private var cancellables = Set<AnyCancellable>()

  // MARK: - Initialization
  init(repository: MovieRepository) {
    self.repository = repository
    // Initialize with current network state
    self.isOnline = repository.isNetworkAvailable()
    setupNetworkMonitoring()
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

  private func setupNetworkMonitoring() {
    repository.networkStatePublisher
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isOnline in
        self?.handleNetworkStateChange(isOnline: isOnline)
      }
      .store(in: &cancellables)
  }

  private func handleNetworkStateChange(isOnline: Bool) {
    print("📱 ViewModel detected network change: \(isOnline ? "Online" : "Offline")")

    let wasOnline = self.isOnline
    self.isOnline = isOnline

    if !wasOnline && isOnline {
      // Just came back online - try to refresh data
      print("📱 Network restored - refreshing data...")
      refreshData()
    } else if wasOnline && !isOnline {
      // Just went offline - show cached data if available
      print("📱 Network lost - switching to offline mode...")
      Task {
        await loadOfflineData()
      }
    }
    
    // Always update the UI to reflect current network state
    DispatchQueue.main.async {
      // Trigger UI updates for network status
      self.objectWillChange.send()
    }
  }

  // MARK: - Public Methods

  /// Load initial popular movies
  func loadInitialData() {
    isLoading = true
    errorMessage = nil

    Task {
      await loadInitialDataAsync()
    }
  }

  @MainActor
  private func loadInitialDataAsync() async {
    // Check current network state directly from repository
    let currentNetworkState = repository.isNetworkAvailable()
    print("📱 Initial data loading - Network state: \(currentNetworkState ? "Online" : "Offline")")
    
    // Update the isOnline state to match current network state
    self.isOnline = currentNetworkState
    
    if !currentNetworkState {
      // When offline, check if we have a last search query and restore the search state
      if let lastQuery = CoreDataManager.shared.getLastSearchQuery() {
        currentQuery = lastQuery
        isSearching = true
        print("📱 Offline mode: Restoring last search query '\(lastQuery)'")
      }
      await loadOfflineData()
    } else {
      await loadPopularMovies()
    }
    isLoading = false
  }

  /// Search for movies
  func searchMovies(query: String) {
    guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      clearSearchState()
      return
    }

    currentQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
    isSearching = true
    currentPage = 1
    hasMorePages = true
    isLoading = true
    errorMessage = nil

    // Check if we're offline and have cached results
    if !repository.isNetworkAvailable() {
      print("📱 Offline search for '\(currentQuery)' - checking cache")
      Task {
        await performOfflineSearch()
      }
    } else {
      Task {
        await performSearch()
      }
    }
  }

  /// Load more movies for pagination
  func loadMoreMovies() {
    guard !isLoading && hasMorePages && !isSearching else { return }

    isLoading = true
    currentPage += 1

    Task {
      await loadPopularMovies()
    }
  }

  /// Refresh current data
  func refreshData() {
    if isSearching {
      searchMovies(query: currentQuery)
    } else {
      loadInitialData()
    }
  }

  /// Clear search state and return to popular movies
  func clearSearchState() {
    // Reset search state
    currentQuery = ""
    isSearching = false
    isShowingCachedSearchResults = false
    
    // Clear filtered movies on main thread
    DispatchQueue.main.async {
      self.filteredMovies = []
    }
    
    // Don't clear all search results from Core Data - keep them for offline access
    // Only clear the current search state, not the cached data
    print("📱 Clearing search state but preserving cached search results for offline access")
    
    // Load initial data
    loadInitialData()
  }

  /// Clear error message
  func clearError() {
    errorMessage = nil
  }

  /// Refresh favorite status for all currently displayed movies
  func refreshFavoriteStatus() {
    Task {
      await refreshFavoriteStatusAsync()
    }
  }

  // MARK: - Private Methods

  @MainActor
  private func loadPopularMovies() async {
    do {
      let response = try await repository.getPopularMovies(page: currentPage)
      let newMovies = response.results
      
      // Preserve favorite status for fresh data from API
      let updatedMovies = await preserveFavoriteStatus(for: newMovies)
      
      if currentPage == 1 {
        movies = updatedMovies
      } else {
        movies.append(contentsOf: updatedMovies)
      }
      
      hasMorePages = newMovies.count == 20  // Assuming 20 movies per page
      filteredMovies = movies
      isShowingCachedSearchResults = false
      
      // Save popular movies to Core Data for offline access
      await savePopularMoviesToCache(updatedMovies)
      
    } catch {
      errorMessage = "Failed to load movies: \(error.localizedDescription)"
      print("❌ Error loading popular movies: \(error)")
    }
    
    isLoading = false
  }

  @MainActor
  private func performSearch() async {
    print("🔍 Performing online search for query: '\(currentQuery)' page: \(currentPage)")
    
    do {
      let response = try await repository.searchMovies(query: currentQuery, page: currentPage)
      let searchResults = response.results
      
      print("🔍 Received \(searchResults.count) search results from API for '\(currentQuery)'")
      
      // Preserve favorite status for fresh search results from API
      let updatedSearchResults = await preserveFavoriteStatus(for: searchResults)
      
      if currentPage == 1 {
        filteredMovies = updatedSearchResults
      } else {
        filteredMovies.append(contentsOf: updatedSearchResults)
      }
      
      hasMorePages = searchResults.count == 20  // Assuming 20 movies per page
      isShowingCachedSearchResults = false
      
      // Save search results to Core Data for offline access
      await saveSearchResultsToCache(updatedSearchResults)
      
      print("🔍 Online search completed - showing \(filteredMovies.count) movies")
      
    } catch {
      errorMessage = "Failed to search movies: \(error.localizedDescription)"
      print("❌ Error searching movies: \(error)")
    }
    
    isLoading = false
  }

  @MainActor
  private func performOfflineSearch() async {
    print("📱 Performing offline search for query: '\(currentQuery)'")
    
    // Try to get cached search results for the current query
    if let cachedSearchResults = CoreDataManager.shared.getSearchResults(for: currentQuery) {
      print("📱 Found cached search results for '\(currentQuery)' in offline mode - \(cachedSearchResults.count) movies")
      filteredMovies = cachedSearchResults
      isShowingCachedSearchResults = true
      hasMorePages = false // No pagination in offline mode
    } else {
      print("📱 No cached search results found for '\(currentQuery)' in offline mode")
      
      // Try to load most recent search results as fallback
      if let recentResults = CoreDataManager.shared.getMostRecentSearchResults() {
        print("📱 Loading most recent search results as fallback: '\(recentResults.query)' with \(recentResults.movies.count) movies")
        currentQuery = recentResults.query
        filteredMovies = recentResults.movies
        isShowingCachedSearchResults = true
        hasMorePages = false
      } else {
        print("📱 No fallback search results available in offline mode")
        filteredMovies = []
        isShowingCachedSearchResults = false
        hasMorePages = false
        errorMessage = "No cached results found for '\(currentQuery)'. Please try again when online."
      }
    }
    
    print("📱 Offline search completed - showing \(filteredMovies.count) movies")
    isLoading = false
  }

  @MainActor
  private func loadOfflineData() async {
    if isSearching && !currentQuery.isEmpty {
      // Load cached search results from Core Data
      if let cachedSearchResults = CoreDataManager.shared.getSearchResults(for: currentQuery) {
        print("📱 Loading cached search results for '\(currentQuery)' from Core Data")
        filteredMovies = cachedSearchResults
        isShowingCachedSearchResults = true
        // Don't run preserveFavoriteStatus on Core Data as it already has correct favorite status
      } else {
        print("📱 No cached search results found for '\(currentQuery)' in Core Data")
        
        // Try to load most recent search results as fallback
        if let recentResults = CoreDataManager.shared.getMostRecentSearchResults() {
          print("📱 Loading most recent search results as fallback: '\(recentResults.query)'")
          currentQuery = recentResults.query
          filteredMovies = recentResults.movies
          isShowingCachedSearchResults = true
        } else {
          print("📱 No fallback search results available")
          filteredMovies = []
          isShowingCachedSearchResults = false
        }
      }
    } else {
      // Load cached popular movies from Core Data
      let cachedMovies = CoreDataManager.shared.getAllMovies()
      if !cachedMovies.isEmpty {
        print("📱 Loading \(cachedMovies.count) cached popular movies from Core Data")
        let movies = cachedMovies.compactMap { $0.toMovie() }
        let updatedMovies = await preserveFavoriteStatus(for: movies)
        filteredMovies = updatedMovies
        isShowingCachedSearchResults = true
      } else {
        print("📱 No cached popular movies found in Core Data")
        filteredMovies = []
        isShowingCachedSearchResults = false
      }
    }
  }

  private func savePopularMoviesToCache(_ movies: [Movie]) async {
    // Save popular movies to Core Data for offline access
    // Use saveOrUpdateMovie to preserve existing favorite status
    for movie in movies {
      CoreDataManager.shared.saveMovie(movie, isFavorite: movie.isFavorite)
    }
    print("💾 Saved \(movies.count) popular movies to Core Data")
  }

  private func saveSearchResultsToCache(_ movies: [Movie]) async {
    // Save search results to Core Data for offline access
    print("💾 Saving \(movies.count) search results for '\(currentQuery)' to Core Data")
    CoreDataManager.shared.saveSearchResults(query: currentQuery, movies: movies)
    print("💾 Successfully saved search results for '\(currentQuery)' to Core Data")
  }

  private func preserveFavoriteStatus(for movies: [Movie]) async -> [Movie] {
    let movieIds = movies.map { $0.id }
    let favoriteStatus = CoreDataManager.shared.getFavoriteStatus(for: movieIds)
    
    // Create new movies array with updated favorite status
    var updatedMovies = movies
    for i in 0..<updatedMovies.count {
      updatedMovies[i].isFavorite = favoriteStatus[updatedMovies[i].id] ?? false
    }
    
    print("💖 Preserved favorite status for \(movies.count) movies")
    return updatedMovies
  }

  private func refreshFavoriteStatusAsync() async {
    // Refresh favorite status for currently displayed movies
    if !filteredMovies.isEmpty {
      let updatedMovies = await preserveFavoriteStatus(for: filteredMovies)
      filteredMovies = updatedMovies
      print("🔄 Refreshed favorite status for \(updatedMovies.count) movies")
    }
  }
}
