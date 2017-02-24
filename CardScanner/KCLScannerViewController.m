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
    [picker dismissViewControllerAnimated:YES completion:nil];
    
    [self recognizeImage:self.rawImage withType:KCLRecognizeTypeIDCard andParameters:[self parameters]];
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

- (IBAction)refreshBtnClicked
{
    if (self.rawImage) {
        [self recognizeImage:self.rawImage withType:KCLRecognizeTypeIDCard andParameters:[self parameters]];
    }
}

///--------------------------------------
#pragma mark - update views
///--------------------------------------

- (void)updateImageWithDicts:(NSDictionary *)imgDicts
{
    // 过程图
    self.binaryImage.image = imgDicts[@"binary"];
    self.erodeImage.image = imgDicts[@"erode"];
    
    // 各目标图
    NSDictionary *imageDict = imgDicts[@"target"];
    
    self.nameImage.image = imageDict[@(KCLRecognizeInfoTypeName)];
    self.genderImage.image = imageDict[@(KCLRecognizeInfoTypeGender)];
    self.nationImage.image = imageDict[@(KCLRecognizeInfoTypeNation)];
    self.birthImage.image = imageDict[@(KCLRecognizeInfoTypeBirthday)];
    self.addressImage.image = imageDict[@(KCLRecognizeInfoTypeAddress)];
    self.numberImage.image = imageDict[@(KCLRecognizeInfoTypeIDCardNumber)];
}

- (void)updateInfoWithDict:(NSDictionary *)infoDict
{
    NSString *nameStr = infoDict[@(KCLRecognizeInfoTypeName)];
    NSString *genderStr = infoDict[@(KCLRecognizeInfoTypeGender)];
    NSString *nationStr = infoDict[@(KCLRecognizeInfoTypeNation)];
    NSString *birthStr = infoDict[@(KCLRecognizeInfoTypeBirthday)];
    NSString *addressStr = infoDict[@(KCLRecognizeInfoTypeAddress)];
    NSString *numberStr = infoDict[@(KCLRecognizeInfoTypeIDCardNumber)];
    
    // 避免重复刷新已经识别好的
    if (![self.nameLabel.text isEqualToString:nameStr]) {
        self.nameLabel.text = nameStr ?: @"Error";
    }
    if (![self.genderLabel.text isEqualToString:genderStr]) {
        self.genderLabel.text = genderStr ?: @"Error";
    }
    if (![self.nationLabel.text isEqualToString:nationStr]) {
        self.nationLabel.text = nationStr ?: @"Error";
    }
    if (![self.birthLabel.text isEqualToString:birthStr]) {
        self.birthLabel.text = birthStr ?: @"Error";
    }
    if (![self.addressLabel.text isEqualToString:addressStr]) {
        self.addressLabel.text = addressStr ?: @"Error";
    }
    if (![self.numberLabel.text isEqualToString:numberStr]) {
        // 17、20: 识别结果带 2 个换行符
        self.numberLabel.text = (numberStr.length == 17 || numberStr.length == 20) ? numberStr : @"Error";
    }
}

///--------------------------------------
#pragma mark - helper/private methods
///--------------------------------------

- (void)recognizeImage:(UIImage *)image withType:(KCLRecognizeType)type andParameters:(NSArray<NSNumber *> *)parameters
{
    [self.indicator startAnimating];
    
    KCLRecognizeManager *RecognizeMgr = [[KCLRecognizeManager alloc] init];
    __weak typeof(self) weakSelf = self;
    
    // 回调过程图, 以便调整处理参数
    [RecognizeMgr editImage:image withType:type andParameters:[self parameters] complete:^(NSDictionary *imgDicts) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf updateImageWithDicts:imgDicts];
    }];
    
    // 回调识别结果
    [RecognizeMgr recognizeImage:image withType:type andParameters:parameters complete:^(NSDictionary *infoDict) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf updateInfoWithDict:infoDict];
        [strongSelf.indicator stopAnimating];
    }];
}

- (NSArray *)parameters
{
    NSArray *parameters = @[
                            @(self.editSlider.value),
                            @(self.recognizeSlider.value),
                            @(self.erodeWidthSlider.value),
                            @(self.erodeHeightSlider.value),
                            ];
    return parameters;
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
