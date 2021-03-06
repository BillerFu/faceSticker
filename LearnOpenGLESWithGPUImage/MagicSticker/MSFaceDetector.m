//
//  MSFaceDetector.m
//  LearnOpenGLESWithGPUImage
//
//  Created by Bill on 17/2/9.
//  Copyright © 2017年 Bill. All rights reserved.
//

#import "MSFaceDetector.h"
#import "CanvasView.h"
#import "CalculatorTools.h"

@interface MSFaceDetector()

@property (nonatomic) UIInterfaceOrientation interfaceOrientation;
/**
 人脸识别
 */
@property (nonatomic, retain ) MSFaceDetector *msFaceDetector;
@property (nonatomic, retain ) IFlyFaceDetector *faceDetector;
@property (nonatomic , strong) CanvasView   *viewCanvas;
@property (nonatomic) CGRect viewRect;
@property (nonatomic) BOOL isFront;

/**
 切换按钮
 */
@property (nonatomic) UIButton *firstStyleButton;
@property (nonatomic) UIButton *secondStyleButton;
@property (nonatomic) UIButton *thirdStyleButton;
@property (nonatomic) UIButton *fourthStyleButton;
@property (nonatomic) UIButton *fifthStyleButton;

@property (nonatomic) UIButton *videoSaveButton;

@property (nonatomic) UILabel *rtmpLabel;


@end


@implementation MSFaceDetector

@synthesize rtmpLabel;

- (id)initWithFrame:(CGRect)frame {
    
    self.frame = frame;
    
    self.viewRect = CGRectMake(0, 0, frame.size.width, frame.size.height);
    // 人脸识别
    self.viewCanvas = [[CanvasView alloc] initWithFrame:CGRectMake(0, 0, self.viewRect.size.width, self.viewRect.size.width / 480 * 640)];
    self.viewCanvas.backgroundColor = [UIColor clearColor];
    self.viewCanvas.headMap = [UIImage imageNamed:@"newyearHear"];
    self.viewCanvas.allbackgroundMap = [UIImage imageNamed:@"newyearBack"];
    self.viewCanvas.clipsToBounds = YES;
    self.faceDetector = [IFlyFaceDetector sharedInstance];
    
    //    if(self.faceDetector){
    [self.faceDetector setParameter:@"1" forKey:@"detect"];
    [self.faceDetector setParameter:@"1" forKey:@"align"];
    //    }
    

    return self;
}


- (MSFaceDetector *)initWithViewRect:(CGRect)viewRect{
    
    self.frame = CGRectMake(0, 0, viewRect.size.width, viewRect.size.height);
    
    self.viewRect = viewRect;
    // 人脸识别
    self.viewCanvas = [[CanvasView alloc] initWithFrame:CGRectMake(0, 0, self.viewRect.size.width, self.viewRect.size.width / 480 * 640)];
    self.viewCanvas.backgroundColor = [UIColor clearColor];
    self.viewCanvas.headMap = [UIImage imageNamed:@"newyearHear"];
    self.viewCanvas.allbackgroundMap = [UIImage imageNamed:@"newyearBack"];
    self.viewCanvas.clipsToBounds = YES;
    self.faceDetector = [IFlyFaceDetector sharedInstance];
    
//    if(self.faceDetector){
        [self.faceDetector setParameter:@"1" forKey:@"detect"];
        [self.faceDetector setParameter:@"1" forKey:@"align"];
//    }
    
    return self;
}

- (void)faceImageSampleBufferFromPlatform:(CMSampleBufferRef)sampleBuffer isFront:(BOOL)isFront{
    
    self.isFront = isFront;
    
    
    
    IFlyFaceImage* faceImg=[self faceImageFromSampleBuffer:sampleBuffer];
    
    
    
    //识别结果，json数据
    NSString* strResult=[self.faceDetector trackFrame:faceImg.data withWidth:faceImg.width height:faceImg.height direction:(int)faceImg.direction];
    
//    NSLog(@"sampleBuffer %lf,%lf",faceImg.width,faceImg.height);
    NSLog(@"strResult %@",strResult);
    //    NSLog(@"strResult is %ld",faceImg.direction);
    
    //此处清理图片数据，以防止因为不必要的图片数据的反复传递造成的内存卷积占用
    faceImg.data=nil;
    
    //        [self praseTrackResult:strResult OrignImage:faceImg];
    NSMethodSignature *sig = [self methodSignatureForSelector:@selector(praseTrackResult:OrignImage:)];
    if (!sig) return ;
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setTarget:self];
    [invocation setSelector:@selector(praseTrackResult:OrignImage:)];
    [invocation setArgument:&strResult atIndex:2];
    [invocation setArgument:&faceImg atIndex:3];
    [invocation retainArguments];
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil  waitUntilDone:NO];
    
    faceImg=nil;
    
    CMSampleBufferRef filterImageBuffer;
