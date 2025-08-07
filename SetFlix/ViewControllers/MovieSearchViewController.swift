//
//  MovieSearchViewController.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import UIKit

class MovieSearchViewController: UIViewController {

  // MARK: - UI Components
  private let searchController = UISearchController(searchResultsController: nil)
  private let tableView = UITableView()
  private let loadingIndicator = UIActivityIndicatorView(style: .large)
  private let emptyStateView = EmptyStateView()

  // MARK: - Properties
  private var movies: [Movie] = []
  private var filteredMovies: [Movie] = []
  private var isSearching = false
  private var currentPage = 1
  private var hasMorePages = true
  private var isLoading = false
  private var searchTask: Task<Void, Never>?

  // MARK: - Dependencies
  private let repository: MovieRepository

  // MARK: - Initialization
  init(repository: MovieRepository = MovieRepositoryFactory.createRepository()) {
    self.repository = repository
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
    setupSearchController()
    setupTableView()
    loadInitialData()
  }

  // MARK: - UI Setup
  private func setupUI() {
    view.backgroundColor = .systemBackground

    // Navigation bar setup
    title = "Movies"
    navigationController?.navigationBar.prefersLargeTitles = true

    // Add menu button to navigation bar
    let menuButton = UIBarButtonItem(
      image: UIImage(systemName: "list.bullet"),
      style: .plain,
      target: self,
      action: #selector(menuButtonTapped)
    )
    navigationItem.rightBarButtonItem = menuButton

    // Add subviews
    view.addSubview(tableView)
    view.addSubview(loadingIndicator)
    view.addSubview(emptyStateView)

    // Configure loading indicator
    loadingIndicator.hidesWhenStopped = true
    loadingIndicator.color = .systemBlue

    // Initially hide empty state
    emptyStateView.isHidden = true
  }

  private func setupConstraints() {
    tableView.translatesAutoresizingMaskIntoConstraints = false
    loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
    emptyStateView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      // Table view constraints
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      // Loading indicator constraints
      loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),

