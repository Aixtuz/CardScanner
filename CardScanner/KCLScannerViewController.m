//
//  KCLScannerViewController.m
//  CardScanner
//
//  Created by Aixtuz on 17/2/7.
//  Copyright © 2017年 KCL. All rights reserved.
//

#import "KCLScannerViewController.h"
#import "KCLRecognizeManager.h"

@interface KCLScannerViewController ()

@property (strong, nonatomic) UIImagePickerController *imgPicker;
@property (strong, nonatomic) UIImage *rawImage;
@property (strong, nonatomic) NSArray *types;

@property (weak, nonatomic) IBOutlet UIImageView *binaryImage;
@property (weak, nonatomic) IBOutlet UIImageView *erodeImage;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;

@property (weak, nonatomic) IBOutlet UIImageView *nameImage;
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UIImageView *genderImage;
@property (weak, nonatomic) IBOutlet UILabel *genderLabel;
@property (weak, nonatomic) IBOutlet UIImageView *nationImage;
@property (weak, nonatomic) IBOutlet UILabel *nationLabel;
@property (weak, nonatomic) IBOutlet UIImageView *birthImage;
@property (weak, nonatomic) IBOutlet UILabel *birthLabel;
@property (weak, nonatomic) IBOutlet UIImageView *addressImage;
@property (weak, nonatomic) IBOutlet UILabel *addressLabel;
@property (weak, nonatomic) IBOutlet UIImageView *numberImage;
@property (weak, nonatomic) IBOutlet UILabel *numberLabel;

@property (weak, nonatomic) IBOutlet UISlider *editSlider;
@property (weak, nonatomic) IBOutlet UILabel *editLabel;
@property (weak, nonatomic) IBOutlet UISlider *recognizeSlider;
@property (weak, nonatomic) IBOutlet UILabel *recognizeLabel;
@property (weak, nonatomic) IBOutlet UISlider *erodeWidthSlider;
@property (weak, nonatomic) IBOutlet UILabel *erodeWidthLabel;
@property (weak, nonatomic) IBOutlet UISlider *erodeHeightSlider;
@property (weak, nonatomic) IBOutlet UILabel *erodeHeightLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *typeControl;


@end


@implementation KCLScannerViewController

///--------------------------------------
#pragma mark - life cycle
///--------------------------------------

- (void)viewDidLoad
{
    [super viewDidLoad];
}

///--------------------------------------
#pragma mark - setup & configuration
///--------------------------------------



///--------------------------------------
#pragma mark - UIImagePickerControllerDelegate
///--------------------------------------

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    // 需要识别的图片
    self.rawImage = info[UIImagePickerControllerOriginalImage];
    if (self.rawImage)
        // 使用默认参数
        [self recognizeImage:self.rawImage
                    withType:self.typeControl.selectedSegmentIndex
               andParamaters:nil];
    
    [picker dismissViewControllerAnimated:YES completion:nil];
}

///--------------------------------------
#pragma mark - event response
///--------------------------------------

- (IBAction)cameraBtnClicked
{
    // 隐私权限
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        self.imgPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:self.imgPicker animated:YES completion:nil];
    } else {
        NSLog(@"无权打开相机");
    }
}

- (IBAction)photoBtnClicked
{
    // 隐私权限
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        self.imgPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:self.imgPicker animated:YES completion:nil];
    } else {
        NSLog(@"无权打开相册");
    }
}

- (IBAction)sliderChanged:(UISlider *)sender
{
    NSString *value = [NSString stringWithFormat:@"%.1f", sender.value];
    switch (sender.tag) {
        case 0: {
            self.editLabel.text = value;
            break;
        }
        case 1: {
            self.recognizeLabel.text = value;
            break;
        }
        case 2: {
            self.erodeWidthLabel.text = value;
            break;
        }
        case 3: {
            self.erodeHeightLabel.text = value;
            break;
        }
        default:
            break;
    }
}

- (IBAction)segmentedChanged:(UISegmentedControl *)sender
{
    switch (sender.selectedSegmentIndex) {
        case 0: {
            self.editSlider.value = 80;
            self.editLabel.text = @"80";
            self.recognizeSlider.value = 80;
            self.recognizeLabel.text = @"80";
            self.erodeWidthSlider.value = 80;
            self.erodeWidthLabel.text = @"80";
            self.erodeHeightSlider.value = 30;
            self.erodeHeightLabel.text = @"30";
            break;
        }
        case 1: {
            self.editSlider.value = 80;
            self.editLabel.text = @"80";
            self.recognizeSlider.value = 120;
            self.recognizeLabel.text = @"120";
            self.erodeWidthSlider.value = 80;
            self.erodeWidthLabel.text = @"80";
            self.erodeHeightSlider.value = 15;
            self.erodeHeightLabel.text = @"15";
            break;
        }
        default:
            break;
    }
}

