//
//  KCLRecognizeManager.m
//  CardScanner
//
//  Created by Aixtuz on 17/2/7.
//  Copyright © 2017年 KCL. All rights reserved.
//

#import "KCLRecognizeManager.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <TesseractOCR/TesseractOCR.h>

@interface KCLRecognizeManager ()

// 证件类型
@property (assign, nonatomic) KCLRecognizeType recognizeType;
// 信息类型
@property (strong, nonatomic) NSArray<NSNumber *> *types;
// 过程图(二值、腐蚀)
@property (strong, nonatomic) NSDictionary *imgDicts;
// 目标图(按类型存)
@property (strong, nonatomic) NSDictionary *imgDict;
// 识别结果
@property (strong, nonatomic) NSDictionary *infoDict;
// 处理参数
@property (strong, nonatomic) NSArray *parameters;
// 异步队列
@property (strong, nonatomic) NSOperationQueue *queue;

@end


@implementation KCLRecognizeManager

///--------------------------------------
#pragma mark - life cycle
///--------------------------------------



///--------------------------------------
#pragma mark - Image Recognize
///--------------------------------------

- (void)recognizeImage:(UIImage *)image
              withType:(KCLRecognizeType)type
         andParameters:(NSArray<NSNumber *> *)parameters
              complete:(recognizeCompleteBlock)complete
{
    // 证件类型用于判断需要识别的 infoTypes
    self.recognizeType = type;
    
    // 回调过程&目标图集合
    __weak typeof(self) weakSelf = self;
    [self editImage:image withType:type andParameters:parameters complete:^(NSDictionary *imgDicts) {
        
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.queue addOperationWithBlock:^{
            
            // 过程图于 editComplete 方法中直接回调更新显示
            // 此处只取目标图, 识别队列结束再回调结果
            for (NSNumber *number in self.types) {
                NSDictionary *imgDict = [imgDicts objectForKey:@"target"];
                UIImage *image = [imgDict objectForKey:number];
                
                if (image) {
                    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
                    tesseract.image = image;
                    
                    // 黑/白名单限制识别范围
                    switch ([number integerValue]) {
                        case KCLRecognizeInfoTypeIDCardNumber: {
                            tesseract.charWhitelist = @"0123456789X";
                            break;
                        }
                        default:
                            break;
                    }
                    [tesseract recognize];
                    
                    // 存入每次的识别结果
                    [strongSelf infoDictSetObject:tesseract.recognizedText forKey:number];
                }
            }
            
            // 回调结果, 主线程更新
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                complete(strongSelf.infoDict);
            }];
        }];
    }];
}

- (void)editImage:(UIImage *)image
         withType:(KCLRecognizeType)type
    andParameters:(NSArray<NSNumber *> *)parameters
         complete:(editCompleteBlock)editComplete
{
    // 每次新识别清空存储
    [self clearDicts];
    
    // 耗时操作
    [self.queue addOperationWithBlock:^{
        
        // 接收处理参数
        self.parameters = parameters;
        for (NSNumber *number in self.types) {
            
            // 传入容器指针, 取得轮廓集合
            std::vector<std::vector<cv::Point>> *contours = new std::vector<std::vector<cv::Point>>();
            [self getContours:*contours fromImage:image];
            
            // 按类型筛选目标轮廓
            KCLRecognizeInfoType type = (KCLRecognizeInfoType)[number integerValue];
            cv::Rect targetRect = [self rectOfContours:contours forType:type];
            
            // 目标轮廓无宽高, 不必继续识别
            if (targetRect.width == 0 || targetRect.height == 0) {
                continue;
            }
            
            // 存入目标图, 用于检查处理效果
            CGFloat thresh = [self.parameters[1] integerValue];
            cv::Mat matImage = [self editImage:image withRect:targetRect andThresh:thresh];
            
            // 传入 targetRect 切割时，已和图片范围取交集，为 0 时不切割仍为原图，故而一定存在
            UIImage *targetImage = MatToUIImage(matImage);
            [self imgDictSetObject:targetImage forKey:number];
        }
        // 存入目标图
        [self imgDictsSetObject:self.imgDict forKey:@"target"];
        
        // 回调过程图, 主线程更新
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            editComplete(self.imgDicts);
        }];
    }];
}

