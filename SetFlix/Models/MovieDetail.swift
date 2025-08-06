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
  let releaseDate: String
  let overview: String
  let posterPath: String?

  enum CodingKeys: String, CodingKey {
    case id
    case title
    case releaseDate = "release_date"
    case overview
    case posterPath = "poster_path"
  }

  // Computed property for poster URL
  var posterURL: String? {
    guard let posterPath = posterPath else { return nil }
    return "https://image.tmdb.org/t/p/w500\(posterPath)"
  }

  // Computed property for formatted release date
  var formattedReleaseDate: String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"

    guard let date = dateFormatter.date(from: releaseDate) else {
      return releaseDate
    }

    dateFormatter.dateStyle = .long
    return dateFormatter.string(from: date)
  }
}