//    return filterImageBuffer;
}

- (void)faceImagePixelBufferFromPlatform:(CVPixelBufferRef)pixelBuffer isFront:(BOOL)isFront{
    
    self.isFront = isFront;
    
    CVPixelBufferRef filterPixelImageBuffer;
//    return filterPixelImageBuffer;
}



/*
 人脸识别
 */
-(void)praseTrackResult:(NSString*)result OrignImage:(IFlyFaceImage*)faceImg{
    
    if(!result){
        return;
    }
    
    @try {
        NSError* error;
        NSData* resultData=[result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* faceDic=[NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
        resultData=nil;
        if(!faceDic){
            return;
        }
        
        NSString* faceRet=[faceDic objectForKey:KCIFlyFaceResultRet];
        NSArray* faceArray=[faceDic objectForKey:KCIFlyFaceResultFace];
        faceDic=nil;
        
        int ret=0;
        if(faceRet){
            ret=[faceRet intValue];
        }
        //没有检测到人脸或发生错误
        if (ret || !faceArray || [faceArray count]<1) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self hideFace];
            } ) ;
            return;
        }
        
        //检测到人脸
        NSMutableArray *arrPersons = [NSMutableArray array] ;
        
        for(id faceInArr in faceArray){
            
            if(faceInArr && [faceInArr isKindOfClass:[NSDictionary class]]){
                
                NSDictionary* positionDic=[faceInArr objectForKey:KCIFlyFaceResultPosition];
                NSString* rectString=[self praseDetect:positionDic OrignImage: faceImg];
                positionDic=nil;
                
                NSDictionary* landmarkDic=[faceInArr objectForKey:KCIFlyFaceResultLandmark];
                NSMutableArray* strPoints=[self praseAlign:landmarkDic OrignImage:faceImg];
                landmarkDic=nil;
                
                NSMutableDictionary *dicPerson = [NSMutableDictionary dictionary] ;
                if(rectString){
                    [dicPerson setObject:rectString forKey:RECT_KEY];
                }
                if(strPoints){
                    [dicPerson setObject:strPoints forKey:POINTS_KEY];
                }
                
                strPoints=nil;
                
                [dicPerson setObject:@"0" forKey:RECT_ORI];
                [arrPersons addObject:dicPerson] ;
                
                dicPerson=nil;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self showFaceLandmarksAndFaceRectWithPersonsArray:arrPersons];
                } ) ;
            }
        }
        faceArray=nil;
    }
    @catch (NSException *exception) {
        NSLog(@"prase exception:%@",exception.name);
    }
    @finally {
    }
    
}


/*
 检测面部特征点
 */
-(NSMutableArray*)praseAlign:(NSDictionary* )landmarkDic OrignImage:(IFlyFaceImage*)faceImg{
    
    if(!landmarkDic){
        return nil;
    }
    // 判断摄像头方向
    BOOL isFrontCamera = self.isFront;
    
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat widthScaleBy = self.viewRect.size.width / faceImg.height;
    CGFloat heightScaleBy = self.viewRect.size.height / faceImg.width;
    
    NSMutableArray *arrStrPoints = [NSMutableArray array] ;
    NSEnumerator* keys=[landmarkDic keyEnumerator];
    for(id key in keys){
        id attr=[landmarkDic objectForKey:key];
        if(attr && [attr isKindOfClass:[NSDictionary class]]){
            
            id attr=[landmarkDic objectForKey:key];
            CGFloat x=[[attr objectForKey:KCIFlyFaceResultPointX] floatValue];
            CGFloat y=[[attr objectForKey:KCIFlyFaceResultPointY] floatValue];
            
            CGPoint p = CGPointMake(y,x);
            
            if(!isFrontCamera){
                p=pSwap(p);
                p=pRotate90(p, faceImg.height, faceImg.width);
            }
            
            p=pScale(p, widthScaleBy, heightScaleBy);
            
            [arrStrPoints addObject:NSStringFromCGPoint(p)];
            
        }
    }
    NSLog(@"arrStrPoints %@",arrStrPoints);
    return arrStrPoints;
    
}


