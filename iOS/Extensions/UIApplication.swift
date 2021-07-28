//
//  UIApplication.swift
//  iOS
//
//  Created by Lucka on 4/7/2021.
//

import UIKit

extension UIApplication {
    @available(iOSApplicationExtension, unavailable)
    var keyRootViewController: UIViewController? {
        return connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows
            .first { $0.isKeyWindow }?
            .rootViewController
    }
}
