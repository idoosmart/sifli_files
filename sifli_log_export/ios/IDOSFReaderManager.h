//
//  IDOSDReaderManager.h
//  IDOSFReaderSDK
//
//  Created by cyf on 2025/4/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@protocol IDOSFReaderManagerDelegate <NSObject>

- (void)readAssetFlashLogDidComplete;

- (void)readFlashLogDidComplete;

- (void)readFlashLogProgress:(CGFloat)progress;

- (void)printLog:(NSString *)log;

@end

@interface IDOSFReaderManager : NSObject

@property (nonatomic,weak) id<IDOSFReaderManagerDelegate> delegate;

+ (IDOSFReaderManager *)shareInstance;

//初始化SDK
- (void)initSDK;

- (void)readAssetFlashLog:(NSString *)filePath deviceUUID:(NSString *)deviceUUID;

- (void)readFlashLog:(NSString *)filePath deviceUUID:(NSString *)deviceUUID;

@end

NS_ASSUME_NONNULL_END
