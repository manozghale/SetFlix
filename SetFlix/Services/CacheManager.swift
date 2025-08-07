//
//  CacheManager.swift
//  SetFlix
//
//  Created by Manoj on 07/08/2025.
//

import CoreData
import Foundation

class CacheManager {
  static let shared = CacheManager()
  private let coreDataManager = CoreDataManager.shared

  private init() {}

  // MARK: - Cache Configuration
  private let searchCacheExpiryDays = 7
  private let popularMoviesCacheExpiryDays = 1
  private let movieDetailsCacheExpiryDays = 30

  // MARK: - Search Results Caching

  func saveSearchResults(_ response: MovieSearchResponse, for query: String) {
    let backgroundContext = coreDataManager.getBackgroundContext()

    backgroundContext.performAndWait {
      // Create or update page entity
      let pageEntity = self.getOrCreatePageEntity(
        for: query, page: response.page, in: backgroundContext)

      // Clear existing movies for this page
      if let existingMovies = pageEntity.movies?.allObjects as? [MovieEntity] {
        existingMovies.forEach { backgroundContext.delete($0) }
      }

      // Save new movies
      for movie in response.results {
        let movieEntity = self.createMovieEntity(from: movie, in: backgroundContext)
        pageEntity.addToMovies(movieEntity)
      }

      // Save context
      coreDataManager.saveBackgroundContext(backgroundContext)
    }
  }

  func getCachedSearchResults(for query: String, page: Int) -> MovieSearchResponse? {
    let context = coreDataManager.context

    let request: NSFetchRequest<PageEntity> = PageEntity.fetchRequest()
    request.predicate = NSPredicate(format: "query == %@ AND pageNumber == %d", query, page)
    request.fetchLimit = 1

    do {
      guard let pageEntity = try context.fetch(request).first,
        let movies = pageEntity.movies?.allObjects as? [MovieEntity],
        !movies.isEmpty
      else {
        return nil
      }

      // Check if cache is still valid
      if let timestamp = pageEntity.timestamp,
        Date().timeIntervalSince(timestamp) > TimeInterval(searchCacheExpiryDays * 24 * 60 * 60)
      {
        return nil  // Cache expired
      }

      let movieModels = movies.compactMap { $0.toMovie() }
      return MovieSearchResponse(
        page: Int(pageEntity.pageNumber),
        results: movieModels,
        totalPages: 1,  // We don't cache total pages
        totalResults: movieModels.count
      )
    } catch {
      print("Error fetching cached search results: \(error)")
      return nil
    }
  }

  // MARK: - Popular Movies Caching

  func savePopularMovies(_ response: MovieSearchResponse) {
    saveSearchResults(response, for: "popular_movies")
  }

  func getCachedPopularMovies() -> MovieSearchResponse? {
    return getCachedSearchResults(for: "popular_movies", page: 1)
  }

  // MARK: - Movie Details Caching

  func saveMovieDetails(_ movieDetail: MovieDetail) {
    let backgroundContext = coreDataManager.getBackgroundContext()

    backgroundContext.performAndWait {
      let movieEntity = self.getOrCreateMovieEntity(id: movieDetail.id, in: backgroundContext)

      // Update with detailed information
      movieEntity.title = movieDetail.title
      movieEntity.overview = movieDetail.overview
      movieEntity.posterURL = movieDetail.posterURL

      if let releaseDateString = movieDetail.releaseDate {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        movieEntity.releaseDate = dateFormatter.date(from: releaseDateString)
      }

      coreDataManager.saveBackgroundContext(backgroundContext)
    }
  }

  func getCachedMovieDetails(id: Int) -> MovieDetail? {
    let context = coreDataManager.context

    let request: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
    request.predicate = NSPredicate(format: "id == %d", id)
    request.fetchLimit = 1

    do {
      guard let movieEntity = try context.fetch(request).first,
        let overview = movieEntity.overview
      else {
        return nil
      }

      // Convert Date to String format for releaseDate
      let releaseDateString: String?
      if let releaseDate = movieEntity.releaseDate {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        releaseDateString = dateFormatter.string(from: releaseDate)
      } else {
        releaseDateString = nil
      }

      return MovieDetail(
        id: Int(movieEntity.id),
        title: movieEntity.title ?? "",
        releaseDate: releaseDateString,
        overview: overview,
        posterPath: movieEntity.posterURL
      )
    } catch {
      print("Error fetching cached movie details: \(error)")
      return nil
    }
  }

  // MARK: - Cache Management

  func clearOldCache(olderThan days: Int) {
    let backgroundContext = coreDataManager.getBackgroundContext()
    let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()

    backgroundContext.performAndWait {
      // Clear old page entities
      let pageRequest: NSFetchRequest<PageEntity> = PageEntity.fetchRequest()
      pageRequest.predicate = NSPredicate(format: "timestamp < %@", cutoffDate as NSDate)

      do {
        let oldPages = try backgroundContext.fetch(pageRequest)
        oldPages.forEach { backgroundContext.delete($0) }

        // Clear orphaned movies (not associated with any page)
        let movieRequest: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
        movieRequest.predicate = NSPredicate(format: "pages.@count == 0")

        let orphanedMovies = try backgroundContext.fetch(movieRequest)
        orphanedMovies.forEach { backgroundContext.delete($0) }

        coreDataManager.saveBackgroundContext(backgroundContext)
        print("Cleared cache older than \(days) days")
      } catch {
        print("Error clearing old cache: \(error)")
      }
    }
  }

  // MARK: - Helper Methods

  private func getOrCreatePageEntity(
    for query: String, page: Int, in context: NSManagedObjectContext
  ) -> PageEntity {
    let request: NSFetchRequest<PageEntity> = PageEntity.fetchRequest()
    request.predicate = NSPredicate(format: "query == %@ AND pageNumber == %d", query, page)
    request.fetchLimit = 1

    do {
      if let existing = try context.fetch(request).first {
        existing.timestamp = Date()
        return existing
      }
    } catch {
      print("Error checking existing page entity: \(error)")
    }

    let pageEntity = PageEntity(context: context)
    pageEntity.query = query
    pageEntity.pageNumber = Int32(page)
    pageEntity.timestamp = Date()
    return pageEntity
  }

  private func getOrCreateMovieEntity(id: Int, in context: NSManagedObjectContext) -> MovieEntity {
    let request: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
    request.predicate = NSPredicate(format: "id == %d", id)
    request.fetchLimit = 1

    do {
      if let existing = try context.fetch(request).first {
        return existing
      }
    } catch {
      print("Error checking existing movie entity: \(error)")
    }

    let movieEntity = MovieEntity(context: context)
    movieEntity.id = Int64(id)
    return movieEntity
  }

  private func createMovieEntity(from movie: Movie, in context: NSManagedObjectContext)
    -> MovieEntity
  {
    let movieEntity = MovieEntity(context: context)
    movieEntity.id = Int64(movie.id)
    movieEntity.title = movie.title
    movieEntity.posterURL = movie.posterURL

    if let releaseDateString = movie.releaseDate {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd"
      movieEntity.releaseDate = dateFormatter.date(from: releaseDateString)
    }

    return movieEntity
  }
}
