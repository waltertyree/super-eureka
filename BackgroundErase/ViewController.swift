//
//  ViewController.swift
//  BackgroundErase
//
//  Created by Walter Tyree on 6/7/22.
//

import UIKit
import CoreImage
import Vision

class ViewController: UIViewController {
  @IBOutlet var originalImage: UIImageView!

  @IBOutlet var processedImage: DrawingSegmentationView!
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    let original = UIImage(named:"IMG_1090")
    originalImage.image = original


    //resize to what the model wants
    let modelInputSize = CGSize(width: 513, height: 513)
    let resizedImage = original?.resized(to: modelInputSize)


     let modelInputImage = CIImage(cgImage: (resizedImage?.cgImage)!)
    var modelPixelBuffer: CVPixelBuffer? = nil
    let colorSpace = CGColorSpaceCreateDeviceRGB()

    CVPixelBufferCreate(kCFAllocatorDefault, Int(modelInputSize.width), Int(modelInputSize.height), kCVPixelFormatType_32BGRA, nil, &modelPixelBuffer)

    let context = CIContext()
    guard let modelPixelBuffer = modelPixelBuffer else {
      abort()
    }


    context.render(modelInputImage, to: modelPixelBuffer, bounds: CGRect(origin: CGPoint(x: 0, y: 0), size: modelInputSize), colorSpace: colorSpace)

    let model = getDeepLabV3Model()
    let outputMaskImage = try? model?.prediction(image: modelPixelBuffer)
    let outputImage = outputMaskImage?.semanticPredictions.image(min: 0, max: 1, axes: (0,0,1))

    processedImage.image = outputImage?.resized(to: original!.size)


  }

  private func getDeepLabV3Model() -> DeepLabV3? {
      do {
          let config = MLModelConfiguration()
          return try DeepLabV3(configuration: config)
      } catch {
          print("Error loading model: \(error)")
          return nil
      }
  }

}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