///--------------------------------------
#pragma mark - Image rect
///--------------------------------------

- (cv::Rect)rectOfContours:(std::vector<std::vector<cv::Point>> *)contours forType:(KCLRecognizeInfoType)type
{
    cv::Rect targetRect = cv::Rect(0,0,0,0);
    cv::Rect numberRect = cv::Rect(0,0,0,0);
    std::vector<std::vector<cv::Point>>::const_iterator itContours = contours->begin();
    
    // 遍历轮廓容器, 匹配类型对应算法, 取出目标轮廓
    for ( ; itContours != contours->end(); ++itContours) {
        
        cv::Rect rect = cv::boundingRect(*itContours);

        if (type == KCLRecognizeInfoTypeIDCardNumber &&
            rect.width > numberRect.width &&
            rect.width > rect.height * 5) {
            numberRect = rect;
        } else if (type == KCLRecognizeInfoTypePassportNumber) {
            // TODO passportNumber
        }
    }
    
    switch (type) {
        case KCLRecognizeInfoTypeName: {
            // name 轮廓
            if (self.recognizeType == KCLRecognizeTypeIDCard) {

            } else if (self.recognizeType == KCLRecognizeTypePassport) {
            
            }
            break;
        }
        case KCLRecognizeInfoTypeGender: {
            // gender 轮廓
            if (self.recognizeType == KCLRecognizeTypeIDCard) {

            } else if (self.recognizeType == KCLRecognizeTypePassport) {
                
            }
            break;
        }
        case KCLRecognizeInfoTypeNation: {
            // nation 轮廓
            if (self.recognizeType == KCLRecognizeTypeIDCard) {

            } else if (self.recognizeType == KCLRecognizeTypePassport) {
                
            }
            break;
        }
        case KCLRecognizeInfoTypeBirthday: {
            // birth 轮廓
            if (self.recognizeType == KCLRecognizeTypeIDCard) {

            } else if (self.recognizeType == KCLRecognizeTypePassport) {
                
            }
            break;
        }
        case KCLRecognizeInfoTypeAddress: {
            // address 轮廓
            if (self.recognizeType == KCLRecognizeTypeIDCard) {

            } else if (self.recognizeType == KCLRecognizeTypePassport) {
                
            }
            break;
        }
        case KCLRecognizeInfoTypeIDCardNumber: {
            // number 轮廓
            if (self.recognizeType == KCLRecognizeTypeIDCard) {
                targetRect = numberRect;
            } else if (self.recognizeType == KCLRecognizeTypePassport) {
                
            }
            break;
        }
        default:
            break;
    }
    
    return targetRect;
}

///--------------------------------------
#pragma mark - Image edit
///--------------------------------------

- (void)getContours:(std::vector<std::vector<cv::Point>> &)contours fromImage:(UIImage *)image
{
    // 0: 不剪裁
    cv::Rect targetRect = cv::Rect(0,0,0,0);
    
    // 灰度二值化
    CGFloat thresh = [self.parameters[0] integerValue];
    cv::Mat matImage = [self editImage:image withRect:targetRect andThresh:thresh];
    
    // 腐蚀填充
    CGFloat erodeWidth = [self.parameters[2] integerValue];
    CGFloat erodeHeight = [self.parameters[3] integerValue];
    cv::Mat erodeElement = getStructuringElement(cv::MORPH_RECT, cv::Size(erodeWidth,erodeHeight));
    cv::erode(matImage, matImage, erodeElement);
    
    // 存入腐蚀图, 用于检查处理效果
    UIImage *erodeImage = MatToUIImage(matImage);
    [self imgDictsSetObject:erodeImage forKey:@"erode"];
    
    // 轮廊容器
    cv::findContours(matImage, contours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cvPoint(0, 0));
}

