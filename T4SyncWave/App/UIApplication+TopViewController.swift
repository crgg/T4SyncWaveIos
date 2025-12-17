//
//  UIApplication+TopViewController.swift
//  T4SyncWave
//
//  Created by Ramon Gajardo on 12/15/25.
//

 
import UIKit

extension UIApplication {
    func topViewController(
        base: UIViewController? = nil
    ) -> UIViewController? {

        let baseVC = base ??
            connectedScenes
                .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                .first?.rootViewController

        if let nav = baseVC as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }

        if let tab = baseVC as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }

        if let presented = baseVC?.presentedViewController {
            return topViewController(base: presented)
        }

        return baseVC
    }
}
