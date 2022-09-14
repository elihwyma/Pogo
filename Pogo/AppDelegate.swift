//
//  AppDelegate.swift
//  Pogo
//
//  Created by Amy While on 12/09/2022.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = BaseNavigationController(rootViewController: ViewController(nibName: nil, bundle: nil))
        self.window?.makeKeyAndVisible()
        
        return true
    }

}

