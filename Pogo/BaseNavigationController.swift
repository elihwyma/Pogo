//
//  BaseNavigationController.swift
//  Shimmer
//
//  Created by Amy While on 16/07/2022.
//

import UIKit

class BaseNavigationController: UINavigationController {
    
    static let boldConfig = UIImage.SymbolConfiguration(pointSize: 25, weight: .semibold)
    static let backImage = UIImage(systemName: "arrow.backward", withConfiguration: boldConfig)!
    static let forwardImage = UIImage(systemName: "arrow.forward", withConfiguration: boldConfig)!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(image: Self.backImage, style: .plain, target: nil, action: nil)
    }
  
}
