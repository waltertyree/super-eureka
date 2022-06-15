//
//  VisionViewController.swift
//  BackgroundErase
//
//  Created by Walter Tyree on 6/14/22.
//

import UIKit
import OSLog
import Vision
import CoreImage

class VisionViewController: UIViewController {

  private var segmentationRequest: VNGeneratePersonSegmentationRequest?

  @IBOutlet var originalImageView: UIImageView!
  var originalImage: UIImage?
  var cropRect: CGRect?

  override func viewDidLoad() {
    super.viewDidLoad()
    originalImage = UIImage(named: "masked")!

    segmentationRequest = VNGeneratePersonSegmentationRequest()
    segmentationRequest?.qualityLevel = .balanced
    segmentationRequest?.outputPixelFormat = kCVPixelFormatType_OneComponent8
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    originalImageView.image = originalImage
  }

  fileprivate func applyBackgroundMask(_ maskImage: CGImage?) {
    let mainImage = CIImage(cgImage: self.originalImage!.cgImage!)
    let originalSize = mainImage.extent.size



    var maskCI = CIImage(cgImage: maskImage!)
    let scaleX = originalSize.width / maskCI.extent.width
    let scaleY = originalSize.height / maskCI.extent.height
    maskCI = maskCI.transformed(by: .init(scaleX: scaleX, y: scaleY))


    DispatchQueue.main.async {


      let backgroundUIImage = UIImage(named: "starfield")!.resized(to: originalSize)
      let background = CIImage(cgImage: backgroundUIImage.cgImage!)

      let filter = CIFilter(name: "CIBlendWithMask")
      filter?.setValue(background, forKey: kCIInputBackgroundImageKey)
      filter?.setValue(mainImage, forKey: kCIInputImageKey)
      filter?.setValue(maskCI, forKey: kCIInputMaskImageKey)


      self.originalImageView.image = UIImage(ciImage: filter!.outputImage!)
      Logger().info("Done: \(Date(), privacy: .public)")

    }
  }


  @IBAction func applyFilter(_ sender: Any) {
    guard let originalCG = originalImage?.cgImage, let segmentationRequest = self.segmentationRequest else { abort() }
    Logger().info("Start: \(Date(), privacy: .public)")

    let handler = VNImageRequestHandler(cgImage: originalCG)

    try? handler.perform([segmentationRequest])

    guard let maskPixelBuffer =
            segmentationRequest.results?.first?.pixelBuffer else { return }

    let maskImage = CGImage.create(pixelBuffer: maskPixelBuffer)


    applyBackgroundMask(maskImage)
  }
}
