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

  @IBOutlet var processedImage: UIImageView!

  var request: VNCoreMLRequest?
  var visionModel: VNCoreMLModel?
  var original: UIImage?

  let segmentationModel: DeepLabV3 = {
    do {
      let config = MLModelConfiguration()
      return try DeepLabV3(configuration: config)
    } catch {
      print("Error loading model: \(error)")
      abort()
    }
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    self.original = UIImage(named:"IMG_1090")!
    originalImage.image = original


    if let visionModel = try? VNCoreMLModel(for: segmentationModel.model) {
               self.visionModel = visionModel
               request = VNCoreMLRequest(model: visionModel, completionHandler: visionRequestDidComplete)
               request?.imageCropAndScaleOption = .centerCrop
           } else {
               fatalError()
           }

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

     func visionRequestDidComplete(request: VNRequest, error: Error?) {
         if let observations = request.results as? [VNCoreMLFeatureValueObservation],
             let segmentationmap = observations.first?.featureValue.multiArrayValue {

           let metadata = segmentationModel.model.modelDescription.metadata[MLModelMetadataKey.creatorDefinedKey]
           if let metadata = metadata as? Dictionary<String, Any>, let annotationString = metadata["com.apple.coreml.model.preview.params"] as? String  {

             let annotations = try! JSONDecoder().decode(Annotations.self, from: Data(annotationString.utf8) )
             self.processedImage.colorsAndTags = annotations
           }

           let maskImage = segmentationmap.image(min: 0, max: 1)
             processedImage.segmentationmap = SegmentationResultMLMultiArray(mlMultiArray: segmentationmap)
           
           DispatchQueue.main.async {
             self.processedImage = maskImage.resizeImageTo(size: original?.size ?? .zero)
           }
         }
     }

}

class SegmentationResultMLMultiArray {
    let mlMultiArray: MLMultiArray
    let segmentationmapWidthSize: Int
    let segmentationmapHeightSize: Int

    init(mlMultiArray: MLMultiArray) {
        self.mlMultiArray = mlMultiArray
        self.segmentationmapWidthSize = mlMultiArray.shape[0].intValue
        self.segmentationmapHeightSize = mlMultiArray.shape[1].intValue
    }

    subscript(colunmIndex: Int, rowIndex: Int) -> NSNumber {
        let index = colunmIndex*(segmentationmapHeightSize) + rowIndex
        return mlMultiArray[index]
    }
}


extension CGImage {
    func resize(size:CGSize) -> CGImage? {
        let width: Int = Int(size.width)
        let height: Int = Int(size.height)

        let bytesPerPixel = self.bitsPerPixel / self.bitsPerComponent
        let destBytesPerRow = width * bytesPerPixel


        guard let colorSpace = self.colorSpace else { return nil }
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: self.bitsPerComponent, bytesPerRow: destBytesPerRow, space: colorSpace, bitmapInfo: self.alphaInfo.rawValue) else { return nil }

        context.interpolationQuality = .high
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))

        return context.makeImage()
    }
}

extension UIImage {

    func resizeImageTo(size: CGSize) -> UIImage? {

        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        self.draw(in: CGRect(origin: CGPoint.zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return resizedImage
    }
}