- (cv::Mat)editImage:(UIImage *)image withRect:(cv::Rect)rect andThresh:(NSInteger)thresh
{
    // UIImage 转 Mat
    cv::Mat matImage;
    UIImageToMat(image, matImage);
    
    // 与图片范围取交集避免出界
    rect &= cv::Rect(0, 0, matImage.cols, matImage.rows);
    if (rect.width > 0 || rect.height > 0) {
        // 非 0 剪裁
        matImage = matImage(rect);
    }
    
    // 转灰度图
    cvtColor(matImage, matImage, cv::COLOR_BGR2GRAY);
    
    // 二值化
    cv::threshold(matImage, matImage, thresh, 255, CV_THRESH_BINARY);
    
    if (rect.width == 0 || rect.height == 0) {
        // 预处理图片未剪裁, 存入二值图, 用于检查处理效果
        UIImage *binaryImage = MatToUIImage(matImage);
        if (binaryImage) {
            [self imgDictsSetObject:binaryImage forKey:@"binary"];
        }
    }
    return matImage;
}

///--------------------------------------
#pragma mark - helper/private methods
///--------------------------------------

- (NSArray *)idCardInfoTypes
{
    return @[ @(KCLRecognizeInfoTypeName),
              @(KCLRecognizeInfoTypeGender),
              @(KCLRecognizeInfoTypeNation),
              @(KCLRecognizeInfoTypeBirthday),
              @(KCLRecognizeInfoTypeAddress),
              @(KCLRecognizeInfoTypeIDCardNumber) ];
}

- (NSArray *)passportInfoTypes
{
    return @[ @(KCLRecognizeInfoTypeName),
              @(KCLRecognizeInfoTypeGender),
              @(KCLRecognizeInfoTypeNationality),
              @(KCLRecognizeInfoTypeBirthday),
              @(KCLRecognizeInfoTypePassportNumber),
              @(KCLRecognizeInfoTypePassportIssuingDate),
              @(KCLRecognizeInfoTypePassportIssuingPlace),
              @(KCLRecognizeInfoTypePassportValidityDate) ];
}

- (void)imgDictsSetObject:(id)object forKey:(id)key
{
    NSMutableDictionary *dictM = [NSMutableDictionary dictionaryWithDictionary:self.imgDicts];
    if (object) {
        [dictM setObject:object forKey:key];
    }
    self.imgDicts = dictM.copy;
}

- (void)imgDictSetObject:(id)object forKey:(id)key
{
    NSMutableDictionary *dictM = [NSMutableDictionary dictionaryWithDictionary:self.imgDict];
    if (object) {
        [dictM setObject:object forKey:key];
    }
    self.imgDict = dictM.copy;
}

- (void)infoDictSetObject:(id)object forKey:(id)key
{
    NSMutableDictionary *dictM = [NSMutableDictionary dictionaryWithDictionary:self.infoDict];
    if (object) {
        [dictM setObject:object forKey:key];
    }
    self.infoDict = dictM.copy;
}

- (void)clearDicts
{
    self.imgDict = nil;
    self.imgDicts = nil;
    self.infoDict = nil;
}

///--------------------------------------
#pragma mark - getters and setters
///--------------------------------------

- (NSArray<NSNumber *> *)types
{
    if (!_types) {
        _types = [[NSArray alloc] init];
    }
    if (self.recognizeType == KCLRecognizeTypeIDCard) {
        _types = [self idCardInfoTypes];
    } else if (self.recognizeType == KCLRecognizeTypePassport) {
        _types = [self passportInfoTypes];
    }
    return _types;
}

- (NSDictionary *)imgDicts
{
    if (!_imgDicts) {
        _imgDicts = [[NSDictionary alloc] init];
    }
    return _imgDicts;
}

- (NSDictionary *)imgDict
{
    if (!_imgDict) {
        _imgDict = [[NSDictionary alloc] init];
    }
    return _imgDict;
}

- (NSDictionary *)infoDict
{
    if (!_infoDict) {
        _infoDict = [[NSDictionary alloc] init];
    }
    return _infoDict;
}

- (NSArray *)parameters
{
    if (!_parameters) {
        _parameters = [[NSArray alloc] init];
    }
    return _parameters;
}

- (NSOperationQueue *)queue {
    if (_queue == nil) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}

@end
