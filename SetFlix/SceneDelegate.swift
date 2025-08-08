//
//  SceneDelegate.swift
//  SetFlix
//
//  Created by Manoj on 06/08/2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

  var window: UIWindow?

  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = (scene as? UIWindowScene) else { return }

    // Create window
    window = UIWindow(windowScene: windowScene)

    // Create tab bar controller
    let tabBarController = UITabBarController()

    // Create Movies tab
    let repository = MovieRepositoryFactory.createRepository()
    let moviesViewModel = MovieSearchViewModel(repository: repository)
    let moviesViewController = MovieSearchViewController(viewModel: moviesViewModel)
    let moviesNavigationController = UINavigationController(
      rootViewController: moviesViewController)
    moviesNavigationController.navigationBar.prefersLargeTitles = true
    moviesNavigationController.navigationBar.tintColor = UIColor.systemBlue

    // Configure Movies tab
    moviesNavigationController.tabBarItem = UITabBarItem(
      title: "Movies",
      image: UIImage(systemName: "film"),
      selectedImage: UIImage(systemName: "film.fill")
    )

    // Create Favorites tab
    let favoritesViewController = FavoritesViewController()
    let favoritesNavigationController = UINavigationController(
      rootViewController: favoritesViewController)
    favoritesNavigationController.navigationBar.prefersLargeTitles = true
    favoritesNavigationController.navigationBar.tintColor = UIColor.systemBlue

    // Configure Favorites tab
    favoritesNavigationController.tabBarItem = UITabBarItem(
      title: "Favorites",
      image: UIImage(systemName: "heart"),
      selectedImage: UIImage(systemName: "heart.fill")
    )

    // Set tab bar view controllers
    tabBarController.viewControllers = [moviesNavigationController, favoritesNavigationController]
    tabBarController.tabBar.tintColor = UIColor.systemBlue

    // Set root view controller
    window?.rootViewController = tabBarController
    window?.makeKeyAndVisible()
  }

  func sceneDidDisconnect(_ scene: UIScene) {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
  }

  func sceneWillResignActive(_ scene: UIScene) {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
  }

  func sceneWillEnterForeground(_ scene: UIScene) {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
  }

  func sceneDidEnterBackground(_ scene: UIScene) {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.

    // Save changes in the application's managed object context when the application transitions to the background.
    (UIApplication.shared.delegate as? AppDelegate)?.saveContext()

    // Clean up old cache when app goes to background
    Task {
      let repository = MovieRepositoryFactory.createRepository()
      repository.clearOldCache(olderThan: 7)  // Clear cache older than 7 days
    }
  }

}
