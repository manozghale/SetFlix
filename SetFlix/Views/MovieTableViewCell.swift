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

      // Content view height
      contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
    ])
  }

  // MARK: - Configuration
  func configure(with movie: Movie) {
    titleLabel.text = movie.title
    yearLabel.text = extractYear(from: movie.releaseDate)

    // Load poster image
    if let posterPath = movie.posterPath {
      // For now, we'll use a placeholder image
      // In the next phase, this will be replaced with actual image loading
      loadPosterImage(from: posterPath)
    } else {
      posterImageView.image = UIImage(systemName: "film")
      posterImageView.tintColor = .systemGray3
      posterImageView.contentMode = .scaleAspectFit
    }
  }

  private func extractYear(from dateString: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"

    if let date = dateFormatter.date(from: dateString) {
      let yearFormatter = DateFormatter()
      yearFormatter.dateFormat = "yyyy"
      return yearFormatter.string(from: date)
    }

    // Fallback: try to extract year from string
    if let year = dateString.components(separatedBy: "-").first {
      return year
    }

    return dateString
  }

  private func loadPosterImage(from path: String) {
    // For Phase 2, we'll use placeholder images
    // In Phase 3, this will be replaced with actual ImageLoader integration

    // Create a placeholder image with movie title
    let placeholderImage = createPlaceholderImage(for: path)
    posterImageView.image = placeholderImage
    posterImageView.contentMode = .scaleAspectFill
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
