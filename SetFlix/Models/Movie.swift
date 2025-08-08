//
//  Movie.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import Foundation

struct Movie: Codable, Identifiable, Equatable {
  let id: Int
  let title: String
  let releaseDate: String?
  let posterPath: String?
  var isFavorite: Bool

  // Custom coding keys to handle snake_case from API and include isFavorite
  enum CodingKeys: String, CodingKey {
    case id
    case title
    case releaseDate
    case posterPath
    case isFavorite // ✅ Include isFavorite in coding keys
  }

  // Manual initializer for creating Movie objects programmatically
  init(id: Int, title: String, releaseDate: String?, posterPath: String?, isFavorite: Bool = false)
  {
    self.id = id
    self.title = title
    self.releaseDate = releaseDate
    self.posterPath = posterPath
    self.isFavorite = isFavorite
  }

  // Custom decoder to handle the fact that isFavorite might not be in the API response
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    id = try container.decode(Int.self, forKey: .id)
    title = try container.decode(String.self, forKey: .title)

    // Handle release_date field - convert "nil" string to actual nil
    if let releaseDateString = try container.decodeIfPresent(String.self, forKey: .releaseDate) {
      releaseDate =
        (releaseDateString == "nil" || releaseDateString.isEmpty) ? nil : releaseDateString
    } else {
      releaseDate = nil
    }

    // Handle poster_path field - convert "nil" string to actual nil
    if let posterPathString = try container.decodeIfPresent(String.self, forKey: .posterPath) {
      posterPath = (posterPathString == "nil" || posterPathString.isEmpty) ? nil : posterPathString
    } else {
      posterPath = nil
    }

    // Try to decode isFavorite, default to false if not present (for API responses)
    isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
  }

  // Custom encoder to ensure isFavorite is included
  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    
    try container.encode(id, forKey: .id)
    try container.encode(title, forKey: .title)
    try container.encodeIfPresent(releaseDate, forKey: .releaseDate)
    try container.encodeIfPresent(posterPath, forKey: .posterPath)
    try container.encode(isFavorite, forKey: .isFavorite) // ✅ Always encode isFavorite
  }

  // Computed property for poster URL
  var posterURL: String? {
    guard let posterPath = posterPath else {
      print("❌ posterPath is nil for movie: \(title)")
      return nil
    }
    print("✅ posterPath: \(posterPath)")
    return "https://image.tmdb.org/t/p/w500\(posterPath)"
  }

  // Computed property for formatted release date
  var formattedReleaseDate: String {
    guard let releaseDate = releaseDate, !releaseDate.isEmpty else {
      print("❌ releaseDate is not available for movie: \(title)")
      return "Release date not available"
    }

    print("✅ releaseDate: \(releaseDate)")
    // Handle different date formats from TMDB API
    let dateFormatter = DateFormatter()

    // Try full date format first (YYYY-MM-DD)
    dateFormatter.dateFormat = "yyyy-MM-dd"
    if let date = dateFormatter.date(from: releaseDate) {
      let displayFormatter = DateFormatter()
      displayFormatter.dateStyle = .medium
      return displayFormatter.string(from: date)
    }

    // Try year-only format (YYYY)
    dateFormatter.dateFormat = "yyyy"
    if let date = dateFormatter.date(from: releaseDate) {
      let yearFormatter = DateFormatter()
      yearFormatter.dateFormat = "yyyy"
      return yearFormatter.string(from: date)
    }

    // Fallback: try to extract year from string using regex
    let yearPattern = #"(\d{4})"#
    if let regex = try? NSRegularExpression(pattern: yearPattern),
      let match = regex.firstMatch(
        in: releaseDate, range: NSRange(releaseDate.startIndex..., in: releaseDate))
    {
      let yearRange = Range(match.range(at: 1), in: releaseDate)!
      return String(releaseDate[yearRange])
    }

    // If all else fails, return the original string
    return releaseDate
  }
}

// MARK: - Search Response
struct MovieSearchResponse: Codable {
  let page: Int
  let results: [Movie]
  let totalPages: Int?
  let totalResults: Int?

  enum CodingKeys: String, CodingKey {
    case page
    case results
    case totalPages
    case totalResults
  }

  // Custom initializer to provide default values
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    page = try container.decode(Int.self, forKey: .page)
    results = try container.decode([Movie].self, forKey: .results)
    totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages)
    totalResults = try container.decodeIfPresent(Int.self, forKey: .totalResults)
  }

  // Manual initializer for creating responses
  init(page: Int, results: [Movie], totalPages: Int? = nil, totalResults: Int? = nil) {
    self.page = page
    self.results = results
    self.totalPages = totalPages
    self.totalResults = totalResults
  }
}

// MARK: - Movie Changes Response
struct MovieChangesResponse: Codable {
  let page: Int
  let results: [MovieChange]
  let totalPages: Int?
  let totalResults: Int?

  enum CodingKeys: String, CodingKey {
    case page
    case results
    case totalPages
    case totalResults
  }

  // Custom initializer to provide default values
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)

    page = try container.decode(Int.self, forKey: .page)
    results = try container.decode([MovieChange].self, forKey: .results)
    totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages)
    totalResults = try container.decodeIfPresent(Int.self, forKey: .totalResults)
  }

  // Manual initializer for creating responses
  init(page: Int, results: [MovieChange], totalPages: Int? = nil, totalResults: Int? = nil) {
    self.page = page
    self.results = results
    self.totalPages = totalPages
    self.totalResults = totalResults
  }
}

struct MovieChange: Codable {
  let id: Int
  let adult: Bool?
}
