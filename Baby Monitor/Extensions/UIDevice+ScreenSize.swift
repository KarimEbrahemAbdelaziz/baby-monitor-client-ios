//
//  UIDevice+ScreenSize.swift
//  Baby Monitor
//

import UIKit

extension UIDevice {

    /// Indicates if screen size of the device is bigger than 4 inches
    static var screenSizeBiggerThan4Inches: Bool {
        return UIScreen.main.bounds.height > 568
    }
}
