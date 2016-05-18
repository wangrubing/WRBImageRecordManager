//
//  ImageRecordManager.h
//  Face++Demo
//
//  Created by 王茹冰 on 16/2/26.
//  Copyright © 2016年 王茹冰. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface WRBImageRecordManager : NSObject

+(instancetype)sharedInstance;

- (void)setCameraInView:(UIView *)view;

- (void)removeCameraInView:(UIView *)view;

- (void)startCamera;

- (void)stopCamera;

- (void)takePhotoCompletion:(void (^)(UIImage *image))completion;

- (void)startScanAnimationInView:(UIView *)view;

@end
