//
//  KCLRecognizeManager.m
//  CardScanner
//
//  Created by Aixtuz on 17/2/7.
//  Copyright © 2017年 KCL. All rights reserved.
//

#import <opencv2/core/mat.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <TesseractOCR/TesseractOCR.h>
#import "KCLRecognizeManager.h"


@interface KCLRecognizeManager ()

// 证件类型
@property (assign, nonatomic) KCLRecognizeType recognizeType;
// 处理参数
@property (strong, nonatomic) NSArray<NSNumber *> *paramaters;
// 信息类型
@property (strong, nonatomic) NSArray<NSNumber *> *types;
// 过程图(二值、腐蚀)
@property (strong, nonatomic) NSDictionary *imgDict;
// 目标图 & 识别结果
@property (strong, nonatomic) NSDictionary *infoDict;
@property (strong, nonatomic) NSDictionary *infoDicts;
// 异步队列
@property (strong, nonatomic) NSOperationQueue *queue;
// 正则表达式
@property (strong, nonatomic) NSDictionary *regularExpressions;

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
         andParamaters:(NSArray<NSNumber *> *)paramaters
              complete:(recognizeCompleteBlock)complete
{
    // 每次新识别清空存储
    [self clearDicts];
    // 接受类型和参数
    self.recognizeType = type;
    if (paramaters)
        self.paramaters = paramaters;
    
    // 耗时操作
    [self.queue addOperationWithBlock:^{
        
        // 图片处理(二值+腐蚀)得所有轮廓
        cv::Mat matImage = [self erodeMatFromImage:image];
        std::vector<std::vector<cv::Point>> contours;
        cv::findContours(matImage, contours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cvPoint(0, 0));
        
        // 初步筛选轮廓并识别区分
        std::vector<cv::Rect> rects = [self qualifiedRectsOfContours:contours];
        [self recognizeImage:image withRects:rects];
        
        // 回调过程图, 主线程更新
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            complete(self.infoDicts);
        }];
    }];
}

- (void)recognizeImage:(UIImage *)image
             withRects:(std::vector<cv::Rect>)rects
{
    std::vector<cv::Rect>::const_iterator rect = rects.begin();
    for ( ; rect != rects.end(); ++rect ) {
        NSString *targetInfo = [[NSString alloc] init];
        
        // 图标图片
        CGFloat thresh = [self.paramaters[1] integerValue];
        cv::Mat matImage = [self binaryMatFromImage:image withRect:*rect andThresh:thresh];
        UIImage *targetImage = MatToUIImage(matImage);
        
        // 识别存储
        if (targetImage) {
            targetInfo = [self infoFromImage:targetImage];
            [self infoDictSetObject:targetImage forKey:@"image"];
            [self infoDictSetObject:targetInfo forKey:@"info"];
        }
        
        // 验证类型
        [self verifyInfoTypeWithDict:self.infoDict];
    }
}

- (NSString *)infoFromImage:(UIImage *)image
{
    G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
    tesseract.image = image;
    tesseract.maximumRecognitionTime = 3;
    [tesseract recognize];
    return tesseract.recognizedText;
}

- (void)verifyInfoTypeWithDict:(NSDictionary *)dict
{
    NSString *info = dict[@"info"];
    [self.regularExpressions enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSError *error = NULL;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:obj
                                                                               options:NSRegularExpressionCaseInsensitive
                                                                                 error:&error];
        NSTextCheckingResult *result = [regex firstMatchInString:info
                                                         options:0
                                                           range:NSMakeRange(0, [info length])];
        if (result) {
            [self infoDictsSetObject:dict forKey:key];
        }
    }];
}

///--------------------------------------
#pragma mark - qualified rects
///--------------------------------------

- (std::vector<cv::Rect>)qualifiedRectsOfContours:(std::vector<std::vector<cv::Point>>)contours
{
    std::vector<cv::Rect> rects;
    std::vector<std::vector<cv::Point>>::const_iterator itContours = contours.begin();
    
    // 初步筛选符合要求的轮廓
    for ( ; itContours != contours.end(); ++itContours ) {
        cv::Rect rect = cv::boundingRect(*itContours);
        if (rect.width > 80 &&
            rect.height > 30 &&
            rect.height < 300) {
            rects.push_back(rect);
        }
    }
    return rects;
}

///--------------------------------------
#pragma mark - Image edit
///--------------------------------------

