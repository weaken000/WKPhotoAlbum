# WKPhotoAlbum

## 0. 概述
 `WKPhotoAlbum`是一个用于`iOS`的自定义相册选择器，UI上模仿了微信的相册选择器。

  ### `Requirement`
  iOS 9.0+
  
 ## 1. 实现功能
 * 系统的资源自定义集成
 * 图片与视频的选取
 * 自定义的媒体录制界面
 
 ## 2. 使用方法
 
 ### 2.1 回调方式
 
 ```objc
 UIViewController *next = [WKPhotoAlbum presentAlbumVCWithSelectBlock:^(NSArray * _Nonnull result) {
     NSLog(@"blockSelect--%@", result);
 } cancelBlock:^{
     NSLog(@"blockCancel");
 }];
```
```objc
[WKPhotoAlbum setPhotoAlbumDelegate:self];
UIViewController *next = [WKPhotoAlbum presentAlbumVC];
```

### 2.2 自定义配置属性

可在`WKPhotoAlbumConfig`类文件中查看所有可配置属性

```objc
//default is NO
@property (nonatomic, assign) BOOL isIncludeVideo;
//default is YES
@property (nonatomic, assign) BOOL isIncludeImage;
//default is 1
@property (nonatomic, assign) NSUInteger maxSelectCount;
//default is NO
@property (nonatomic, assign) BOOL canClip;
//default is YES
@property (nonatomic, assign) BOOL allowTakePicture;
//default is YES
@property (nonatomic, assign) BOOL allowTakeVideo;
...
```
## 3. Screen Shot
![image](https://github.com/weaken000/WKPhotoAlbum/blob/master/WKPhotoAlbumSample/WKPhotoAlbumSample/ScreenShot1.png)
![image](https://github.com/weaken000/WKPhotoAlbum/blob/master/WKPhotoAlbumSample/WKPhotoAlbumSample/ScreenShot2.png)

 ## 4. 集成方式
 
 ### `cocoapods`
 
 ```sh
 pod "WKPhotoAlbum", '2.0'
 ```
 
 
 
