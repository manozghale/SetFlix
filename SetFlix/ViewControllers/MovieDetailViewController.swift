//
//  MovieDetailViewController.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import UIKit

class MovieDetailViewController: UIViewController {

  // MARK: - UI Components
  private let scrollView = UIScrollView()
  private let contentView = UIView()
  private let posterImageView = UIImageView()
  private let titleLabel = UILabel()
  private let yearLabel = UILabel()
  private let overviewLabel = UILabel()
  private let favoriteButton = UIButton()

  // MARK: - Properties
  private let movie: Movie

  // MARK: - Initialization
  init(movie: Movie) {
    self.movie = movie
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    setupUI()
    setupConstraints()
    configureWithMovie()
  }

  // MARK: - UI Setup
  private func setupUI() {
    view.backgroundColor = .systemBackground

    // Navigation bar setup
    title = "Movie Details"
    navigationItem.largeTitleDisplayMode = .never

    // Configure scroll view
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    contentView.translatesAutoresizingMaskIntoConstraints = false

    view.addSubview(scrollView)
    scrollView.addSubview(contentView)

    // Configure poster image view
    posterImageView.contentMode = .scaleAspectFill
    posterImageView.clipsToBounds = true
    posterImageView.layer.cornerRadius = 12
    posterImageView.backgroundColor = .systemGray5
    posterImageView.translatesAutoresizingMaskIntoConstraints = false

    // Configure title label
    titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
    titleLabel.textColor = .label
    titleLabel.numberOfLines = 0
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    // Configure year label
    yearLabel.font = UIFont.systemFont(ofSize: 18, weight: .medium)
    yearLabel.textColor = .secondaryLabel
    yearLabel.translatesAutoresizingMaskIntoConstraints = false

    // Configure overview label
    overviewLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
    overviewLabel.textColor = .label
    overviewLabel.numberOfLines = 0
    overviewLabel.translatesAutoresizingMaskIntoConstraints = false

    // Configure favorite button
    favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
    favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .selected)
    favoriteButton.tintColor = .systemRed
    favoriteButton.backgroundColor = .systemBackground
    favoriteButton.layer.cornerRadius = 25
    favoriteButton.layer.shadowColor = UIColor.black.cgColor
    favoriteButton.layer.shadowOffset = CGSize(width: 0, height: 2)
    favoriteButton.layer.shadowRadius = 4
    favoriteButton.layer.shadowOpacity = 0.1
    favoriteButton.translatesAutoresizingMaskIntoConstraints = false
    favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)

    // Add subviews to content view
    contentView.addSubview(posterImageView)
    contentView.addSubview(titleLabel)
    contentView.addSubview(yearLabel)
    contentView.addSubview(overviewLabel)
    contentView.addSubview(favoriteButton)
  }

  private func setupConstraints() {
    NSLayoutConstraint.activate([
      // Scroll view constraints
      scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      // Content view constraints
      contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
      contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
      contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
      contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
      contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

      // Poster image constraints
      posterImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
      posterImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
      posterImageView.widthAnchor.constraint(equalToConstant: 200),
      posterImageView.heightAnchor.constraint(equalToConstant: 300),

      // Title label constraints
      titleLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 20),
      titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

      // Year label constraints
      yearLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      yearLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      yearLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

      // Overview label constraints
      overviewLabel.topAnchor.constraint(equalTo: yearLabel.bottomAnchor, constant: 20),
      overviewLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      overviewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      overviewLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),

      // Favorite button constraints
      favoriteButton.topAnchor.constraint(equalTo: posterImageView.topAnchor, constant: 10),
      favoriteButton.trailingAnchor.constraint(
        equalTo: posterImageView.trailingAnchor, constant: -10),
      favoriteButton.widthAnchor.constraint(equalToConstant: 50),
      favoriteButton.heightAnchor.constraint(equalToConstant: 50),
    ])
  }

  // MARK: - Configuration
  private func configureWithMovie() {
    titleLabel.text = movie.title
    yearLabel.text = extractYear(from: movie.releaseDate)
    overviewLabel.text = movie.overview

    // Load poster image
    if let posterPath = movie.posterPath {
      loadPosterImage(from: posterPath)
    } else {
      posterImageView.image = UIImage(systemName: "film")
      posterImageView.tintColor = .systemGray3
      posterImageView.contentMode = .scaleAspectFit
    }

    // TODO: Check if movie is in favorites and update button state
    // This will be implemented in the next phase
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

    let placeholderImage = createPlaceholderImage(for: path)
    posterImageView.image = placeholderImage
    posterImageView.contentMode = .scaleAspectFill
  }

  private func createPlaceholderImage(for path: String) -> UIImage {
    // Create a simple placeholder image
    let size = CGSize(width: 200, height: 300)
    let renderer = UIGraphicsImageRenderer(size: size)

    return renderer.image { context in
      // Background
      UIColor.systemGray5.setFill()
      context.fill(CGRect(origin: .zero, size: size))

      // Film icon
      let iconSize: CGFloat = 60
      let iconRect = CGRect(
        x: (size.width - iconSize) / 2,
        y: (size.height - iconSize) / 2,
        width: iconSize,
        height: iconSize
      )

      UIColor.systemGray3.setFill()

      // Draw a simple film icon
      let path = UIBezierPath()
      path.move(to: CGPoint(x: iconRect.minX + 8, y: iconRect.minY))
      path.addLine(to: CGPoint(x: iconRect.maxX - 8, y: iconRect.minY))
      path.addLine(to: CGPoint(x: iconRect.maxX - 8, y: iconRect.maxY))
      path.addLine(to: CGPoint(x: iconRect.minX + 8, y: iconRect.maxY))
      path.close()
      path.fill()

      // Draw film perforations
      let perforationWidth: CGFloat = 4
      let perforationHeight: CGFloat = 8
      let spacing: CGFloat = 12

      for i in 0..<3 {
        let x = iconRect.minX + 4 + CGFloat(i) * spacing
        let y = iconRect.minY + 8

        let perforationRect = CGRect(x: x, y: y, width: perforationWidth, height: perforationHeight)
        UIColor.systemBackground.setFill()
        UIBezierPath(rect: perforationRect).fill()
      }
    }
  }

  // MARK: - Actions
  @objc private func favoriteButtonTapped() {
    favoriteButton.isSelected.toggle()

    // TODO: Implement favorite functionality
    // This will be implemented in the next phase with repository integration

    let isFavorite = favoriteButton.isSelected
    print("Movie \(movie.title) favorite status: \(isFavorite)")
  }
}
