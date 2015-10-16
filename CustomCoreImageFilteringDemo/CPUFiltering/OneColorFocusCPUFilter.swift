
//
//  OneColorFocusCPUFilter.swift
//  Custom Grayscale convert
//
//

import UIKit

class OneColorFocusCPUFilter {
    private let redMultiplier = 0.2126 / 255.0
    private let greenMultiplier = 0.7152 / 255.0
    private let blueMultiplier = 0.0722 / 255.0
    
    private let power = 1.0/2.4
    private let cLinearThreshold = 0.0031308
    
    private let focusColorRed: Int
    private let focusColorGreen: Int
    private let focusColorBlue: Int
    private let focusColorThreshold = 70
    
    private let originalImage: UIImage
    
    init(image: UIImage, focusColorRed: Int, focusColorGreen: Int, focusColorBlue: Int) {
        self.originalImage = image
        self.focusColorRed = focusColorRed
        self.focusColorGreen = focusColorGreen
        self.focusColorBlue = focusColorBlue
    }
    
    func createOneColorFocusImage() -> UIImage? {
        return iterateThroughPixels()
    }
    
    private func iterateThroughPixels() -> UIImage? {
        let dataProvider = CGDataProviderCopyData(CGImageGetDataProvider(originalImage.CGImage))
        let data = CFDataGetBytePtr(dataProvider)
        
        let imageDataLength = CFDataGetLength(dataProvider)
        assert(imageDataLength % 4 == 0, "image data doesn't contains proper number of color information")
        
        let newImagePointer = createGreyScaleDataWithData(data, withImageLenght: imageDataLength)
        
        let context = CGBitmapContextCreate(newImagePointer, CGImageGetWidth(originalImage.CGImage), CGImageGetHeight(originalImage.CGImage), 8, CGImageGetWidth(originalImage.CGImage) * 4, CGColorSpaceCreateDeviceRGB(), CGImageAlphaInfo.PremultipliedLast.rawValue)
        var resultImage: UIImage? = nil
        
        if let cgImage = CGBitmapContextCreateImage(context) {
            resultImage = UIImage(CGImage: cgImage)
        }
        
        newImagePointer.dealloc(imageDataLength)
        return resultImage
    }
    
    private func createGreyScaleDataWithData(data: UnsafePointer<UInt8>, withImageLenght imageDataLength: CFIndex) -> UnsafeMutablePointer<UInt8> {
        
        let newImagePointer = UnsafeMutablePointer<UInt8>.alloc(imageDataLength)
        
        for pixelColorInfoStartIndex in 0..<(imageDataLength / 4) {
            let currentPixelRedIndex = pixelColorInfoStartIndex * 4
            let currentPixelGreenIndex = currentPixelRedIndex + 1
            let currentPixelBlueIndex = currentPixelRedIndex + 2
            let currentPixelAlphaIndex = currentPixelRedIndex + 3
            
            let redComponent = data[currentPixelRedIndex]
            let greenComponent = data[currentPixelGreenIndex]
            let blueComponent = data[currentPixelBlueIndex]
            
            let pixelShouldBeInOriginalColor = abs(Int(redComponent) - focusColorRed) < focusColorThreshold && abs(Int(greenComponent) - focusColorGreen) < focusColorThreshold && abs(Int(blueComponent) - focusColorBlue) < focusColorThreshold
            
            if (pixelShouldBeInOriginalColor) {
                newImagePointer[currentPixelRedIndex] = redComponent
                newImagePointer[currentPixelGreenIndex] = greenComponent
                newImagePointer[currentPixelBlueIndex] = blueComponent
                newImagePointer[currentPixelAlphaIndex] = data[currentPixelAlphaIndex]
            } else {
                let greyScale = greyScaleFromRed(redComponent, green: greenComponent, blue: blueComponent)
                newImagePointer[currentPixelRedIndex] = greyScale
                newImagePointer[currentPixelGreenIndex] = greyScale
                newImagePointer[currentPixelBlueIndex] = greyScale
                newImagePointer[currentPixelAlphaIndex] = 255
            }
        }
        return newImagePointer
    }
    
    private func greyScaleFromRed(red: UInt8, green: UInt8, blue: UInt8) -> UInt8 {
        let Y = Double(red) * redMultiplier + Double(green) * greenMultiplier + Double(blue) * blueMultiplier
        let Ysrgb: Double
        
        if Y <= cLinearThreshold {
            Ysrgb = Y * 12.92
        } else {
            Ysrgb = 1.055 * pow(Y, power) - 0.055
        }
        return UInt8(Ysrgb * 255)
    }
}