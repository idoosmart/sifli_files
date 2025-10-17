//
//  IDOSDReaderManager.m
//  IDOSFReaderSDK
//
//  Created by cyf on 2025/4/15.
//

#import "IDOSFReaderManager.h"
#import "SFReaderSDKA-Swift.h"

@interface IDOSFReaderManager()<SFReaderManagerDelegate>

@property (nonatomic,assign) NSInteger currentProgress;

@property (nonatomic,strong) NSString *filePath;

@property (nonatomic,strong) NSString *deviceUUID;

//是否在读取asset 日志
@property (nonatomic,assign) BOOL isReadAssetLog;

@property (nonatomic,assign) BOOL clear;

@end


@implementation IDOSFReaderManager

static IDOSFReaderManager *_mgr = nil;

+ (IDOSFReaderManager *)shareInstance{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _mgr = [[IDOSFReaderManager alloc] init];
    });
    return _mgr;
}

- (instancetype)init{
    if(self = [super init]){
    }
    return self;
}

+ (instancetype)alloc{
    if (_mgr) {
        NSException *exception = [NSException exceptionWithName:@"重复创建IDOSifliFlashLogManager单例对象异常" reason:@"请使用[IDOSifliFlashLogManager shareInstance]的单例方法." userInfo:nil];
        [exception raise];
    }
    return [super alloc];
}


- (void)initSDK{
    [SFReaderManager share].delegate = self;
    self.currentProgress = 0;
}

- (void)saveLog:(NSString *)log{
    if(self.delegate && [self.delegate respondsToSelector:@selector(printLog:)]){
        [self.delegate printLog:log];
    }
}

#pragma mark - 读取aseet 日志
- (void)readAssetFlashLog:(NSString *)filePath deviceUUID:(NSString *)deviceUUID{
   
    if(!filePath || filePath.length == 0 || !deviceUUID || deviceUUID.length == 0){
        NSString *desc = [NSString stringWithFormat:@"Flash readAssetFlashLog 传输过来的文件flash 日志路径为空 filePath ： %@  deviceUUID:%@",filePath,deviceUUID];
        [self saveLog:desc];
        return;
    }
    
    if(self.isReadAssetLog){
        return;
    }
    
    self.isReadAssetLog = YES;
    self.currentProgress = 0;
    self.filePath = filePath;
    self.deviceUUID = deviceUUID;
    self.clear = NO;
    
    [self saveLog:[NSString stringWithFormat:@"Flash 开始读取flash日志 Asset filePath:%@  deviceUUID:%@",filePath,deviceUUID]];

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readAssetFlashLogTimeOut) object:nil];
    [self performSelector:@selector(readAssetFlashLogTimeOut) withObject:nil afterDelay:60];
    [[SFReaderManager share] readAssetRequestWithDir:self.filePath targetIdentifier:self.deviceUUID];
}

- (void)readAssetFlashLogTimeOut{
    self.isReadAssetLog = NO;
    [self saveLog:@"Asset Flash 读取flash日志 超时"];
    [self readAssetFlashFinish];
}

- (void)readAssetFlashFinish{
    if(self.delegate && [self.delegate respondsToSelector:@selector(readAssetFlashLogDidComplete)]){
        [self.delegate readAssetFlashLogDidComplete];
    }
}

#pragma mark - 接到读取frash日志的通知
- (void)readFlashLog:(NSString *)filePath deviceUUID:(NSString *)deviceUUID{
    
    filePath = filePath;
    deviceUUID = deviceUUID;
    if(!filePath || filePath.length == 0 || !deviceUUID || deviceUUID.length == 0){
        NSString *desc = [NSString stringWithFormat:@"Flash 传输过来的文件flash 日志路径为空 filePath ： %@  deviceUUID:%@",filePath,deviceUUID];
        [self saveLog:desc];
        return;
    }
    
    if(self.isReadAssetLog){
        [self saveLog:@"正在读取 Asset Flash 读取flash日志"];
        return;
    }
    
    self.currentProgress = 0;
    self.filePath = filePath;
    self.deviceUUID = deviceUUID;
    self.clear = NO;
    
    [self saveLog:[NSString stringWithFormat:@"Flash 开始读取flash日志  filePath:%@  deviceUUID:%@",filePath,deviceUUID]];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readFlashLogTimeOut) object:nil];
    [self performSelector:@selector(readFlashLogTimeOut) withObject:nil afterDelay:60];
    //读取固件中异常的数据
    [[SFReaderManager share] readLogRequestWithLogDir:filePath targetIdentifier:deviceUUID];
}



- (void)readFlashLogTimeOut{
    [self saveLog:@"Flash 读取flash日志 超时"];
    [self notiAppFlashFinish];
}

- (void)notiAppFlashFinish{
    if(self.delegate && [self.delegate respondsToSelector:@selector(readFlashLogDidComplete)]){
        [self.delegate readFlashLogDidComplete];
    }
}

#pragma Mark - <SFReaderManagerDelegate>

- (void)readerManagerWithManager:(SFReaderManager *)manager complete:(SFReadLogResult *)result success:(BOOL)success error:(SFReaderError *)error{
    [self saveLog:[NSString stringWithFormat:@"Flash 读取flash日志结果success:%d error:%ld errorDes:%@ self.isReadAssetLog:%d",success,error.errorType,error.errorDes,self.isReadAssetLog]];
    
    
    //如果是正在读取asset 日志
    if(self.isReadAssetLog){
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readAssetFlashLogTimeOut) object:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if(!self.clear){
                [[SFReaderManager share] clearAssetRequestWithTargetIdentifier:self.deviceUUID];
                [self readAssetFlashFinish];
                self.clear = YES;
            }
            
        });
    }else{
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(readFlashLogTimeOut) object:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if(!self.clear){
                [[SFReaderManager share] clearLogRequestWithTargetIdentifier:self.deviceUUID];
                [self notiAppFlashFinish];
                self.clear = YES;
            }
        });
    }
    
    self.isReadAssetLog = NO;
}

- (void)readerManagerWithManager:(SFReaderManager * _Nonnull)manager progressWithtotalBytes:(NSInteger)progressWithtotalBytes completedBytes:(NSInteger)completedBytes {
    
    //0.35表示每个日志暂35%的进度，剩下的创建返回接口占30%；
    CGFloat pr = progressWithtotalBytes > 0 ? completedBytes * 1.0 / progressWithtotalBytes : 0;
    
    if(!self.isReadAssetLog){
        pr = pr * 0.7;
        if(self.delegate && [self.delegate respondsToSelector:@selector(readFlashLogProgress:)]){
            [self.delegate readFlashLogProgress:pr];
        }
    }
    
    NSInteger progress = completedBytes * 100 / progressWithtotalBytes;
    if(progress > 0 && progress % 10 == 0 && self.currentProgress != progress){
        self.currentProgress = progress;
        [self saveLog:[NSString stringWithFormat:@"Flash 读取flash日志进度 progress:%ld  completedBytes:%ld progressWithtotalBytes:%ld  self.isReadAssetLog：%d",progress,completedBytes,progressWithtotalBytes,self.isReadAssetLog]];
    }
}


- (void)readerManagerWithManager:(SFReaderManager * _Nonnull)manager updateBleState:(enum SFReaderBleManagerState)state {
    [self saveLog:[NSString stringWithFormat:@"Flash 读取flash日志结果 蓝牙状态变化state:%ld self.isReadAssetLog：%d",(long)state,self.isReadAssetLog]];
}


@end
