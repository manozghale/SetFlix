//
//  CoreDataManager.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import CoreData
import Foundation

class CoreDataManager {
  static let shared = CoreDataManager()

  private init() {}

  // MARK: - Core Data Stack

  lazy var persistentContainer: NSPersistentContainer = {
    let container = NSPersistentContainer(name: "SetFlix")
    container.loadPersistentStores { _, error in
      if let error = error as NSError? {
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    }
    return container
  }()

  var context: NSManagedObjectContext {
    return persistentContainer.viewContext
  }

  // Background context for write operations
  private var backgroundContext: NSManagedObjectContext {
    return persistentContainer.newBackgroundContext()
  }

  // Public method to get background context for external use
  func getBackgroundContext() -> NSManagedObjectContext {
    return persistentContainer.newBackgroundContext()
  }

  // MARK: - Save Context

  func saveContext() {
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        let error = error as NSError
        print("Error saving context: \(error), \(error.userInfo)")
      }
    }
  }

  func saveBackgroundContext(_ context: NSManagedObjectContext) {
    context.performAndWait {
      if context.hasChanges {
        do {
          try context.save()
        } catch {
          let error = error as NSError
          print("Error saving background context: \(error), \(error.userInfo)")
        }
      }
    }
  }

  // MARK: - Movie Operations

  func saveMovie(_ movie: Movie, isFavorite: Bool = false) {
    let backgroundContext = self.backgroundContext

    backgroundContext.performAndWait {
      // Check if movie already exists
      let request: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
      request.predicate = NSPredicate(format: "id == %d", movie.id)
      request.fetchLimit = 1

      let existingMovie: MovieEntity?
      do {
        existingMovie = try backgroundContext.fetch(request).first
      } catch {
        print("Error checking existing movie: \(error)")
        existingMovie = nil
      }

      let movieEntity: MovieEntity
      if let existing = existingMovie {
        movieEntity = existing
        // Preserve existing favorite status for existing movies
        print("🔄 Updating existing movie '\(movie.title)' (ID: \(movie.id)) - preserving favorite status: \(movieEntity.isFavorite)")
      } else {
        movieEntity = MovieEntity(context: backgroundContext)
        movieEntity.id = Int64(movie.id)
        movieEntity.isFavorite = isFavorite  // Only set favorite status for new movies
        print("🆕 Creating new movie '\(movie.title)' (ID: \(movie.id)) - setting favorite status to \(isFavorite)")
      }

      movieEntity.title = movie.title
      movieEntity.posterURL = movie.posterURL
      // Note: isFavorite is only set for new movies, existing movies keep their status

      // Convert string date to Date (handle optional release date)
      if let releaseDateString = movie.releaseDate {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        movieEntity.releaseDate = dateFormatter.date(from: releaseDateString)
      } else {
        movieEntity.releaseDate = nil
      }

      saveBackgroundContext(backgroundContext)
    }
  }

  func getMovie(by id: Int) -> MovieEntity? {
    var result: MovieEntity?

    context.performAndWait {
      let request: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
      request.predicate = NSPredicate(format: "id == %d", id)
      request.fetchLimit = 1

      do {
        result = try context.fetch(request).first
      } catch {
        print("Error fetching movie: \(error)")
        result = nil
      }
    }

    return result
  }

  func getAllMovies() -> [MovieEntity] {
    var result: [MovieEntity] = []

    context.performAndWait {
      let request: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()

      do {
        result = try context.fetch(request)
      } catch {
        print("Error fetching all movies: \(error)")
        result = []
      }
    }

    return result
  }

  func getFavoriteMovies() -> [MovieEntity] {
    var result: [MovieEntity] = []

    context.performAndWait {
      let request: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
      request.predicate = NSPredicate(format: "isFavorite == YES")

      do {
        result = try context.fetch(request)
      } catch {
        print("Error fetching favorite movies: \(error)")
        result = []
      }
    }

    return result
  }

  /// Get favorite status for multiple movies efficiently
  func getFavoriteStatus(for movieIds: [Int]) -> [Int: Bool] {
    var result: [Int: Bool] = [:]

    context.performAndWait {
      let request: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
      request.predicate = NSPredicate(
        format: "id IN %@ AND isFavorite == YES", movieIds.map { NSNumber(value: $0) })

      do {
        let favoriteMovies = try context.fetch(request)
        let favoriteIds = Set(favoriteMovies.map { Int($0.id) })

        // Set all movies to false by default, then mark favorites as true
        for movieId in movieIds {
          result[movieId] = favoriteIds.contains(movieId)
        }
      } catch {
        print("Error fetching favorite status: \(error)")
        // If there's an error, assume all movies are not favorites
        for movieId in movieIds {
          result[movieId] = false
        }
      }
    }

    return result
  }

  func toggleFavorite(for movieId: Int) -> Bool {
    let backgroundContext = self.backgroundContext
    var result = false

    backgroundContext.performAndWait {
      let request: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
      request.predicate = NSPredicate(format: "id == %d", movieId)
      request.fetchLimit = 1

      do {
        if let movieEntity = try backgroundContext.fetch(request).first {
          movieEntity.isFavorite.toggle()
          result = movieEntity.isFavorite
          saveBackgroundContext(backgroundContext)
        }
      } catch {
        print("Error toggling favorite: \(error)")
      }
    }

    return result
  }

  func deleteMovie(with id: Int) {
    let backgroundContext = self.backgroundContext

    backgroundContext.performAndWait {
      let request: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
      request.predicate = NSPredicate(format: "id == %d", id)
      request.fetchLimit = 1

      do {
        if let movieEntity = try backgroundContext.fetch(request).first {
          backgroundContext.delete(movieEntity)
          saveBackgroundContext(backgroundContext)
        }
      } catch {
        print("Error deleting movie: \(error)")
      }
    }
  }

  // MARK: - Page Operations

  func savePage(query: String, pageNumber: Int, movies: [Movie]) {
    let backgroundContext = self.backgroundContext

    backgroundContext.performAndWait {
      // First, save all movies
      for movie in movies {
        // Check if movie already exists
        let request: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", movie.id)
        request.fetchLimit = 1

        let existingMovie: MovieEntity?
        do {
          existingMovie = try backgroundContext.fetch(request).first
        } catch {
          print("Error checking existing movie: \(error)")
          existingMovie = nil
        }

        let movieEntity: MovieEntity
        if let existing = existingMovie {
          movieEntity = existing
          // Preserve existing favorite status for existing movies
          print(
            "🔄 Updating existing movie '\(movie.title)' (ID: \(movie.id)) - preserving favorite status: \(movieEntity.isFavorite)"
          )
        } else {
          movieEntity = MovieEntity(context: backgroundContext)
          movieEntity.id = Int64(movie.id)
          movieEntity.isFavorite = false  // Only set to false for new movies
          print(
            "🆕 Creating new movie '\(movie.title)' (ID: \(movie.id)) - setting favorite status to false"
          )
        }

        movieEntity.title = movie.title
        movieEntity.posterURL = movie.posterURL
        // Note: isFavorite is only set for new movies, existing movies keep their status

        // Convert string date to Date (handle optional release date)
        if let releaseDateString = movie.releaseDate {
          let dateFormatter = DateFormatter()
          dateFormatter.dateFormat = "yyyy-MM-dd"
          movieEntity.releaseDate = dateFormatter.date(from: releaseDateString)
        } else {
          movieEntity.releaseDate = nil
        }
      }

      // Create or update page entity
      let pageEntity = getOrCreatePageEntity(
        query: query, pageNumber: pageNumber, context: backgroundContext)
      pageEntity.timestamp = Date()

      // Get movie entities and add to page
      let movieEntities = movies.compactMap { movie -> MovieEntity? in
        let request: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %d", movie.id)
        request.fetchLimit = 1

        do {
          return try backgroundContext.fetch(request).first
        } catch {
          print("Error fetching movie for page: \(error)")
          return nil
        }
      }

      pageEntity.movies = NSSet(array: movieEntities)

      saveBackgroundContext(backgroundContext)
    }
  }

  func getOrCreatePageEntity(query: String, pageNumber: Int, context: NSManagedObjectContext)
    -> PageEntity
  {
    let request: NSFetchRequest<PageEntity> = PageEntity.fetchRequest()
    request.predicate = NSPredicate(format: "query == %@ AND pageNumber == %d", query, pageNumber)
    request.fetchLimit = 1

    do {
      if let existingPage = try context.fetch(request).first {
        return existingPage
      }
    } catch {
      print("Error fetching page: \(error)")
    }

    // Create new page entity
    let pageEntity = PageEntity(context: context)
    pageEntity.query = query
    pageEntity.pageNumber = Int32(pageNumber)
    pageEntity.timestamp = Date()

    return pageEntity
  }

  func getPageEntity(query: String, pageNumber: Int) -> PageEntity? {
    var result: PageEntity?

    context.performAndWait {
      let request: NSFetchRequest<PageEntity> = PageEntity.fetchRequest()
      request.predicate = NSPredicate(format: "query == %@ AND pageNumber == %d", query, pageNumber)
      request.fetchLimit = 1

      do {
        result = try context.fetch(request).first
      } catch {
        print("Error fetching page entity: \(error)")
        result = nil
      }
    }

    return result
  }

  func getCachedMovies(for query: String, pageNumber: Int) -> [MovieEntity]? {
    var result: [MovieEntity]?

    context.performAndWait {
      let request: NSFetchRequest<PageEntity> = PageEntity.fetchRequest()
      request.predicate = NSPredicate(format: "query == %@ AND pageNumber == %d", query, pageNumber)
      request.fetchLimit = 1

      do {
        guard let pageEntity = try context.fetch(request).first else {
          result = nil
          return
        }

        // Check if cache is still valid (1 hour)
        let cacheExpiration: TimeInterval = 3600  // 1 hour
        if let timestamp = pageEntity.timestamp,
          Date().timeIntervalSince(timestamp) > cacheExpiration
        {
          // Cache expired, delete it
          context.delete(pageEntity)
          saveContext()
          result = nil
          return
        }

        result = pageEntity.movies?.allObjects as? [MovieEntity] ?? []
      } catch {
        print("Error fetching cached movies: \(error)")
        result = nil
      }
    }

    return result
  }

  func clearCache() {
    let backgroundContext = self.backgroundContext

    backgroundContext.performAndWait {
      let pageRequest: NSFetchRequest<NSFetchRequestResult> = PageEntity.fetchRequest()
      let deletePageRequest = NSBatchDeleteRequest(fetchRequest: pageRequest)

      do {
        try backgroundContext.execute(deletePageRequest)
        saveBackgroundContext(backgroundContext)
      } catch {
        print("Error clearing cache: \(error)")
      }
    }
  }

  func clearExpiredCache() {
    let backgroundContext = self.backgroundContext

    backgroundContext.performAndWait {
      let request: NSFetchRequest<PageEntity> = PageEntity.fetchRequest()
      let cacheExpiration: TimeInterval = 3600  // 1 hour
      let expirationDate = Date().addingTimeInterval(-cacheExpiration)

      request.predicate = NSPredicate(format: "timestamp < %@", expirationDate as NSDate)

      do {
        let expiredPages = try backgroundContext.fetch(request)
        for page in expiredPages {
          backgroundContext.delete(page)
        }
        saveBackgroundContext(backgroundContext)
      } catch {
        print("Error clearing expired cache: \(error)")
      }
    }
  }

  func clearAllData() {
    let backgroundContext = self.backgroundContext

    backgroundContext.performAndWait {
      // Delete all movies
      let movieRequest: NSFetchRequest<NSFetchRequestResult> = MovieEntity.fetchRequest()
      let movieDeleteRequest = NSBatchDeleteRequest(fetchRequest: movieRequest)

      // Delete all pages
      let pageRequest: NSFetchRequest<NSFetchRequestResult> = PageEntity.fetchRequest()
      let pageDeleteRequest = NSBatchDeleteRequest(fetchRequest: pageRequest)

      do {
        try backgroundContext.execute(movieDeleteRequest)
        try backgroundContext.execute(pageDeleteRequest)
        saveBackgroundContext(backgroundContext)
        print("✅ Cleared all Core Data")
      } catch {
        print("❌ Error clearing Core Data: \(error)")
      }
    }
  }

  // MARK: - Search Results Operations

  /// Save search results with order preservation
  func saveSearchResults(query: String, movies: [Movie]) {
    let backgroundContext = self.backgroundContext

    backgroundContext.performAndWait {
      // First, clear any existing search results for this query
      clearSearchResults(for: query, context: backgroundContext)

      // Create a new SearchResultEntity for this query
      let searchResultEntity = SearchResultEntity(context: backgroundContext)
      searchResultEntity.query = query
      searchResultEntity.timestamp = Date()

      // Save movies and create ordered relationships
      var orderedMovies: [OrderedMovieEntity] = []
      
      for (index, movie) in movies.enumerated() {
        // Save or update the movie
        let movieEntity = saveOrUpdateMovie(movie, context: backgroundContext)
        
        // Create ordered movie entity to preserve order
        let orderedMovieEntity = OrderedMovieEntity(context: backgroundContext)
        orderedMovieEntity.order = Int32(index)
        orderedMovieEntity.movie = movieEntity
        orderedMovieEntity.searchResult = searchResultEntity
        
        orderedMovies.append(orderedMovieEntity)
      }

      // Set the ordered movies relationship
      searchResultEntity.orderedMovies = NSSet(array: orderedMovies)

      saveBackgroundContext(backgroundContext)
      print("💾 Saved \(movies.count) search results for query '\(query)' to Core Data")
    }
  }

  /// Retrieve search results with preserved order
  func getSearchResults(for query: String) -> [Movie]? {
    var result: [Movie]?

    context.performAndWait {
      let request: NSFetchRequest<SearchResultEntity> = SearchResultEntity.fetchRequest()
      request.predicate = NSPredicate(format: "query == %@", query)
      request.fetchLimit = 1

      do {
        guard let searchResultEntity = try context.fetch(request).first else {
          print("📱 No search results found in Core Data for query '\(query)'")
          result = nil
          return
        }

        // Check if cache is still valid (extended to 24 hours for better offline experience)
        let cacheExpiration: TimeInterval = 24 * 3600  // 24 hours
        if let timestamp = searchResultEntity.timestamp,
          Date().timeIntervalSince(timestamp) > cacheExpiration
        {
          // Cache expired, delete it
          context.delete(searchResultEntity)
          saveContext()
          print("⏰ Search results expired for query '\(query)', deleted from Core Data")
          result = nil
          return
        }

        // Get ordered movies
        let orderedMovies = searchResultEntity.orderedMovies?.allObjects as? [OrderedMovieEntity] ?? []
        
        // Sort by order and convert to Movie objects
        let sortedOrderedMovies = orderedMovies.sorted { $0.order < $1.order }
        let movies = sortedOrderedMovies.compactMap { orderedMovie -> Movie? in
          guard let movieEntity = orderedMovie.movie else { return nil }
          return movieEntity.toMovie()
        }

        print("📱 Retrieved \(movies.count) search results from Core Data for query '\(query)'")
        result = movies
      } catch {
        print("❌ Error fetching search results from Core Data: \(error)")
        result = nil
      }
    }

    return result
  }

  /// Clear search results for a specific query
  func clearSearchResults(for query: String) {
    clearSearchResults(for: query, context: context)
  }

  private func clearSearchResults(for query: String, context: NSManagedObjectContext) {
    let request: NSFetchRequest<SearchResultEntity> = SearchResultEntity.fetchRequest()
    request.predicate = NSPredicate(format: "query == %@", query)

    do {
      let searchResults = try context.fetch(request)
      for searchResult in searchResults {
        context.delete(searchResult)
      }
      print("🗑️ Cleared search results for query '\(query)' from Core Data")
    } catch {
      print("❌ Error clearing search results: \(error)")
    }
  }

  /// Clear all search results
  func clearAllSearchResults() {
    let backgroundContext = self.backgroundContext

    backgroundContext.performAndWait {
      let request: NSFetchRequest<NSFetchRequestResult> = SearchResultEntity.fetchRequest()
      let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

      do {
        try backgroundContext.execute(deleteRequest)
        saveBackgroundContext(backgroundContext)
        print("🗑️ Cleared all search results from Core Data")
      } catch {
        print("❌ Error clearing all search results: \(error)")
      }
    }
  }

  /// Get the last search query
  func getLastSearchQuery() -> String? {
    var result: String?

    context.performAndWait {
      let request: NSFetchRequest<SearchResultEntity> = SearchResultEntity.fetchRequest()
      request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
      request.fetchLimit = 1

      do {
        if let lastSearchResult = try context.fetch(request).first {
          result = lastSearchResult.query
        }
      } catch {
        print("❌ Error fetching last search query: \(error)")
        result = nil
      }
    }

    return result
  }

  /// Get the most recent valid search results (for offline fallback)
  func getMostRecentSearchResults() -> (query: String, movies: [Movie])? {
    var result: (query: String, movies: [Movie])?

    context.performAndWait {
      let request: NSFetchRequest<SearchResultEntity> = SearchResultEntity.fetchRequest()
      request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
      request.fetchLimit = 1

      do {
        guard let searchResultEntity = try context.fetch(request).first else {
          print("📱 No search results found in Core Data")
          result = nil
          return
        }

        // Check if cache is still valid (24 hours)
        let cacheExpiration: TimeInterval = 24 * 3600  // 24 hours
        if let timestamp = searchResultEntity.timestamp,
          Date().timeIntervalSince(timestamp) > cacheExpiration
        {
          print("⏰ Most recent search results expired, not using as fallback")
          result = nil
          return
        }

        // Get ordered movies
        let orderedMovies = searchResultEntity.orderedMovies?.allObjects as? [OrderedMovieEntity] ?? []
        
        // Sort by order and convert to Movie objects
        let sortedOrderedMovies = orderedMovies.sorted { $0.order < $1.order }
        let movies = sortedOrderedMovies.compactMap { orderedMovie -> Movie? in
          guard let movieEntity = orderedMovie.movie else { return nil }
          return movieEntity.toMovie()
        }

        if let query = searchResultEntity.query {
          print("📱 Retrieved most recent search results: '\(query)' with \(movies.count) movies")
          result = (query: query, movies: movies)
        } else {
          result = nil
        }
      } catch {
        print("❌ Error fetching most recent search results: \(error)")
        result = nil
      }
    }

    return result
  }

  private func saveOrUpdateMovie(_ movie: Movie, context: NSManagedObjectContext) -> MovieEntity {
    // Check if movie already exists
    let request: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
    request.predicate = NSPredicate(format: "id == %d", movie.id)
    request.fetchLimit = 1

    let existingMovie: MovieEntity?
    do {
      existingMovie = try context.fetch(request).first
    } catch {
      print("Error checking existing movie: \(error)")
      existingMovie = nil
    }

    let movieEntity: MovieEntity
    if let existing = existingMovie {
      movieEntity = existing
      // Preserve existing favorite status for existing movies
      print("🔄 Updating existing movie '\(movie.title)' (ID: \(movie.id)) - preserving favorite status: \(movieEntity.isFavorite)")
    } else {
      movieEntity = MovieEntity(context: context)
      movieEntity.id = Int64(movie.id)
      movieEntity.isFavorite = false  // Only set to false for new movies
      print("🆕 Creating new movie '\(movie.title)' (ID: \(movie.id)) - setting favorite status to false")
    }

    movieEntity.title = movie.title
    movieEntity.posterURL = movie.posterURL
    // Note: isFavorite is only set for new movies, existing movies keep their status

    // Convert string date to Date (handle optional release date)
    if let releaseDateString = movie.releaseDate {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd"
      movieEntity.releaseDate = dateFormatter.date(from: releaseDateString)
    } else {
      movieEntity.releaseDate = nil
    }

    return movieEntity
  }
}

// MARK: - Extensions

extension MovieEntity {
  func toMovie() -> Movie? {
    guard let title = title else { return nil }

    let releaseDateString: String?
    if let releaseDate = releaseDate {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd"
      releaseDateString = dateFormatter.string(from: releaseDate)
    } else {
      releaseDateString = nil
    }

    return Movie(
      id: Int(id),
      title: title,
      releaseDate: releaseDateString,
      posterPath: posterURL?.replacingOccurrences(of: "https://image.tmdb.org/t/p/w500", with: ""),
      isFavorite: isFavorite
    )
  }
}
