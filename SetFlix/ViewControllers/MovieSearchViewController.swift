//
//  MovieSearchViewController.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import Combine
import UIKit

class MovieSearchViewController: UIViewController {

  // MARK: - UI Components
  private let searchController = UISearchController(searchResultsController: nil)
  private let tableView = UITableView()
  private let loadingIndicator = UIActivityIndicatorView(style: .large)
  private let emptyStateView = EmptyStateView()
  private let refreshControl = UIRefreshControl()

  // MARK: - ViewModel
  private let viewModel: MovieSearchViewModel
  private var cancellables = Set<AnyCancellable>()

  // MARK: - Initialization
  init(viewModel: MovieSearchViewModel) {
    self.viewModel = viewModel
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
    setupBindings()
    viewModel.loadInitialData()
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

    // Add refresh control
    refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    tableView.refreshControl = refreshControl
  }

  // MARK: - Setup
  private func setupBindings() {
    // Bind movies to table view
    viewModel.$filteredMovies
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.tableView.reloadData()
        self?.updateEmptyState()
      }
      .store(in: &cancellables)

    // Bind loading state
    viewModel.$isLoading
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isLoading in
        self?.loadingIndicator.isHidden = !isLoading
        if isLoading {
          self?.loadingIndicator.startAnimating()
        } else {
          self?.loadingIndicator.stopAnimating()
        }
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

    // Bind empty state
    viewModel.$isEmptyState
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isEmpty in
        self?.updateEmptyState()
      }
      .store(in: &cancellables)

    // Add cache status indicator
    viewModel.$isLoading
      .combineLatest(viewModel.$filteredMovies)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isLoading, movies in
        if !isLoading && !movies.isEmpty {
          self?.showCacheIndicator()
        }
      }
      .store(in: &cancellables)
  }

  private func updateEmptyState() {
    let isEmpty = viewModel.isEmptyState
    emptyStateView.isHidden = !isEmpty
    tableView.isHidden = isEmpty

    if isEmpty {
      if viewModel.isSearching {
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

  private func showCacheIndicator() {
    if !viewModel.isNetworkAvailable() {
      // Show offline indicator
      let offlineLabel = UILabel()
      offlineLabel.text = "📱 Offline Mode - Showing cached results"
      offlineLabel.textAlignment = .center
      offlineLabel.backgroundColor = .systemYellow.withAlphaComponent(0.8)
      offlineLabel.textColor = .black
      offlineLabel.font = .systemFont(ofSize: 12)
      offlineLabel.layer.cornerRadius = 4
      offlineLabel.clipsToBounds = true

      // Add to navigation bar
      navigationItem.titleView = offlineLabel
    } else {
      navigationItem.titleView = nil
    }
  }

  // MARK: - Actions
  @objc private func menuButtonTapped() {
    // TODO: Implement menu functionality
    print("Menu button tapped")
  }

  @objc private func refreshData() {
    viewModel.refreshData()
    refreshControl.endRefreshing()
  }
}

// MARK: - UITableViewDataSource
extension MovieSearchViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.filteredMovies.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell =
      tableView.dequeueReusableCell(withIdentifier: MovieTableViewCell.identifier, for: indexPath)
      as! MovieTableViewCell
    let movie = viewModel.filteredMovies[indexPath.row]
    cell.configure(with: movie)
    return cell
  }
}

// MARK: - UITableViewDelegate
extension MovieSearchViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)

    let movie = viewModel.filteredMovies[indexPath.row]
    let detailViewController = MovieDetailViewController(movie: movie)
    navigationController?.pushViewController(detailViewController, animated: true)
  }
}

// MARK: - UITableViewDataSourcePrefetching
extension MovieSearchViewController: UITableViewDataSourcePrefetching {
  func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    let thresholdIndex = viewModel.filteredMovies.count - 5

    for indexPath in indexPaths {
      if indexPath.row >= thresholdIndex {
        viewModel.loadMoreResults()
        break
      }
    }
  }
}

// MARK: - UISearchResultsUpdating
extension MovieSearchViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    guard let searchText = searchController.searchBar.text else { return }
    viewModel.searchMovies(query: searchText)
  }
}
