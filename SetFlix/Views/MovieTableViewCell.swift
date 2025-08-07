//
//  MovieTableViewCell.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import UIKit

class MovieTableViewCell: UITableViewCell {

  // MARK: - UI Components
  private let posterImageView = UIImageView()
  private let titleLabel = UILabel()
  private let yearLabel = UILabel()
  private let favoriteIndicator = UIImageView()
  private let stackView = UIStackView()

  // MARK: - Properties
  static let identifier = "MovieTableViewCell"

  // MARK: - Initialization
  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupUI()
    setupConstraints()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - UI Setup
  private func setupUI() {
    // Configure poster image view
    posterImageView.contentMode = .scaleAspectFill
    posterImageView.clipsToBounds = true
    posterImageView.layer.cornerRadius = 8
    posterImageView.backgroundColor = .systemGray5
    posterImageView.translatesAutoresizingMaskIntoConstraints = false

    // Configure title label
    titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 2
    titleLabel.lineBreakMode = .byTruncatingTail
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    // Configure year label
    yearLabel.font = UIFont.systemFont(ofSize: 14, weight: .regular)
    yearLabel.textColor = .secondaryLabel
    yearLabel.translatesAutoresizingMaskIntoConstraints = false

    // Configure favorite indicator
    favoriteIndicator.image = UIImage(systemName: "heart.fill")
    favoriteIndicator.tintColor = .systemRed
    favoriteIndicator.contentMode = .scaleAspectFit
    favoriteIndicator.translatesAutoresizingMaskIntoConstraints = false
    favoriteIndicator.isHidden = true  // Hidden by default

    // Configure stack view for text content
    stackView.axis = .vertical
    stackView.spacing = 4
    stackView.alignment = .leading
    stackView.distribution = .fill
    stackView.translatesAutoresizingMaskIntoConstraints = false

    // Add labels to stack view
    stackView.addArrangedSubview(titleLabel)
    stackView.addArrangedSubview(yearLabel)

    // Add subviews to content view
    contentView.addSubview(posterImageView)
    contentView.addSubview(stackView)
    contentView.addSubview(favoriteIndicator)

    // Configure cell
    backgroundColor = .systemBackground
    selectionStyle = .none
  }

  private func setupConstraints() {
    NSLayoutConstraint.activate([
      // Poster image constraints
      posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
      posterImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      posterImageView.widthAnchor.constraint(equalToConstant: 60),
      posterImageView.heightAnchor.constraint(equalToConstant: 80),

      // Stack view constraints
      stackView.leadingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: 12),
      stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
      stackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

      // Favorite indicator constraints
      favoriteIndicator.trailingAnchor.constraint(
        equalTo: contentView.trailingAnchor, constant: -16),
      favoriteIndicator.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
      favoriteIndicator.widthAnchor.constraint(equalToConstant: 24),
      favoriteIndicator.heightAnchor.constraint(equalToConstant: 24),

      // Content view height
      contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
    ])
  }

  // MARK: - Configuration
  func configure(with movie: Movie) {
    titleLabel.text = movie.title
    yearLabel.text = extractYear(from: movie.releaseDate)

    // Show/hide favorite indicator
    favoriteIndicator.isHidden = !movie.isFavorite

    // Load poster image
    if let posterPath = movie.posterPath {
      loadPosterImage(from: posterPath)
    } else {
      posterImageView.image = UIImage(systemName: "film")
      posterImageView.tintColor = .systemGray3
      posterImageView.contentMode = .scaleAspectFit
    }
  }

  private func extractYear(from dateString: String?) -> String {
    guard let dateString = dateString, !dateString.isEmpty else {
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

  private func loadPosterImage(from path: String) {
    // Set placeholder first
    posterImageView.image = createPlaceholderImage(for: path)
    posterImageView.contentMode = .scaleAspectFill

    // Load real image using ImageLoader
    Task {
      await posterImageView.loadImageAsync(from: path, size: "w92")
    }
  }

  private func createPlaceholderImage(for path: String) -> UIImage {
    // Create a simple placeholder image
    let size = CGSize(width: 60, height: 80)
    let renderer = UIGraphicsImageRenderer(size: size)

    return renderer.image { context in
      // Background
      UIColor.systemGray5.setFill()
      context.fill(CGRect(origin: .zero, size: size))

      // Film icon
      let iconSize: CGFloat = 24
      let iconRect = CGRect(
        x: (size.width - iconSize) / 2,
        y: (size.height - iconSize) / 2,
        width: iconSize,
        height: iconSize
      )

      UIColor.systemGray3.setFill()

      // Draw a simple film icon
      let path = UIBezierPath()
      path.move(to: CGPoint(x: iconRect.minX + 4, y: iconRect.minY))
      path.addLine(to: CGPoint(x: iconRect.maxX - 4, y: iconRect.minY))
      path.addLine(to: CGPoint(x: iconRect.maxX - 4, y: iconRect.maxY))
      path.addLine(to: CGPoint(x: iconRect.minX + 4, y: iconRect.maxY))
      path.close()
      path.fill()

      // Draw film perforations
      let perforationWidth: CGFloat = 2
      let perforationHeight: CGFloat = 4
      let spacing: CGFloat = 6

      for i in 0..<3 {
        let x = iconRect.minX + 2 + CGFloat(i) * spacing
        let y = iconRect.minY + 4

        let perforationRect = CGRect(x: x, y: y, width: perforationWidth, height: perforationHeight)
        UIColor.systemBackground.setFill()
        UIBezierPath(rect: perforationRect).fill()
      }
    }
  }

  // MARK: - Reuse
  override func prepareForReuse() {
    super.prepareForReuse()
    posterImageView.image = nil
    titleLabel.text = nil
    yearLabel.text = nil
  }
}
