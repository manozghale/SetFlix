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
      } else {
        movieEntity = MovieEntity(context: backgroundContext)
        movieEntity.id = Int64(movie.id)
      }

      movieEntity.title = movie.title
      movieEntity.posterURL = movie.posterURL
      movieEntity.isFavorite = isFavorite

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
        } else {
          movieEntity = MovieEntity(context: backgroundContext)
          movieEntity.id = Int64(movie.id)
        }

        movieEntity.title = movie.title
        movieEntity.posterURL = movie.posterURL
        movieEntity.isFavorite = false

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
      posterPath: posterURL?.replacingOccurrences(of: "https://image.tmdb.org/t/p/w500", with: "")
    )
  }
}
