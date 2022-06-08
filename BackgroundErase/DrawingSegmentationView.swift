//
//  DrawingSegmentationView.swift
//  BackgroundErase
//
//  Created by Walter Tyree on 6/7/22.
//

import UIKit

class DrawingSegmentationView: UIView {

  var colorsAndTags: Annotations?

     func segmentationColor(with index: Int32) -> UIColor {
       if index != 0 {
         print(colorsAndTags?.labels?[Int(index)] ?? "--")
       }
       if let colorToReturn = colorsAndTags?.color(Int(index))  {
         return colorToReturn

       }
       return .purple
     }

     var segmentationmap: SegmentationResultMLMultiArray? = nil {
         didSet {
             self.setNeedsDisplay()
         }
     }

     override func draw(_ rect: CGRect) {

         if let ctx = UIGraphicsGetCurrentContext() {

             ctx.clear(rect);

             guard let segmentationmap = self.segmentationmap else { return }

             let size = self.bounds.size
             let segmentationmapWidthSize = segmentationmap.segmentationmapWidthSize
             let segmentationmapHeightSize = segmentationmap.segmentationmapHeightSize
             let w = size.width / CGFloat(segmentationmapWidthSize)
             let h = size.height / CGFloat(segmentationmapHeightSize)

             for j in 0..<segmentationmapHeightSize {
                 for i in 0..<segmentationmapWidthSize {
                     let value = segmentationmap[j, i].int32Value

                     let rect: CGRect = CGRect(x: CGFloat(i) * w, y: CGFloat(j) * h, width: w, height: h)

                     let color: UIColor = segmentationColor(with: value)

                     color.setFill()
                     UIRectFill(rect)
                 }
             }
         }
     } // end of draw(rect:)

}
