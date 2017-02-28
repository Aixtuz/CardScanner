//
//  KCLRecognizeManager.h
//  CardScanner
//
//  Created by Aixtuz on 17/2/7.
//  Copyright © 2017年 KCL. All rights reserved.
//

#import <Foundation/Foundation.h>
@class UIImage;

typedef NS_ENUM(NSInteger, KCLRecognizeType)
{
    KCLRecognizeTypeIDCard = 0,
    KCLRecognizeTypePassport = 1,
};

typedef NS_ENUM(NSInteger, KCLRecognizeInfoType)
{
    KCLRecognizeInfoTypeName = 0,
    KCLRecognizeInfoTypeGender = 1,
    KCLRecognizeInfoTypeNationality = 2,
    KCLRecognizeInfoTypeNation = 3,
    KCLRecognizeInfoTypeBirthday = 4,
    KCLRecognizeInfoTypeAddress = 5,
    KCLRecognizeInfoTypeIDCardNumber = 6,
    KCLRecognizeInfoTypePassportNumber = 7,
    KCLRecognizeInfoTypePassportIssuingDate = 8,
    KCLRecognizeInfoTypePassportIssuingPlace = 9,
    KCLRecognizeInfoTypePassportValidityDate = 10,
};

// 结构: { @"binary": binaryImage, @"erode": erodeImage, ... }
typedef void (^editCompleteBlock)(NSDictionary *imgDict);
// 结构: { @infoType: { @"image": targetImage, @"info": targetInfo }, ... }
typedef void (^recognizeCompleteBlock)(NSDictionary *infoDicts);

@interface KCLRecognizeManager : NSObject

/**
 图片识别: 返回识别结果,用于显示
 
 @param image      原始图片
 @param type       识别类型
 @param paramaters 图片调试参数，之后可移至 manager 中动态调整
 @param complete   识别结果回调
 */
- (void)recognizeImage:(UIImage *)image
              withType:(KCLRecognizeType)type
         andParamaters:(NSArray<NSNumber *> *)paramaters
              complete:(recognizeCompleteBlock)complete;

/**
 图片处理: 用于检查图片处理效果,调整参数(正式使用可移除此方法)
 
 @param image        原始图片
 @param paramaters   图片调试参数
 @param editComplete 过程图回调
 */
- (void)editImage:(UIImage *)image
   withParamaters:(NSArray<NSNumber *> *)paramaters
         complete:(editCompleteBlock)editComplete;

@end
