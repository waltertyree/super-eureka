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
  private var faceCropRequest: VNDetectFaceRectanglesRequest?

  @IBOutlet var originalImageView: UIImageView!
  var originalImage: UIImage?
  var cropRect: CGRect?

  override func viewDidLoad() {
    super.viewDidLoad()
    originalImage = UIImage(named: "masked")!

    faceCropRequest = VNDetectFaceRectanglesRequest()
    segmentationRequest = VNGeneratePersonSegmentationRequest(completionHandler: visionRequestDidComplete)
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

      // Scale the mask image to fit the bounds of the video frame.
      let context = CIContext(options: [CIContextOption.useSoftwareRenderer: false])

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

  func visionRequestDidComplete(request: VNRequest, error: Error?) {
    guard let request = request as? VNGeneratePersonSegmentationRequest else { abort() }
    guard let maskPixelBuffer =
            request.results?.first?.pixelBuffer else { return }

    let maskImage = CGImage.create(pixelBuffer: maskPixelBuffer)


    applyBackgroundMask(maskImage)
  }
  
  @IBAction func applyFilter(_ sender: Any) {
    guard let originalCG = originalImage?.cgImage, let segmentationRequest = self.segmentationRequest, let faceCropRequest = self.faceCropRequest else { abort() }
    Logger().info("Start: \(Date(), privacy: .public)")

    let handler = VNImageRequestHandler(cgImage: originalCG)

    try? handler.perform([segmentationRequest, faceCropRequest])

    if let faceRect = faceCropRequest.results?.first as? VNFaceObservation {
      self.cropRect = faceRect.boundingBox
    }
  }
}