#pragma mark - 人脸识别相关方法
// 检测到人脸
- (void) showFaceLandmarksAndFaceRectWithPersonsArray:(NSMutableArray *)arrPersons{
    if (self.viewCanvas.hidden) {
        self.viewCanvas.hidden = NO ;
    }
    self.viewCanvas.arrPersons = arrPersons ;
    [self.viewCanvas setNeedsDisplay];
}

// 没有检测到人脸或发生错误
- (void) hideFace {
    if (!self.viewCanvas.hidden) {
        [UIView animateWithDuration:1.0 animations:^{
            self.viewCanvas.hidden = YES ;
        }];
    }
}


/*
 检测脸部轮廓
 */
-(NSString*)praseDetect:(NSDictionary* )positionDic OrignImage:(IFlyFaceImage*)faceImg{
    
    if(!positionDic){
        return nil;
    }
    
    // 判断摄像头方向
    BOOL isFrontCamera = self.isFront;
    
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat widthScaleBy = self.viewRect.size.width / faceImg.height;
    CGFloat heightScaleBy = self.viewRect.size.height / faceImg.width;
    
    CGFloat bottom =[[positionDic objectForKey:KCIFlyFaceResultBottom] floatValue];
    CGFloat top=[[positionDic objectForKey:KCIFlyFaceResultTop] floatValue];
    CGFloat left=[[positionDic objectForKey:KCIFlyFaceResultLeft] floatValue];
    CGFloat right=[[positionDic objectForKey:KCIFlyFaceResultRight] floatValue];
    
    float cx = (left+right)/2;
    float cy = (top + bottom)/2;
    float w = right - left;
    float h = bottom - top;
    
    float ncx = cy ;
    float ncy = cx ;
    
    CGRect rectFace = CGRectMake(ncx-w/2 ,ncy-w/2 , w, h);
    
    if(!isFrontCamera){
        rectFace=rSwap(rectFace);
        rectFace=rRotate90(rectFace, faceImg.height, faceImg.width);
        
    }
    
    rectFace=rScale(rectFace, widthScaleBy, heightScaleBy);
    rectFace = CGRectMake(rectFace.origin.x, rectFace.origin.y, rectFace.size.width, rectFace.size.height);
    return NSStringFromCGRect(rectFace);
    
}


- (IFlyFaceImage *) faceImageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer{
    
    //获取灰度图像数据
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    uint8_t *lumaBuffer  = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer,0);
    size_t width  = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CGColorSpaceRef grayColorSpace = CGColorSpaceCreateDeviceGray();
    
    CGContextRef context=CGBitmapContextCreate(lumaBuffer, width, height, 8, bytesPerRow, grayColorSpace,0);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    IFlyFaceDirectionType faceOrientation=[self faceImageOrientation];
    
    IFlyFaceImage* faceImage=[[IFlyFaceImage alloc] init];
    if(!faceImage){
        return nil;
    }
    
    CGDataProviderRef provider = CGImageGetDataProvider(cgImage);
    
    faceImage.data= (__bridge_transfer NSData*)CGDataProviderCopyData(provider);
    faceImage.width=width;
    faceImage.height=height;
    faceImage.direction=faceOrientation;
    
    CGImageRelease(cgImage);
    CGContextRelease(context);
    CGColorSpaceRelease(grayColorSpace);

    return faceImage;
}

#pragma mark - 判断视频帧方向
-(IFlyFaceDirectionType)faceImageOrientation {
    
    IFlyFaceDirectionType faceOrientation=IFlyFaceDirectionTypeLeft;
    BOOL isFrontCamera = self.isFront;
    switch (self.interfaceOrientation) {
        case UIDeviceOrientationPortrait:{//
            faceOrientation=IFlyFaceDirectionTypeLeft;
        }
            break;
        case UIDeviceOrientationPortraitUpsideDown:{
            faceOrientation=IFlyFaceDirectionTypeRight;
        }
            break;
        case UIDeviceOrientationLandscapeRight:{
            faceOrientation=isFrontCamera?IFlyFaceDirectionTypeUp:IFlyFaceDirectionTypeDown;
        }
            break;
        default:{//
            faceOrientation=isFrontCamera?IFlyFaceDirectionTypeDown:IFlyFaceDirectionTypeUp;
        }
            break;
    }
    
    return faceOrientation;
}


#pragma mark -- config button usage

