//
//  DeepLabV3Helpers.swift
//  BackgroundErase
//
//  Created by Walter Tyree on 6/8/22.
//

import Foundation
import UIKit

struct Annotations: Decodable {
  var labels: [String]?
  var colors: [String]?

  func color(_ index: Int) -> UIColor {
    guard let colorEntry = colors?[index] else {
      return .black
    }
    let splitHex = colorEntry.split(separator: "x")
    guard let hexint = Int(splitHex[1]) else { return .purple }
    let red = CGFloat((hexint & 0xff000000) >> 32) / 255.0
    let green = CGFloat((hexint & 0xff0000) >> 16) / 255.0
    let blue = CGFloat((hexint & 0xff00) >> 8) / 255.0
    var alpha = CGFloat((hexint & 0xff) >> 0) / 255.0
    if red != 0.0 && green != 0.0 && blue != 0.0 {
      alpha = 0.2
    }
    // Create color object, specifying alpha as well
    let color = UIColor(red: red, green: green, blue: blue, alpha: alpha)
    if color == .init(red: 0, green: 0, blue: 0, alpha: 0) {
      return color.withAlphaComponent(0.1)
    }
    return color
  }
}
