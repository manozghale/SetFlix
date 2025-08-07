//
//  MovieDetail.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import Foundation

struct MovieDetail: Codable, Identifiable {
  let id: Int
  let title: String
  let releaseDate: String?
  let overview: String
  let posterPath: String?

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case releaseDate
    case overview
    case posterPath
  }

  // Computed property for poster URL
  var posterURL: String? {
    guard let posterPath = posterPath else { return nil }
    return "https://image.tmdb.org/t/p/w500\(posterPath)"
  }

  // Computed property for formatted release date
  var formattedReleaseDate: String {
    guard let releaseDate = releaseDate, !releaseDate.isEmpty else {
      return "Release date not available"
    }

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