- (void)configButton{
    
    CGFloat buttonWidth = self.viewRect.size.width / 5;
    CGFloat buttonHeight = self.viewRect.size.width / 480 * 640 + 5;
    
    self.firstStyleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.firstStyleButton.frame = CGRectMake(buttonWidth * 0, buttonHeight, buttonWidth, buttonWidth + 20);
    UILabel *firstLabel = [[UILabel alloc] initWithFrame:CGRectMake(buttonWidth/8, buttonWidth, buttonWidth - buttonWidth/4, 20)];
    [firstLabel setText:@"广告魔法"];
    [firstLabel setTextColor:[UIColor grayColor]];
    [firstLabel setTextAlignment:NSTextAlignmentCenter];
    [firstLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [self.firstStyleButton addSubview:firstLabel];
    [self.firstStyleButton setImage:[UIImage imageNamed:@"elemeIcon"] forState:UIControlStateNormal];
    self.firstStyleButton.imageEdgeInsets = UIEdgeInsetsMake(buttonWidth/8,buttonWidth/8,buttonWidth/8 + 20,buttonWidth/8);
    self.firstStyleButton.tag = 100;
    [self.firstStyleButton addTarget:self action:@selector(styleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.firstStyleButton];
    
    self.secondStyleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.secondStyleButton.frame = CGRectMake(buttonWidth * 1, buttonHeight, buttonWidth, buttonWidth + 20);
    [self.secondStyleButton setImage:[UIImage imageNamed:@"cocacolaIcon"] forState:UIControlStateNormal];
    self.secondStyleButton.imageEdgeInsets = UIEdgeInsetsMake(buttonWidth/8,buttonWidth/8,buttonWidth/8 + 20,buttonWidth/8);
    UILabel *secondLabel = [[UILabel alloc] initWithFrame:CGRectMake(buttonWidth/8, buttonWidth, buttonWidth - buttonWidth/4, 20)];
    [secondLabel setText:@"品牌魔法"];
    [secondLabel setTextColor:[UIColor grayColor]];
    [secondLabel setTextAlignment:NSTextAlignmentCenter];
    [secondLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [self.secondStyleButton addSubview:secondLabel];
    self.secondStyleButton.tag = 101;
    [self.secondStyleButton addTarget:self action:@selector(styleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.secondStyleButton];
    
    self.thirdStyleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.thirdStyleButton.frame = CGRectMake(buttonWidth * 2, buttonHeight, buttonWidth, buttonWidth + 20);
    [self.thirdStyleButton setImage:[UIImage imageNamed:@"newYearIcon"] forState:UIControlStateNormal];
    self.thirdStyleButton.imageEdgeInsets = UIEdgeInsetsMake(buttonWidth/8,buttonWidth/8,buttonWidth/8 + 20,buttonWidth/8);
    UILabel *thirdLabel = [[UILabel alloc] initWithFrame:CGRectMake(buttonWidth/8, buttonWidth, buttonWidth - buttonWidth/4, 20)];
    [thirdLabel setText:@"新年魔法"];
    [thirdLabel setTextColor:[UIColor grayColor]];
    [thirdLabel setTextAlignment:NSTextAlignmentCenter];
    [thirdLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [self.thirdStyleButton addSubview:thirdLabel];
    self.thirdStyleButton.tag = 102;
    [self.thirdStyleButton addTarget:self action:@selector(styleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.thirdStyleButton];
    
    self.fourthStyleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fourthStyleButton.frame = CGRectMake(buttonWidth * 3, buttonHeight, buttonWidth, buttonWidth + 20);
    [self.fourthStyleButton setImage:[UIImage imageNamed:@"earIcon"] forState:UIControlStateNormal];
    self.fourthStyleButton.imageEdgeInsets = UIEdgeInsetsMake(buttonWidth/8,buttonWidth/8,buttonWidth/8 + 20,buttonWidth/8);
    UILabel *fourthLabel = [[UILabel alloc] initWithFrame:CGRectMake(buttonWidth/8, buttonWidth, buttonWidth - buttonWidth/4, 20)];
    [fourthLabel setText:@"趣味魔法"];
    [fourthLabel setTextColor:[UIColor grayColor]];
    [fourthLabel setTextAlignment:NSTextAlignmentCenter];
    [fourthLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [self.fourthStyleButton addSubview:fourthLabel];
    self.fourthStyleButton.tag = 103;
    [self.fourthStyleButton addTarget:self action:@selector(styleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.fourthStyleButton];
    
    self.fifthStyleButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fifthStyleButton.frame = CGRectMake(buttonWidth * 4, buttonHeight, buttonWidth, buttonWidth + 20);
    [self.fifthStyleButton setImage:[UIImage imageNamed:@"seaIcon"] forState:UIControlStateNormal];
    self.fifthStyleButton.imageEdgeInsets = UIEdgeInsetsMake(buttonWidth/8,buttonWidth/8,buttonWidth/8 + 20,buttonWidth/8);
    UILabel *fifthLabel = [[UILabel alloc] initWithFrame:CGRectMake(buttonWidth/8, buttonWidth, buttonWidth - buttonWidth/4, 20)];
    [fifthLabel setText:@"少女魔法"];
    [fifthLabel setTextColor:[UIColor grayColor]];
    [fifthLabel setTextAlignment:NSTextAlignmentCenter];
    [fifthLabel setFont:[UIFont systemFontOfSize:12.0f]];
    [self.fifthStyleButton addSubview:fifthLabel];
    self.fifthStyleButton.tag = 104;
    [self.fifthStyleButton addTarget:self action:@selector(styleButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.fifthStyleButton];
    
}

- (void)styleButtonTapped:(UIButton *)sender{
    
    [self configAllViewTransparent];
    @try {
        switch (sender.tag) {
            case 100:
                self.viewCanvas.backgroundMap = [UIImage imageNamed:@"eleme-bg"];
                self.viewCanvas.leftEarMap = [UIImage imageNamed:@"elemeLeftEar"];
                self.viewCanvas.rightEarMap = [UIImage imageNamed:@"elemeRightEar"];
                break;
            case 101:
                self.viewCanvas.leftEarMap = [UIImage imageNamed:@"cococolaLeftEar"];
                self.viewCanvas.rightEarMap = [UIImage imageNamed:@"cococolaRightEar"];
                self.viewCanvas.backgroundMap = [UIImage imageNamed:@"cococolaBg"];
                break;
            case 102:
                self.viewCanvas.headMap = [UIImage imageNamed:@"newyearHear"];
                self.viewCanvas.allbackgroundMap = [UIImage imageNamed:@"newyearBack"];
                break;
            case 103:
                self.viewCanvas.leftEarMap = [UIImage imageNamed:@"leftEarMeng"];
                self.viewCanvas.rightEarMap = [UIImage imageNamed:@"rightEarMeng"];
                self.viewCanvas.noseMap = [UIImage imageNamed:@"strawberryLeft"];
                break;
            case 104:
                self.viewCanvas.backgroundMap = [UIImage imageNamed:@"seaback"];
                self.viewCanvas.facialTextureMap = [UIImage imageNamed:@"seaface"];
                self.viewCanvas.bodyMap = [UIImage imageNamed:@"seabody"];
                break;
            case 105:
                
                break;
            default:
                break;
        }
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
}


- (void)saveButtonTapped:(UIButton *)sender{
    
//    [self.videoCamera rotateCamera];
    //    // 录像文件
    //    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    //    unlink([pathToMovie UTF8String]);
    //    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    //
    //    // 配置录制信息
    //    movieWriter = [[MSGPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480, 640)];
    //    movieWriter.delegate = self;
    //
    ////    movieWriter.encodingLiveVideo = YES;
    //
    //    [self.blendFilter addTarget:movieWriter];
    //    // 保存到相册
    //    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    //        [beautifyFilter removeTarget:movieWriter];
    //        [movieWriter finishRecording];
    //        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    //        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(pathToMovie))
    //        {
    //            [library writeVideoAtPathToSavedPhotosAlbum:movieURL completionBlock:^(NSURL *assetURL, NSError *error)
    //             {
    //                 dispatch_async(dispatch_get_main_queue(), ^{
    //
    //                     if (error) {
    //                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存失败" message:nil
    //                                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    //                         [alert show];
    //                     } else {
    //                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存成功" message:nil
    //                                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    //                         [alert show];
    //                     }
    //                 });
    //             }];
    //        }
    //        else {
    //            NSLog(@"error mssg)");
    //        }
    //    });
}




- (void)configAllViewTransparent{
    self.viewCanvas.noseMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.headMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.eyesMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.bodyMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.mouthMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.leftEarMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.rightEarMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.backgroundMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.allbackgroundMap = [UIImage imageNamed:@"transparentBack"];
    self.viewCanvas.facialTextureMap = [UIImage imageNamed:@"transparentBack"];
}


@end
