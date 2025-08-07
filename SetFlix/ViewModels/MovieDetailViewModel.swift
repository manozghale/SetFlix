//
//  MovieDetailViewModel.swift
//  SetFlix
//
//  Created by Manoj on 07/08/2025.
//

import Combine
import Foundation

@MainActor
class MovieDetailViewModel: ObservableObject {

  // MARK: - Published Properties
  @Published var movieDetail: MovieDetail?
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var isFavorite = false

  // MARK: - Private Properties
  private let movie: Movie
  private let repository: MovieRepository
  private var cancellables = Set<AnyCancellable>()

  // MARK: - Computed Properties
  var title: String {
    return movieDetail?.title ?? movie.title
  }

  var overview: String {
    return movieDetail?.overview ?? "Overview not available"
  }

  var releaseYear: String {
    guard let releaseDate = movieDetail?.releaseDate ?? movie.releaseDate else {
      return "Year not available"
    }
    return extractYear(from: releaseDate)
  }

  var posterURL: String? {
    return movieDetail?.posterURL ?? movie.posterURL
  }

  // MARK: - Initialization
  init(movie: Movie, repository: MovieRepository = MovieRepositoryFactory.createRepository()) {
    self.movie = movie
    self.repository = repository
  }

  // MARK: - Public Methods

  /// Load movie details from API
  func loadMovieDetails() {
    Task {
      await fetchMovieDetails()
    }
  }

  /// Toggle favorite status
  func toggleFavorite() {
    // This would be implemented when Core Data is re-enabled
    // For now, just toggle the local state
    isFavorite.toggle()
  }

  /// Clear error message
  func clearError() {
    errorMessage = nil
  }

  // MARK: - Private Methods

  private func fetchMovieDetails() async {
    do {
      isLoading = true
      errorMessage = nil

      let detail = try await repository.getMovieDetails(id: movie.id)
      movieDetail = detail
      isLoading = false

    } catch {
      isLoading = false

      if error is NetworkError {
        errorMessage = "Failed to load movie details: \(error.localizedDescription)"
      } else {
        errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
      }
    }
  }

  private func extractYear(from dateString: String) -> String {
    guard !dateString.isEmpty else {
      return "Year not available"
    }

    // Handle different date formats from TMDB API
    let dateFormatter = DateFormatter()

    // Try full date format first (YYYY-MM-DD)
    dateFormatter.dateFormat = "yyyy-MM-dd"
    if let date = dateFormatter.date(from: dateString) {
      let yearFormatter = DateFormatter()
      yearFormatter.dateFormat = "yyyy"
      return yearFormatter.string(from: date)
    }

    // Try year-only format (YYYY)
    dateFormatter.dateFormat = "yyyy"
    if let date = dateFormatter.date(from: dateString) {
      let yearFormatter = DateFormatter()
      yearFormatter.dateFormat = "yyyy"
      return yearFormatter.string(from: date)
    }

    // Fallback: try to extract year from string using regex
    let yearPattern = #"(\d{4})"#
    if let regex = try? NSRegularExpression(pattern: yearPattern),
      let match = regex.firstMatch(
        in: dateString, range: NSRange(dateString.startIndex..., in: dateString))
    {
      let yearRange = Range(match.range(at: 1), in: dateString)!
      return String(dateString[yearRange])
    }

    // If all else fails, return the original string
    return dateString
  }
}
