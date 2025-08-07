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

  // MARK: - Save Context

  func saveContext() {
    if context.hasChanges {
      do {
        try context.save()
      } catch {
        let error = error as NSError
        fatalError("Unresolved error \(error), \(error.userInfo)")
      }
    }
  }

  // MARK: - Movie Operations

  func saveMovie(_ movie: Movie, isFavorite: Bool = false) {
    let movieEntity = MovieEntity(context: context)
    movieEntity.id = Int64(movie.id)
    movieEntity.title = movie.title

    movieEntity.posterURL = movie.posterURL
    movieEntity.isFavorite = isFavorite

    // Convert string date to Date
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    movieEntity.releaseDate = dateFormatter.date(from: movie.releaseDate)

    saveContext()
  }

  func getMovie(by id: Int) -> MovieEntity? {
    let request: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
    request.predicate = NSPredicate(format: "id == %d", id)
    request.fetchLimit = 1

    do {
      return try context.fetch(request).first
    } catch {
      print("Error fetching movie: \(error)")
      return nil
    }
  }

  func getAllMovies() -> [MovieEntity] {
    let request: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()

    do {
      return try context.fetch(request)
    } catch {
      print("Error fetching all movies: \(error)")
      return []
    }
  }

  func getFavoriteMovies() -> [MovieEntity] {
    let request: NSFetchRequest<MovieEntity> = MovieEntity.fetchRequest()
    request.predicate = NSPredicate(format: "isFavorite == YES")

    do {
      return try context.fetch(request)
    } catch {
      print("Error fetching favorite movies: \(error)")
      return []
    }
  }

  func toggleFavorite(for movieId: Int) -> Bool {
    guard let movieEntity = getMovie(by: movieId) else { return false }

    movieEntity.isFavorite.toggle()
    saveContext()

    return movieEntity.isFavorite
  }

  func deleteMovie(with id: Int) {
    guard let movieEntity = getMovie(by: id) else { return }

    context.delete(movieEntity)
    saveContext()
  }

  // MARK: - Page Operations

  func savePage(query: String, pageNumber: Int, movies: [Movie]) {
    // First, save all movies
    for movie in movies {
      saveMovie(movie)
    }

    // Create or update page entity
    let pageEntity = getOrCreatePageEntity(query: query, pageNumber: pageNumber)
    pageEntity.timestamp = Date()

    // Get movie entities and add to page
    let movieEntities = movies.compactMap { getMovie(by: $0.id) }
    pageEntity.movies = NSSet(array: movieEntities)

    saveContext()
  }

  func getOrCreatePageEntity(query: String, pageNumber: Int) -> PageEntity {
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
    let request: NSFetchRequest<PageEntity> = PageEntity.fetchRequest()
    request.predicate = NSPredicate(format: "query == %@ AND pageNumber == %d", query, pageNumber)
    request.fetchLimit = 1

    do {
      guard let pageEntity = try context.fetch(request).first else { return nil }

      // Check if cache is still valid (1 hour)
      let cacheExpiration: TimeInterval = 3600  // 1 hour
      if let timestamp = pageEntity.timestamp,
        Date().timeIntervalSince(timestamp) > cacheExpiration
      {
        // Cache expired, delete it
        context.delete(pageEntity)
        saveContext()
        return nil
      }

      return pageEntity.movies?.allObjects as? [MovieEntity] ?? []
    } catch {
      print("Error fetching cached movies: \(error)")
      return nil
    }
  }

  func clearCache() {
    let pageRequest: NSFetchRequest<NSFetchRequestResult> = PageEntity.fetchRequest()
    let deletePageRequest = NSBatchDeleteRequest(fetchRequest: pageRequest)

    do {
      try context.execute(deletePageRequest)
      saveContext()
    } catch {
      print("Error clearing cache: \(error)")
    }
  }

  func clearExpiredCache() {
    let request: NSFetchRequest<PageEntity> = PageEntity.fetchRequest()
    let cacheExpiration: TimeInterval = 3600  // 1 hour
    let expirationDate = Date().addingTimeInterval(-cacheExpiration)

    request.predicate = NSPredicate(format: "timestamp < %@", expirationDate as NSDate)

    do {
      let expiredPages = try context.fetch(request)
      for page in expiredPages {
        context.delete(page)
      }
      saveContext()
    } catch {
      print("Error clearing expired cache: \(error)")
    }
  }
}

// MARK: - Extensions

extension MovieEntity {
  func toMovie() -> Movie? {
    guard let title = title,
      let releaseDate = releaseDate
    else { return nil }

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"
    let releaseDateString = dateFormatter.string(from: releaseDate)

    return Movie(
      id: Int(id),
      title: title,
      releaseDate: releaseDateString,
      posterPath: posterURL?.replacingOccurrences(of: "https://image.tmdb.org/t/p/w500", with: "")
    )
  }
}
