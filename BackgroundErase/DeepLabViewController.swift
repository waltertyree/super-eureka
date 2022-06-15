//
//  DeepLabViewController.swift
//  BackgroundErase
//
//  Created by Walter Tyree on 6/7/22.
//

import OSLog
import UIKit
import CoreImage
import Vision

class DeepLabViewController: UIViewController {
  @IBOutlet var originalImage: UIImageView!


  var request: VNCoreMLRequest?
  var visionModel: VNCoreMLModel?
  var original: UIImage?

  let segmentationModel: DeepLabV3 = {
    do {
      let config = MLModelConfiguration()
      return try DeepLabV3(configuration: config)
    } catch {
      Logger().error("Error loading model.")
      abort()
    }
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    self.original = UIImage(named:"IMG_2705")!


    if let visionModel = try? VNCoreMLModel(for: segmentationModel.model) {
      self.visionModel = visionModel
      request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
      request?.imageCropAndScaleOption = .scaleFill
    } else {
      Logger().error("Could not create request.")
      abort()
    }

  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    originalImage.image = original

  }
  @IBAction func applyFilter(_ sender: Any) {
    Logger().info("Start: \(Date(), privacy: .public)")
    predict(with: original?.cgImage)
  }

  func predict(with cgImage: CGImage?) {
    guard let request = request else { fatalError() }
    guard let cgImage = cgImage else {
      return
    }

    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
    try? handler.perform([request])
  }

  fileprivate func applyBackgroundMask(_ image: UIImage) {
    let mainImage = CIImage(cgImage: self.original!.cgImage!)
    let originalSize = mainImage.extent.size


    let maskUIImage = image.resized(to: originalSize)

    var maskImage = CIImage(cgImage: maskUIImage.cgImage!)

    DispatchQueue.main.async {

      // Scale the mask image to fit the bounds of the video frame.
      maskImage = maskImage.applyingGaussianBlur(sigma: 3.0)

      let backgroundUIImage = UIImage(named: "starfield")!.resized(to: originalSize)
      let background = CIImage(cgImage: backgroundUIImage.cgImage!)

      let filter = CIFilter(name: "CIBlendWithMask")
      filter?.setValue(background, forKey: kCIInputBackgroundImageKey)
      filter?.setValue(mainImage, forKey: kCIInputImageKey)
      filter?.setValue(maskImage, forKey: kCIInputMaskImageKey)

      self.originalImage.image = UIImage(ciImage: filter!.outputImage!)
      Logger().info("Done: \(Date(), privacy: .public)")

    }
  }

  func visionRequestDidComplete(request: VNRequest, error: Error?) {
    if let observations = request.results as? [VNCoreMLFeatureValueObservation],
       let segmentationmap = observations.first?.featureValue.multiArrayValue {

      guard let maskUIImage = segmentationmap.image(min: 0.0, max: 1.0) else { return }

      applyBackgroundMask(maskUIImage)
    }
  }

}
