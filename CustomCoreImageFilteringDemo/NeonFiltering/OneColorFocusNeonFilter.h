//
//  OneColorFocusNeonFilter.h
//  CustomCoreImageFilteringDemo
//
//  Created by Tomas Camin on 13/10/15.
//  Copyright © 2015 Tomas Camin. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface OneColorFocusNeonFilter : NSObject

- (id)initWithImage:(UIImage *)image focusColorRed:(UInt8)focusColorRed focusColorGreen:(UInt8)focusColorGreen focusColorBlue:(UInt8)focusColorBlue;
- (UIImage *)createOneColorFocusImage;

@property (nonatomic, assign) UInt8 focusColorRed;
@property (nonatomic, assign) UInt8 focusColorGreen;
@property (nonatomic, assign) UInt8 focusColorBlue;

@end
