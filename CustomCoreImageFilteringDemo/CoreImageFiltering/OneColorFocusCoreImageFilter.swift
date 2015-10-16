//
//  OneColorFocusCoreImageFilter.swift
//  CustomCoreImageFilteringDemo
//
//  Created by Tomas Camin on 08/10/15.
//  Copyright © 2015 Tomas Camin. All rights reserved.
//

import UIKit

class OneColorFocusCoreImageFilter: CIFilter {
    private static var kernel: CIColorKernel?
    private static var context: CIContext?

    private var _inputImage: CIImage?
    private var inputImage: CIImage? {
        get { return _inputImage }
        set { _inputImage = newValue }
    }
    private var focusColor: CIColor?
    
    init(image: UIImage, focusColorRed: Int, focusColorGreen: Int, focusColorBlue: Int) {
        super.init()
        
        OneColorFocusCoreImageFilter.preload()
        inputImage = CIImage(image: image)
        focusColor = CIColor(red: CGFloat(focusColorRed) / 255.0, green: CGFloat(focusColorGreen) / 255.0, blue: CGFloat(focusColorBlue) / 255.0)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        OneColorFocusCoreImageFilter.preload()
    }
    
    override var outputImage : CIImage! {
        if  let inputImage = inputImage,
            let kernel = OneColorFocusCoreImageFilter.kernel,
            let fc = focusColor {
                return kernel.applyWithExtent(inputImage.extent, roiCallback: { (_, _) -> CGRect in return inputImage.extent  }, arguments: [inputImage, fc]) // to support iOS8
                // return kernel.applyWithExtent(inputImage.extent, arguments: [inputImage, fc.red, fc.green, fc.blue]) // iOS9 and newer
        }
        return nil
    }
    
    func outputUIImage() -> UIImage {
        let ciimage = self.outputImage
        
        return UIImage(CGImage: OneColorFocusCoreImageFilter.context!.createCGImage(ciimage, fromRect: ciimage.extent))
    }
    
    private class func createKernel() -> CIColorKernel {
        let kernelString = try! String(contentsOfFile: NSBundle.mainBundle().pathForResource("OneColorFocusCoreImageFilter", ofType: "cikernel")!, encoding: NSUTF8StringEncoding)
        
        return CIColorKernel(string: kernelString)!
    }
    
    class func preload() {
        // preloading kernel speeds up first execution of filter
        if kernel != nil {
            return
        }
        kernel = createKernel()
        context = CIContext(options: [kCIContextWorkingColorSpace: NSNull()])
    }
}