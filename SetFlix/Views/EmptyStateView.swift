//
//  EmptyStateView.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import UIKit

class EmptyStateView: UIView {

  // MARK: - UI Components
  private let imageView = UIImageView()
  private let titleLabel = UILabel()
  private let messageLabel = UILabel()
  private let stackView = UIStackView()

  // MARK: - Initialization
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
    setupConstraints()
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - UI Setup
  private func setupUI() {
    // Configure image view
    imageView.contentMode = .scaleAspectFit
    imageView.tintColor = .systemGray3
    imageView.translatesAutoresizingMaskIntoConstraints = false

    // Configure title label
    titleLabel.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
    titleLabel.textColor = .label
    titleLabel.textAlignment = .center
    titleLabel.numberOfLines = 0
    titleLabel.translatesAutoresizingMaskIntoConstraints = false

    // Configure message label
    messageLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
    messageLabel.textColor = .secondaryLabel
    messageLabel.textAlignment = .center
    messageLabel.numberOfLines = 0
    messageLabel.translatesAutoresizingMaskIntoConstraints = false

    // Configure stack view
    stackView.axis = .vertical
    stackView.spacing = 16
    stackView.alignment = .center
    stackView.distribution = .fill
    stackView.translatesAutoresizingMaskIntoConstraints = false

    // Add subviews to stack view
    stackView.addArrangedSubview(imageView)
    stackView.addArrangedSubview(titleLabel)
    stackView.addArrangedSubview(messageLabel)

    // Add stack view to main view
    addSubview(stackView)

    // Configure main view
    backgroundColor = .clear
  }

  private func setupConstraints() {
    NSLayoutConstraint.activate([
      // Stack view constraints
      stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
      stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20),

      // Image view constraints
      imageView.widthAnchor.constraint(equalToConstant: 80),
      imageView.heightAnchor.constraint(equalToConstant: 80),
    ])
  }

  // MARK: - Configuration
  func configure(title: String, message: String, imageName: String) {
    titleLabel.text = title
    messageLabel.text = message

    if let image = UIImage(systemName: imageName) {
      imageView.image = image
    } else {
      imageView.image = UIImage(systemName: "questionmark.circle")
    }
  }
}
