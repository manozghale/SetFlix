//
//  FavoritesViewController.swift
//  SetFlix
//
//  Created by Manoj on 08/08/2025.
//

import Combine
import UIKit

class FavoritesViewController: UIViewController {

  // MARK: - UI Components
  private let tableView = UITableView()
  private let emptyStateLabel = UILabel()
  private let refreshControl = UIRefreshControl()

  // MARK: - ViewModel
  private var viewModel: FavoritesViewModel!
  private var cancellables = Set<AnyCancellable>()

  // MARK: - Initialization
  init() {
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Lifecycle
  override func viewDidLoad() {
    super.viewDidLoad()
    viewModel = FavoritesViewModel()
    setupUI()
    setupConstraints()
    setupBindings()
    viewModel.loadFavorites()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    viewModel.loadFavorites()
  }

  // MARK: - UI Setup
  private func setupUI() {
    view.backgroundColor = .systemBackground
    title = "Favorites"
    navigationItem.largeTitleDisplayMode = .always

    // Add subviews
    view.addSubview(tableView)
    view.addSubview(emptyStateLabel)

    // Configure table view
    tableView.delegate = self
    tableView.dataSource = self
    tableView.register(MovieTableViewCell.self, forCellReuseIdentifier: "MovieCell")
    tableView.separatorStyle = .none
    tableView.backgroundColor = .systemBackground

    // Configure refresh control
    refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    tableView.refreshControl = refreshControl

    // Configure empty state label
    emptyStateLabel.text = "No favorite movies yet"
    emptyStateLabel.textAlignment = .center
    emptyStateLabel.textColor = .secondaryLabel
    emptyStateLabel.font = .systemFont(ofSize: 18, weight: .medium)
    emptyStateLabel.numberOfLines = 0
    emptyStateLabel.isHidden = true
  }

  private func setupConstraints() {
    tableView.translatesAutoresizingMaskIntoConstraints = false
    emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      // Table view constraints
      tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

      // Empty state label constraints
      emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      emptyStateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
      emptyStateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
    ])
  }

  private func setupBindings() {
    // Bind movies to UI
    viewModel.$movies
      .receive(on: DispatchQueue.main)
      .sink { [weak self] movies in
        self?.tableView.reloadData()
        self?.updateEmptyState(movies.isEmpty)
      }
      .store(in: &cancellables)

    // Bind loading state
    viewModel.$isLoading
      .receive(on: DispatchQueue.main)
      .sink { [weak self] isLoading in
        if !isLoading {
          self?.refreshControl.endRefreshing()
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
  }

  private func updateEmptyState(_ isEmpty: Bool) {
    emptyStateLabel.isHidden = !isEmpty
    tableView.isHidden = isEmpty
  }

  private func showError(_ message: String) {
    let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
  }

  // MARK: - Actions
  @objc private func refreshData() {
    viewModel.loadFavorites()
  }
}

// MARK: - UITableViewDataSource
extension FavoritesViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return viewModel.movies.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell =
      tableView.dequeueReusableCell(withIdentifier: "MovieCell", for: indexPath)
      as! MovieTableViewCell
    let movie = viewModel.movies[indexPath.row]
    cell.configure(with: movie)
    return cell
  }
}

// MARK: - UITableViewDelegate
extension FavoritesViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    tableView.deselectRow(at: indexPath, animated: true)

    let movie = viewModel.movies[indexPath.row]
    let detailViewController = MovieDetailViewController(movie: movie)
    navigationController?.pushViewController(detailViewController, animated: true)
  }

  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 120
  }

  // MARK: - Swipe to Delete
  func tableView(
    _ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
    forRowAt indexPath: IndexPath
  ) {
    if editingStyle == .delete {
      let movie = viewModel.movies[indexPath.row]
      viewModel.removeFromFavorites(movie)
    }
  }

  func tableView(
    _ tableView: UITableView, titleForDeleteConfirmationButtonForRowAt indexPath: IndexPath
  ) -> String? {
    return "Remove"
  }
}