- (void)editImage:(UIImage *)image
         withType:(KCLRecognizeType)type
    andParamaters:(NSArray<NSNumber *> *)paramaters
         complete:(editCompleteBlock)editComplete
{
    // 每次新识别清空存储
    [self clearDicts];
    // 接受类型和参数
    self.recognizeType = type;
    if (paramaters)
        self.paramaters = paramaters;
    
    // 耗时操作
    [self.queue addOperationWithBlock:^{
        
        // 图片预处理
        cv::Mat matImage = [self erodeMatFromImage:image];
        UIImage *erodeImage = MatToUIImage(matImage);
        
        // 存入过程图(腐蚀), 用于检查处理效果
        if (erodeImage)
            [self imgDictSetObject:erodeImage forKey:@"erode"];
        
        // 回调过程图, 主线程更新
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            editComplete(self.imgDict);
        }];
    }];
}

- (cv::Mat)erodeMatFromImage:(UIImage *)image
{
    // 0: 不剪裁
    cv::Rect targetRect = cv::Rect(0,0,0,0);
    
    // 灰度二值化
    CGFloat thresh = [self.paramaters[0] integerValue];
    cv::Mat matImage = [self binaryMatFromImage:image withRect:targetRect andThresh:thresh];
    
    // 腐蚀填充
    CGFloat erodeWidth = [self.paramaters[2] integerValue];
    CGFloat erodeHeight = [self.paramaters[3] integerValue];
    cv::Mat erodeElement = getStructuringElement(cv::MORPH_RECT, cv::Size(erodeWidth,erodeHeight));
    cv::erode(matImage, matImage, erodeElement);
    
    return matImage;
}

- (cv::Mat)binaryMatFromImage:(UIImage *)image withRect:(cv::Rect)rect andThresh:(NSInteger)thresh
{
    // UIImage 转 Mat
    cv::Mat matImage;
    UIImageToMat(image, matImage);
    
    // 与图片范围取交集，避免出界
    rect &= cv::Rect(0, 0, matImage.cols, matImage.rows);
    // 非 0 剪裁
    if (rect.width > 0 && rect.height > 0)
        matImage = matImage(rect);
    
    // 转灰度图
    cvtColor(matImage, matImage, cv::COLOR_BGR2GRAY);
    // 二值化
    cv::threshold(matImage, matImage, thresh, 255, CV_THRESH_BINARY);
    
    // 0: 未剪裁,存入过程图(二值), 用于检查处理效果
    if (rect.width == 0 || rect.height == 0) {
        UIImage *binaryImage = MatToUIImage(matImage);
        if (binaryImage)
            [self imgDictSetObject:binaryImage forKey:@"binary"];
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

- (void)infoDictsSetObject:(id)object forKey:(id)key
{
    NSMutableDictionary *dictM = [NSMutableDictionary dictionaryWithDictionary:self.infoDicts];
    if (object) {
        [dictM setObject:object forKey:key];
    }
    self.infoDicts = dictM.copy;
}

- (void)clearDicts
{
    self.imgDict = nil;
    self.infoDict = nil;
    self.infoDicts = nil;
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

- (NSArray *)paramaters
{
    if (!_paramaters)
        _paramaters = [[NSArray alloc] init];
    if (self.recognizeType == KCLRecognizeTypeIDCard) {
        _paramaters = @[@80, @80, @80, @30];
    } else if (self.recognizeType == KCLRecognizeTypePassport) {
        _paramaters = @[@80, @120, @80, @15];
    }
    return _paramaters;
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

- (NSDictionary *)infoDicts
{
    if (!_infoDicts) {
        _infoDicts = [[NSDictionary alloc] init];
    }
    return _infoDicts;
}

- (NSOperationQueue *)queue {
    if (_queue == nil) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}

- (NSDictionary *)regularExpressions
{
    if (!_regularExpressions) {
        _regularExpressions = @{ @(KCLRecognizeInfoTypeName) : @"",
                                 @(KCLRecognizeInfoTypeGender) : @"",
                                 @(KCLRecognizeInfoTypeNationality) : @"",
                                 @(KCLRecognizeInfoTypeNation) : @"",
                                 @(KCLRecognizeInfoTypeBirthday) : @"",
                                 @(KCLRecognizeInfoTypeAddress) : @"",
                                 @(KCLRecognizeInfoTypeIDCardNumber) : @"^\\d{15}(\\d\\d[0-9xX])?(?=\\n)",
                                 @(KCLRecognizeInfoTypePassportNumber) : @"^[GDESP][0-9E]\\d{7}(?=\\n)",
                                 @(KCLRecognizeInfoTypePassportIssuingDate) : @"",
                                 @(KCLRecognizeInfoTypePassportIssuingPlace) : @"",
                                 @(KCLRecognizeInfoTypePassportValidityDate) : @"" };
    }
    return _regularExpressions;
}

@end
