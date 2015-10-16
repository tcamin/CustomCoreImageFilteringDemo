//
//  OneColorFocusNeonFilter.m
//  CustomCoreImageFilteringDemo
//
//  Created by Tomas Camin on 13/10/15.
//  Copyright © 2015 Tomas Camin. All rights reserved.
//

#import "OneColorFocusNeonFilter.h"
#if defined(__ARM_NEON)
    #import "arm_neon.h"
#endif

#define kFocusThreshold 70
#define kGammaLUTSize (int)(255.0 / 0.0722)


@interface OneColorFocusNeonFilter()
{
    uint8_t *gamma24_lut;
}

@property (nonatomic, strong) UIImage *sourceImage;

@end

@implementation OneColorFocusNeonFilter

- (id)initWithImage:(UIImage *)image focusColorRed:(UInt8)focusColorRed focusColorGreen:(UInt8)focusColorGreen focusColorBlue:(UInt8)focusColorBlue;
{
    if ((self = [super init])) {
        self.sourceImage = image;
        
        self.focusColorRed = focusColorRed;
        self.focusColorGreen = focusColorGreen;
        self.focusColorBlue = focusColorBlue;
        
        [self prepareGammaLUT];
    }
    
    return self;
}

- (void)dealloc
{
    free(gamma24_lut);
    gamma24_lut = NULL;
}

- (void)prepareGammaLUT
{
    gamma24_lut = (uint8_t *)malloc(sizeof(uint8_t) * kGammaLUTSize + 1);
    
    for (int i = 0; i < kGammaLUTSize + 1; i++)
    {
        float y = (float)i / kGammaLUTSize;
        
        if (y <= 0.0031308) {
            y = 12.92 * y;
        } else {
            y = 1.055 * powf(y, 1 / 2.4) - 0.055;
        }
        
        gamma24_lut[i] = 255.0 * y;
    }
}

- (UIImage *)createOneColorFocusImage;
{
    NSData *pixelData = (__bridge NSData *)CGDataProviderCopyData(CGImageGetDataProvider(self.sourceImage.CGImage));
    uint8_t *data = (uint8_t *)[pixelData bytes];
    
    CGImageRef imageref = self.sourceImage.CGImage;
    size_t width = CGImageGetWidth(imageref);
    size_t height = CGImageGetHeight(imageref);
    
    size_t bitsPerComponent = 8;
    size_t bytesPerPixel = 4;
    size_t bitsPerPixel = bitsPerComponent * bytesPerPixel;
    size_t bytesPerRow = width * bytesPerPixel;
    size_t byteCount = bytesPerRow * height;
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    #if defined(__ARM_NEON)
        process_pixels_neon_with_lut(data, width * height, self.focusColorRed, self.focusColorGreen, self.focusColorBlue, gamma24_lut);
    #else
        NSLog(@"Neon not supported, using simulator?");
    #endif
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, byteCount, NULL);
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault | kCGImageAlphaLast;
    
    CGImageRef convertedImageRef = CGImageCreate(width, height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpace, bitmapInfo, provider, nil, true, kCGRenderingIntentDefault);
    
    UIImage *modifiedImage = [[UIImage alloc] initWithCGImage:convertedImageRef];
    
    return modifiedImage;
}

#if defined(__ARM_NEON)
static inline void uint8x8_to_float32x4_t(uint8x8_t src, float32x4_t *dst_low, float32x4_t *dst_high)
{
    uint16x8_t dst16 = vmovl_u8(src);
    
    uint32x4_t dst16_low = vmovl_u16(vget_low_u16(dst16));
    uint32x4_t dst16_high = vmovl_u16(vget_high_u16(dst16));
    
    *dst_low = vcvtq_f32_u32(dst16_low);
    *dst_high = vcvtq_f32_u32(dst16_high);
}

static inline void floats32x4_to_uint8x8(float32x4_t src_low, float32x4_t src_high, uint8x8_t *dst)
{
    int16x4_t dst16_low = vmovn_u32(vcvtq_u32_f32(src_low));
    int16x4_t dst16_high = vmovn_u32(vcvtq_u32_f32(src_high));
    
    int16x8_t dst16 = vcombine_u16(dst16_low, dst16_high);
    
    *dst = vmovn_u16(dst16);
}

