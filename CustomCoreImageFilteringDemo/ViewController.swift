//
//  ViewController.swift
//  CustomCoreImageFilteringDemo
//
//  Created by Xcode on 12/10/15.
//  Copyright © 2015 Tomas Camin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var benchResult: UILabel!
    
    var sourceImage: UIImage! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        OneColorFocusCoreImageFilter.preload()
    }
    
    private func prepareSourceImage() {
        sourceImage = UIImage(named: "tstimage-large.jpg")!
    }
    
    @IBAction func runCPUTapped(sender: AnyObject) {
        prepareSourceImage()
        
        var elapsedTime = CFAbsoluteTimeGetCurrent()
        
        let filter = OneColorFocusCPUFilter(image: sourceImage, focusColorRed: 10, focusColorGreen: 10, focusColorBlue: 10)
        let filteredImage = filter.createOneColorFocusImage()!
        
        self.resultImageView.image = filteredImage
        
        elapsedTime = (CFAbsoluteTimeGetCurrent() - elapsedTime) * 1000.0
        
        self.benchResult.text = String(format: "CPU: %.3fms", elapsedTime)
        
        print(self.benchResult.text!)
    }
    
    @IBAction func runCoreImageTapped(sender: AnyObject) {
        prepareSourceImage()
        
        var elapsedTime = CFAbsoluteTimeGetCurrent()
        
        let filter = OneColorFocusCoreImageFilter(image: sourceImage, focusColorRed: 10, focusColorGreen: 10, focusColorBlue: 10)
        let filteredImage = filter.outputUIImage()
        
        self.resultImageView.image = filteredImage
        
        elapsedTime = (CFAbsoluteTimeGetCurrent() - elapsedTime) * 1000.0
        
        self.benchResult.text = String(format: "CoreImage: %.3fms", elapsedTime)
        
        print(self.benchResult.text!)
    }
    
    @IBAction func runNeonTapped(sender: AnyObject) {
        prepareSourceImage()
        
        var elapsedTime = CFAbsoluteTimeGetCurrent()
        
        let filter = OneColorFocusNeonFilter(image: sourceImage, focusColorRed: 10, focusColorGreen: 10, focusColorBlue: 10)
        let filteredImage = filter.createOneColorFocusImage()
        
        self.resultImageView.image = filteredImage
        
        elapsedTime = (CFAbsoluteTimeGetCurrent() - elapsedTime) * 1000.0
        
        self.benchResult.text = String(format: "Neon: %.3fms", elapsedTime)
        
        print(self.benchResult.text!)
    }
}