      // Empty state constraints
      emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      emptyStateView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      emptyStateView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      emptyStateView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
    ])
  }

  private func setupSearchController() {
    searchController.searchResultsUpdater = self
    searchController.obscuresBackgroundDuringPresentation = false
    searchController.searchBar.placeholder = "Search movies..."
    searchController.searchBar.tintColor = .systemBlue

    // Add search bar to navigation bar
    navigationItem.searchController = searchController
    definesPresentationContext = true
  }

  private func setupTableView() {
    tableView.delegate = self
    tableView.dataSource = self
    tableView.prefetchDataSource = self

    // Register custom cell
    tableView.register(
      MovieTableViewCell.self, forCellReuseIdentifier: MovieTableViewCell.identifier)

    // Configure table view
    tableView.separatorStyle = .singleLine
    tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    tableView.rowHeight = 100
    tableView.backgroundColor = .systemBackground

    // Remove empty cells
    tableView.tableFooterView = UIView()
  }

  // MARK: - Data Loading
  private func loadInitialData() {
    // Load cached data first, then try to refresh from API
    loadCachedData()
    refreshFromAPI()
  }

  private func loadCachedData() {
    Task {
      do {
        // For now, we'll load some sample data
        // In the next phase, this will be replaced with actual cached data
        await MainActor.run {
          loadSampleData()
        }
      } catch {
        await MainActor.run {
          showError("Failed to load cached data: \(error.localizedDescription)")
        }
      }
    }
  }

  private func refreshFromAPI() {
    // This will be implemented when we add real API integration
    // For now, we'll keep the sample data
  }

  private func loadSampleData() {
    movies = [
      Movie(
        id: 1, title: "The Enigma Code", releaseDate: "2022-01-15",
        posterPath: "/sample1.jpg"),
      Movie(
        id: 2, title: "Starlight Symphony", releaseDate: "2023-03-22",
        posterPath: "/sample2.jpg"),
      Movie(
        id: 3, title: "Echoes of the Past", releaseDate: "2021-11-08",
        posterPath: "/sample3.jpg"),
      Movie(
        id: 4, title: "Crimson Horizon", releaseDate: "2022-07-14",
        posterPath: "/sample4.jpg"),
      Movie(
        id: 5, title: "Whispers of the Wind", releaseDate: "2023-05-30",
        posterPath: "/sample5.jpg"),
      Movie(
        id: 6, title: "The Silent Observer", releaseDate: "2021-09-12",
        posterPath: "/sample6.jpg"),
      Movie(
        id: 7, title: "Beneath the Surface", releaseDate: "2022-12-03",
        posterPath: "/sample7.jpg"),
    ]

    filteredMovies = movies
    tableView.reloadData()
    updateEmptyState()
  }

  private func searchMovies(query: String) {
    // Cancel previous search task
    searchTask?.cancel()

    guard !query.isEmpty else {
      filteredMovies = movies
      tableView.reloadData()
      updateEmptyState()
      return
    }

    // Create new search task with debouncing
    searchTask = Task {
      do {
        // Add a small delay for debouncing
        try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds

        // Check if task was cancelled
        try Task.checkCancellation()

        // Perform search
        let searchResponse = try await repository.searchMovies(query: query, page: 1)

        // Check if task was cancelled before updating UI
        try Task.checkCancellation()

        await MainActor.run {
          self.filteredMovies = searchResponse.results
          self.hasMorePages = searchResponse.page < searchResponse.totalPages
          self.currentPage = searchResponse.page
          self.tableView.reloadData()
          self.updateEmptyState()
        }
      } catch is CancellationError {
        // Search was cancelled, do nothing
        return
      } catch {
        await MainActor.run {
          self.showError("Search failed: \(error.localizedDescription)")
        }
      }
    }
  }

  private func loadMoreResults() {
    guard !isLoading && hasMorePages else { return }

    isLoading = true

    Task {
      do {
        guard let searchText = searchController.searchBar.text, !searchText.isEmpty else {
          await MainActor.run {
            self.isLoading = false
          }
          return
        }

        let nextPage = currentPage + 1
        let searchResponse = try await repository.searchMovies(query: searchText, page: nextPage)

        await MainActor.run {
          self.movies.append(contentsOf: searchResponse.results)
          self.filteredMovies = self.movies
          self.hasMorePages = searchResponse.page < searchResponse.totalPages
          self.currentPage = searchResponse.page
          self.isLoading = false
          self.tableView.reloadData()
        }
      } catch {
        await MainActor.run {
          self.isLoading = false
          self.showError("Failed to load more results: \(error.localizedDescription)")
        }
      }
    }
  }

  private func updateEmptyState() {
    let isEmpty = filteredMovies.isEmpty
    emptyStateView.isHidden = !isEmpty
    tableView.isHidden = isEmpty

    if isEmpty {
      if isSearching {
        emptyStateView.configure(
          title: "No Results Found",
          message: "Try searching for a different movie title",
          imageName: "magnifyingglass"
        )
      } else {
        emptyStateView.configure(
          title: "No Movies Available",
          message: "Movies will appear here once loaded",
          imageName: "film"
        )
      }
    }
  }

  private func showError(_ message: String) {
    let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }

  // MARK: - Actions
  @objc private func menuButtonTapped() {
    // TODO: Implement menu functionality
    print("Menu button tapped")
  }
}

// MARK: - UITableViewDataSource
extension MovieSearchViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return filteredMovies.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard
      let cell = tableView.dequeueReusableCell(
        withIdentifier: MovieTableViewCell.identifier, for: indexPath) as? MovieTableViewCell
    else {
      return UITableViewCell()
    }

    let movie = filteredMovies[indexPath.row]
    cell.configure(with: movie)
    cell.selectionStyle = .none

    return cell
  }
}

// MARK: - UITableViewDelegate
extension MovieSearchViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)

    let movie = filteredMovies[indexPath.row]
    let detailViewController = MovieDetailViewController(movie: movie, repository: repository)
    navigationController?.pushViewController(detailViewController, animated: true)
  }
}

// MARK: - UITableViewDataSourcePrefetching
extension MovieSearchViewController: UITableViewDataSourcePrefetching {
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    let thresholdIndex = filteredMovies.count - 5

    for indexPath in indexPaths {
      if indexPath.row >= thresholdIndex {
        loadMoreResults()
        break
      }
    }
  }
}

// MARK: - UISearchResultsUpdating
extension MovieSearchViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    guard let searchText = searchController.searchBar.text else { return }

    isSearching = !searchText.isEmpty
    searchMovies(query: searchText)
  }
}
