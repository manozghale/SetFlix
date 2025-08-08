//
//  MovieSearchViewController.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import Combine
import UIKit

class MovieSearchViewController: UIViewController, UISearchBarDelegate {

  // MARK: - UI Components
  private lazy var searchController: UISearchController = {
    let controller = UISearchController(searchResultsController: nil)
    controller.searchResultsUpdater = self
    controller.obscuresBackgroundDuringPresentation = false
    controller.searchBar.placeholder = "Search movies..."
    controller.searchBar.tintColor = .systemBlue
    controller.searchBar.delegate = self
    controller.searchBar.isUserInteractionEnabled = true
    controller.searchBar.autocorrectionType = .no
    controller.searchBar.autocapitalizationType = .none
    controller.searchBar.returnKeyType = .search
    controller.searchBar.enablesReturnKeyAutomatically = false
    controller.definesPresentationContext = true
    
    // Configure clear button
    controller.searchBar.showsBookmarkButton = false
    controller.searchBar.showsCancelButton = false
    
    // Ensure clear button is properly configured
    controller.searchBar.searchTextField.clearButtonMode = .whileEditing
    
    return controller
  }()
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

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    // Refresh favorite status when returning from detail view
    viewModel.refreshFavoriteStatus()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    // Ensure search controller is properly configured after view appears
    if searchController.searchBar.delegate == nil {
      searchController.searchBar.delegate = self
    }
    // Ensure search controller is properly configured
    if searchController.searchResultsUpdater == nil {
      searchController.searchResultsUpdater = self
    }
  }

  // MARK: - UI Setup
  private func setupUI() {
    view.backgroundColor = .systemBackground

    // Navigation bar setup
    title = "Movies"
    navigationController?.navigationBar.prefersLargeTitles = true

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
    // Add search bar to navigation bar
    navigationItem.searchController = searchController
    navigationItem.hidesSearchBarWhenScrolling = false
    
    // Set presentation context to prevent crashes
    definesPresentationContext = true
    searchController.definesPresentationContext = true
    
    // Ensure search controller is properly configured
    searchController.isActive = false
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

    // Bind network status
    viewModel.$isOnline
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isOnline in
        self?.updateNetworkStatus(isOnline: isOnline)
      }
      .store(in: &cancellables)

    // Add cache status indicator
    viewModel.$isLoading
      .combineLatest(viewModel.$filteredMovies, viewModel.$isOnline)
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isLoading, movies, isOnline in
        if !isLoading && !movies.isEmpty {
          self?.showCacheIndicator(isOnline: isOnline)
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

  private func updateNetworkStatus(isOnline: Bool) {
    if isOnline {
      // Remove offline indicator
      navigationItem.titleView = nil
      print("📱 UI: Network status updated - Online")
    } else {
      // Show offline indicator
      let offlineLabel = UILabel()
      offlineLabel.text = "📱 Offline Mode"
      offlineLabel.textAlignment = .center
      offlineLabel.backgroundColor = .systemYellow.withAlphaComponent(0.8)
      offlineLabel.textColor = .black
      offlineLabel.font = .systemFont(ofSize: 12)
      offlineLabel.layer.cornerRadius = 4
      offlineLabel.clipsToBounds = true
      offlineLabel.sizeToFit()

      // Add padding
      offlineLabel.frame = CGRect(
        x: 0, y: 0,
        width: offlineLabel.frame.width + 16,
        height: offlineLabel.frame.height + 8
      )

      navigationItem.titleView = offlineLabel
      print("📱 UI: Network status updated - Offline")
    }
  }

  private func showError(_ message: String) {
    let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }

  private func showCacheIndicator(isOnline: Bool) {
    if !isOnline {
      // Show offline indicator with specific message
      let offlineLabel = UILabel()

      if viewModel.isShowingCachedSearchResults {
        offlineLabel.text = "📱 Offline Mode - Showing cached search results"
      } else {
        offlineLabel.text = "📱 Offline Mode - Showing cached popular movies"
      }

      offlineLabel.textAlignment = .center
      offlineLabel.backgroundColor = .systemYellow.withAlphaComponent(0.8)
      offlineLabel.textColor = .black
      offlineLabel.font = .systemFont(ofSize: 12)
      offlineLabel.layer.cornerRadius = 4
      offlineLabel.clipsToBounds = true
      offlineLabel.sizeToFit()

      // Add padding
      offlineLabel.frame = CGRect(
        x: 0, y: 0,
        width: offlineLabel.frame.width + 16,
        height: offlineLabel.frame.height + 8
      )

      // Add to navigation bar
      navigationItem.titleView = offlineLabel
    } else {
      navigationItem.titleView = nil
    }
  }

  // MARK: - Actions
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
        viewModel.loadMoreMovies()
        break
      }
    }
  }
}

// MARK: - UISearchResultsUpdating
extension MovieSearchViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    // This method is called by UISearchController when search results need updating
    // The actual search is handled by UISearchBarDelegate methods
    // This method is kept for compatibility but the search logic is in searchBar(_:textDidChange:)
  }
}

// MARK: - UISearchBarDelegate
extension MovieSearchViewController {
  func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
    // This ensures immediate search as user types
    if searchText.isEmpty {
      // Handle clear button action
      handleSearchBarClear()
    } else {
      viewModel.searchMovies(query: searchText)
    }
  }
  
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    // Handle search button tap
    guard let searchText = searchBar.text else { return }
    viewModel.searchMovies(query: searchText)
    searchController.dismiss(animated: true)
  }
  
  func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
    // Clear search and show popular movies
    searchBar.text = ""
    searchBar.resignFirstResponder()
    searchController.dismiss(animated: true)
    viewModel.clearSearchState()
  }
  
  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    // Show cancel button when editing begins
    searchBar.showsCancelButton = true
  }
  
  func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    // Hide cancel button when editing ends
    searchBar.showsCancelButton = false
  }
  
  func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
    // Ensure search bar can begin editing
    return true
  }
  
  func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
    // Allow search bar to end editing
    return true
  }
  
  func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    // Handle text changes including clear button
    let currentText = searchBar.text ?? ""
    guard let textRange = Range(range, in: currentText) else { return true }
    
    let updatedText = currentText.replacingCharacters(in: textRange, with: text)
    
    // If the text is being cleared (likely by clear button), handle it properly
    if updatedText.isEmpty {
      DispatchQueue.main.async {
        self.handleSearchBarClear()
      }
    }
    
    return true
  }
  
  // MARK: - Private Helper Methods
  private func handleSearchBarClear() {
    // Safely handle search bar clear action
    DispatchQueue.main.async {
      self.viewModel.clearSearchState()
    }
  }
}