void process_pixels_neon_with_lut(uint8_t *src, unsigned long numPixels, uint8_t focus_r, uint8_t focus_g, uint8_t focus_b, uint8_t *gamma_lut)
{
    float32x4_t y32_factor_r = vdupq_n_f32(0.2126f);
    float32x4_t y32_factor_g = vdupq_n_f32(0.7152f);
    float32x4_t y32_factor_b = vdupq_n_f32(0.0722f);
    
    uint8x8_t focus8_r = vdup_n_u8(focus_r);
    uint8x8_t focus8_g = vdup_n_u8(focus_g);
    uint8x8_t focus8_b = vdup_n_u8(focus_b);
    
    uint8x8_t fthrsh8 = vdup_n_u8(kFocusThreshold);
    
    unsigned long n = numPixels / 8 + 1;
    
    // Convert per eight pixels
    while (n-- > 0)
    {
        uint8x8x4_t pix  = vld4_u8(src);
        
        uint8x8_t p8_r = pix.val[0];
        uint8x8_t p8_g = pix.val[1];
        uint8x8_t p8_b = pix.val[2];
        
        // check if color should be in original color
        uint8x8_t delta8_r = vabd_u8(p8_r, focus8_r);
        uint8x8_t delta8_g = vabd_u8(p8_g, focus8_g);
        uint8x8_t delta8_b = vabd_u8(p8_b, focus8_b);
        
        uint8x8_t delta8_lt_ft_r = vclt_u8(delta8_r, fthrsh8);
        uint8x8_t delta8_lt_ft_g = vclt_u8(delta8_g, fthrsh8);
        uint8x8_t delta8_lt_ft_b = vclt_u8(delta8_b, fthrsh8);
        
        uint8x8_t keep_color8 = vand_u8(delta8_lt_ft_r, vand_u8(delta8_lt_ft_g, delta8_lt_ft_b));
        uint8x8_t discard_color8 = vmvn_u8(keep_color8);
        
        // split and convert uint8x8 -> 2x float32x4_t
        float32x4_t p32_low_r, p32_low_g, p32_low_b;
        float32x4_t p32_high_r, p32_high_g, p32_high_b;
        
        uint8x8_to_float32x4_t(p8_r, &p32_low_r, &p32_high_r);
        uint8x8_to_float32x4_t(p8_g, &p32_low_g, &p32_high_g);
        uint8x8_to_float32x4_t(p8_b, &p32_low_b, &p32_high_b);
        
        // calculate Y
        float32x4_t temp_y32_low_r = vmulq_f32(p32_low_r, y32_factor_r);
        float32x4_t temp_y32_low_g = vmulq_f32(p32_low_g, y32_factor_g);
        float32x4_t temp_y32_low_b = vmulq_f32(p32_low_b, y32_factor_b);
        
        float32x4_t y32_low = vaddq_f32(temp_y32_low_r, vaddq_f32(temp_y32_low_g, temp_y32_low_b));
        
        float32x4_t temp_y32_high_r = vmulq_f32(p32_high_r, y32_factor_r);
        float32x4_t temp_y32_high_g = vmulq_f32(p32_high_g, y32_factor_g);
        float32x4_t temp_y32_high_b = vmulq_f32(p32_high_b, y32_factor_b);
        
        float32x4_t y32_high = vaddq_f32(temp_y32_high_r, vaddq_f32(temp_y32_high_g, temp_y32_high_b));
        
        // gamma correction using lut.
        for (int j = 0; j < 4; j++)
        {
            y32_low[j] = gamma_lut[(int)(y32_low[j] * kGammaLUTSize / 255.0)];
            y32_high[j] = gamma_lut[(int)(y32_high[j] * kGammaLUTSize / 255.0)];
        }
        
        // convert back to int and merge
        uint8x8_t y8;
        floats32x4_to_uint8x8(y32_low, y32_high, &y8);
        
        // merge grayscale + original rgba
        uint8x8_t pix_grayscale = vand_u8(y8, discard_color8);

        pix.val[0] = vadd_u8(vand_u8(p8_r, keep_color8), pix_grayscale);
        pix.val[1] = vadd_u8(vand_u8(p8_g, keep_color8), pix_grayscale);
        pix.val[2] = vadd_u8(vand_u8(p8_b, keep_color8), pix_grayscale);

        vst4_u8(src, pix);
        
        src += 8 * 4;
    }
}
#endif

@end
