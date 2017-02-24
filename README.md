# Opencv Tesseract

识别的基本思路,感谢前人的总结:

- [参考1](http://fengdeng.github.io/2016/08/18/iOS%E5%AE%9E%E7%8E%B0%E8%BA%AB%E4%BB%BD%E8%AF%81%E5%8F%B7%E7%A0%81%E8%AF%86%E5%88%AB/)
- [参考2](http://www.jianshu.com/p/ac4c4536ca3e)

## Cocoapods

**podfile**

```objective-c
platform :ios, "8.0"
target 'CardScanner'  do
    pod 'OpenCV'
    pod 'TesseractOCRiOS'
end
```

## RecognizeManager

### 图片处理

```objective-c
cv::Mat matImage;
// UIImage 转 Mat
UIImageToMat(image, matImage);
// 转灰度图
cvtColor(matImage, matImage, cv::COLOR_BGR2GRAY);
// 二值化, thresh:黑白阀值(double)
cv::threshold(matImage, matImage, thresh, 255, CV_THRESH_BINARY);
```

> 首次图片处理不剪裁,用于取得轮廓集合.

### 腐蚀轮廓

```objective-c
// 腐蚀, Size(W,H):横竖腐蚀值(int)
cv::Mat erodeElement = getStructuringElement(cv::MORPH_RECT, cv::Size(erodeWidth,erodeHeight));
// 取出所有轮廓
std::vector<std::vector<cv::Point>> *contours;
cv::findContours(matImage, contours, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cvPoint(0, 0));
```

### 匹配轮廓

```objective-c
std::vector<cv::Rect> rects;
cv::Rect numberRect = cv::Rect(0,0,0,0);
// 遍历轮廓
std::vector<std::vector<cv::Point>>::const_iterator itContours = contours.begin();
  for ( ; itContours != contours.end(); ++itContours) {
  cv::Rect rect = cv::boundingRect(*itContours);
  rects.push_back(rect);
  // 筛选轮廓的条件
  if () {
    numberRect = rect;
  }
} 
```

### 切割轮廓

```objective-c
// 重复[图片处理]步骤 & 切割'匹配轮廓'
matImage = matImage(rect);
// 灰度&二值&切割,转回 UIImage 用于识别
UIImage *targetImage = MatToUIImage(matImage);
```

> 与操作最大图片轮廓， 避免超出范围崩溃，rect &= cv::Rect(0, 0, matImage.cols, matImage.rows);

### 识别方法

```objective-c
G8Tesseract *tesseract = [[G8Tesseract alloc] initWithLanguage:@"eng"];
// 传入要切割好的图片
tesseract.image = image;
[tesseract recognize];                
// 回调识别结果
complete(tesseract.recognizedText);
```

### 调用识别

```objective-c
- (void)recognizeImage:(UIImage *)image complete:^(NSString *recognizeText) 
{
    // 识别类型等自行扩充方法参数
}
```

# Tesseract Training

- 中英语言包相加近百兆,身份证号码只用到 0~9+X,故可自行训练语言.
- 其他语言需求自行准备素材: Text + Font 生成 tif & box, 或者图片转 tif.

## Install

- Homebrew

- Install tesseract (3.02)

  ```shell
    // Install ImageMagick for image conversion:
    brew install imagemagick
    // Install tesseract for OCR:
    brew install tesseract --all-languages
    // Install training tools
    brew install tesseract --with-training-tools
  ```

- java

- [jTessBoxEditor](https://sourceforge.net/projects/vietocr/files/jTessBoxEditor/)

## Material

### 自动方法(Text-->tif & box)

- training_text.txt(UTF-8) 文件写入: 1234567890X(需要识别的目标)
- Droid Sans Mono Font 36(对应的字体)
- Press Generate --> .tif & .box

### 手动方法(jpg/png --> tif & box)

- 处理图片

  ```shell
    // 灰度: 直接转 tif 会提示:不支持16-bit png
    convert -monochrome name.png name.png
    // png/jpg 转 tif
    convert name.jpg name.tif
  ```

- jTessBoxEditor —— Tools —— Merge Tiff

- 全选合并 tif & 命名为 `language.fontName.exp.tif`

  ```shell
    // box
    tesseract fontname.fonttype.exp0.tif fontname.fonttype.exp0 makebox
    // -l -psm 参数可选
  ```

### 检查 .tif 识别

- Box Editor tab: Open .tif 检查识别正误，纠正保存

## Training

- touch font_properties 内容: `fontName 0 0 0 0 0`
- 生成训练文件（UTF-8 without DOM）

```shell
// 生成 .tr 训练文件
tesseract language.fontName.exp0.tif language.fontName.exp0 nobatch box.train
// 生成字符集文件
unicharset_extractor language.fontName.exp0.box
// 生成 shape 文件
shapeclustering -F font_properties -U unicharset -O language.unicharset language.fontName.exp0.tr
// 生成聚集字符特征文件: unicharset、inttemp、pffmtable
mftraining -F font_properties -U unicharset -O language.unicharset language.fontName.exp0.tr
// 生成正常化特征文件 normproto
cntraining language.fontName.exp0.tr
```

- 训练文件改名

```shell
mv normproto fontname.normproto  
mv inttemp fontname.inttemp  
mv pffmtable fontname.pffmtable   
mv unicharset fontname.unicharset  
mv shapetable fontname.shapetable  
```

- 合并训练文件

```
// 生成fontname.traineddata文件
combine_tessdata fontname.
```

> - 命令行最后必须带一个点。
> - 执行结果中，1,3,4,5,13这几行必须有数值，才代表命令执行成功。