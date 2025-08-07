//
//  MovieDetailViewController.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import Combine
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

  // MARK: - ViewModel
  private let viewModel: MovieDetailViewModel
  private var cancellables = Set<AnyCancellable>()

  // MARK: - Initialization
  init(movie: Movie, viewModel: MovieDetailViewModel? = nil) {
    let movieViewModel = viewModel ?? MovieDetailViewModel(movie: movie)
    self.viewModel = movieViewModel
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
    setupBindings()
    viewModel.loadMovieDetails()
  }

  // MARK: - UI Setup
  private func setupUI() {
    view.backgroundColor = .systemBackground

    // Navigation bar setup
    navigationItem.largeTitleDisplayMode = .never

    // Add subviews
    view.addSubview(scrollView)
    scrollView.addSubview(contentView)
    contentView.addSubview(posterImageView)
    contentView.addSubview(titleLabel)
    contentView.addSubview(yearLabel)
    contentView.addSubview(overviewLabel)
    contentView.addSubview(favoriteButton)

    // Configure poster image view
    posterImageView.contentMode = .scaleAspectFill
    posterImageView.clipsToBounds = true
    posterImageView.layer.cornerRadius = 8

    // Configure title label
    titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
    titleLabel.numberOfLines = 0
    titleLabel.textColor = .label

    // Configure year label
    yearLabel.font = .systemFont(ofSize: 16, weight: .medium)
    yearLabel.textColor = .secondaryLabel

    // Configure overview label
    overviewLabel.font = .systemFont(ofSize: 16)
    overviewLabel.numberOfLines = 0
    overviewLabel.textColor = .label

    // Configure favorite button
    favoriteButton.setImage(UIImage(systemName: "heart"), for: .normal)
    favoriteButton.setImage(UIImage(systemName: "heart.fill"), for: .selected)
    favoriteButton.tintColor = .systemRed
    favoriteButton.addTarget(self, action: #selector(favoriteButtonTapped), for: .touchUpInside)
  }

  private func setupConstraints() {
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    contentView.translatesAutoresizingMaskIntoConstraints = false
    posterImageView.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    yearLabel.translatesAutoresizingMaskIntoConstraints = false
    overviewLabel.translatesAutoresizingMaskIntoConstraints = false
    favoriteButton.translatesAutoresizingMaskIntoConstraints = false

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
      posterImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      posterImageView.widthAnchor.constraint(equalToConstant: 200),
      posterImageView.heightAnchor.constraint(equalToConstant: 300),

      // Title label constraints
      titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
      titleLabel.leadingAnchor.constraint(equalTo: posterImageView.trailingAnchor, constant: 20),
      titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),

      // Year label constraints
      yearLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
      yearLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      yearLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),

      // Favorite button constraints
      favoriteButton.topAnchor.constraint(equalTo: yearLabel.bottomAnchor, constant: 16),
      favoriteButton.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
      favoriteButton.widthAnchor.constraint(equalToConstant: 44),
      favoriteButton.heightAnchor.constraint(equalToConstant: 44),

      // Overview label constraints
      overviewLabel.topAnchor.constraint(equalTo: posterImageView.bottomAnchor, constant: 20),
      overviewLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
      overviewLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
      overviewLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
    ])
  }

  // MARK: - Setup
  private func setupBindings() {
    // Bind movie details to UI
    viewModel.$movieDetail
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.configureUI()
      }
      .store(in: &cancellables)

    // Bind loading state
    viewModel.$isLoading
      .receive(on: DispatchQueue.main)
      .sink { isLoading in
        // Show/hide loading indicator if needed
        // Currently no loading indicator implemented
      }
      .store(in: &cancellables)

    // Bind error messages
    viewModel.$errorMessage
      .compactMap { $0 }
      .receive(on: DispatchQueue.main)
      .sink { [weak self] errorMessage in
        self?.showError(errorMessage)
        self?.viewModel.clearError()
      }
      .store(in: &cancellables)

    // Bind favorite state
    viewModel.$isFavorite
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isFavorite in
        self?.favoriteButton.isSelected = isFavorite
      }
      .store(in: &cancellables)
  }

  private func configureUI() {
    titleLabel.text = viewModel.title
    overviewLabel.text = viewModel.overview
    yearLabel.text = viewModel.releaseYear

    if let posterURL = viewModel.posterURL {
      loadPosterImage(from: posterURL)
    } else {
      posterImageView.image = UIImage(named: "placeholder_poster")
    }
  }

  private func loadPosterImage(from path: String) {
    // Set placeholder first
    posterImageView.image = createPlaceholderImage(for: path)
    posterImageView.contentMode = .scaleAspectFill

    // Use ImageLoader for real image loading
    Task {
      await posterImageView.loadImageAsync(from: path, size: "w500")
    }
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

      let config = UIImage.SymbolConfiguration(pointSize: iconSize, weight: .light)
      let filmIcon = UIImage(systemName: "film", withConfiguration: config)
      filmIcon?.draw(in: iconRect)

      // Text
      let text = "No Image"
      let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: 14, weight: .medium),
        .foregroundColor: UIColor.systemGray,
      ]

      let textSize = text.size(withAttributes: attributes)
      let textRect = CGRect(
        x: (size.width - textSize.width) / 2,
        y: iconRect.maxY + 8,
        width: textSize.width,
        height: textSize.height
      )

      text.draw(in: textRect, withAttributes: attributes)
    }
  }

  private func showError(_ message: String) {
    let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }

  // MARK: - Actions
  @objc private func favoriteButtonTapped() {
    viewModel.toggleFavorite()
  }
}