- (IBAction)refreshBtnClicked
{
    if (self.rawImage)
        // 传入测试参数
        [self recognizeImage:self.rawImage
                    withType:KCLRecognizeTypeIDCard
               andParamaters:[self paramaters]];
}


///--------------------------------------
#pragma mark - update views
///--------------------------------------

- (void)updateImageWithDict:(NSDictionary *)imgDict
{
    // 过程图
    self.binaryImage.image = imgDict[@"binary"];
    self.erodeImage.image = imgDict[@"erode"];
}

- (void)updateInfoWithDicts:(NSDictionary *)infoDicts
{
    // 目标 & 结果 & 显示
    self.nameImage.image = infoDicts[@(KCLRecognizeInfoTypeName)][@"image"];
    NSString *nameStr = infoDicts[@(KCLRecognizeInfoTypeName)][@"info"];
    if (![self.nameLabel.text isEqualToString:nameStr])
        self.nameLabel.text = nameStr ?: @"Error";
    
    self.genderImage.image = infoDicts[@(KCLRecognizeInfoTypeGender)][@"image"];
    NSString *genderStr = infoDicts[@(KCLRecognizeInfoTypeGender)][@"info"];
    if (![self.genderLabel.text isEqualToString:genderStr])
        self.genderLabel.text = genderStr ?: @"Error";
    
    self.nationImage.image = infoDicts[@(KCLRecognizeInfoTypeNation)][@"image"];
    NSString *nationStr = infoDicts[@(KCLRecognizeInfoTypeNation)][@"info"];
    if (![self.nationLabel.text isEqualToString:nationStr])
        self.nationLabel.text = nationStr ?: @"Error";
    
    self.birthImage.image = infoDicts[@(KCLRecognizeInfoTypeBirthday)][@"image"];
    NSString *birthStr = infoDicts[@(KCLRecognizeInfoTypeBirthday)][@"info"];
    if (![self.birthLabel.text isEqualToString:birthStr])
        self.birthLabel.text = birthStr ?: @"Error";
    
    self.addressImage.image = infoDicts[@(KCLRecognizeInfoTypeAddress)][@"image"];
    NSString *addressStr = infoDicts[@(KCLRecognizeInfoTypeAddress)][@"info"];
    if (![self.addressLabel.text isEqualToString:addressStr])
        self.addressLabel.text = addressStr ?: @"Error";
    
    UIImage *passportImage = infoDicts[@(KCLRecognizeInfoTypePassportNumber)][@"image"];
    UIImage *idCardImage = infoDicts[@(KCLRecognizeInfoTypeIDCardNumber)][@"image"];
    self.numberImage.image = passportImage ?: idCardImage;
    
    NSString *passportNumber = infoDicts[@(KCLRecognizeInfoTypePassportNumber)][@"info"];
    NSString *idCardNumber = infoDicts[@(KCLRecognizeInfoTypeIDCardNumber)][@"info"];
    NSString *numberStr = passportNumber ?: idCardNumber;
    if (![self.numberLabel.text isEqualToString:numberStr])
        self.numberLabel.text = numberStr ?: @"Error";
    
    [self.indicator stopAnimating];
}

///--------------------------------------
#pragma mark - helper/private methods
///--------------------------------------

- (void)recognizeImage:(UIImage *)image
              withType:(KCLRecognizeType)type
         andParamaters:(NSArray<NSNumber *> *)paramaters
{
    [self.indicator startAnimating];
    
    __weak typeof(self) weakSelf = self;
    KCLRecognizeManager *RecognizeMgr = [[KCLRecognizeManager alloc] init];
    
    // 回调过程图, 以便调整处理参数
    [RecognizeMgr editImage:image
                   withType:type
             andParamaters:paramaters
                   complete:^(NSDictionary *imgDicts) {
                       __strong typeof(self) strongSelf = weakSelf;
                       [strongSelf updateImageWithDict:imgDicts];
                   }];
    
    // 回调识别结果
    [RecognizeMgr recognizeImage:image
                        withType:type
                   andParamaters:paramaters
                        complete:^(NSDictionary *infoDict) {
                            __strong typeof(self) strongSelf = weakSelf;
                            [strongSelf updateInfoWithDicts:infoDict];
                        }];
}

- (NSArray *)paramaters
{
    return @[ @(self.editSlider.value),
              @(self.recognizeSlider.value),
              @(self.erodeWidthSlider.value),
              @(self.erodeHeightSlider.value) ];
}

///--------------------------------------
#pragma mark - getters and setters
///--------------------------------------

- (UIImagePickerController *)imgPicker
{
    if (!_imgPicker) {
        _imgPicker = [[UIImagePickerController alloc] init];
        _imgPicker.delegate = self;
    }
    return _imgPicker;
}

@end
