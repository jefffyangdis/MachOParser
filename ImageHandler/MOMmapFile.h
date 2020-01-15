//
//  MOMmapFile.h
//
//  Created by 方阳 on 2019/3/20.
//  Copyright © 2019年 方阳. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger,YMMapFileMode){
    YMMapFileModeORead   =  0x01,
    YMMapFileModeOWrite  =  0x10,
    YMMapFileModeRW      =  0x11
};

@interface MOMmapFile : NSObject

@property (atomic,readonly)     size_t  fileLength;
@property (nonatomic,readonly)  BOOL    fileOpen;

- (instancetype)initWithPath:(NSString*)path mode:(YMMapFileMode)mode;

- (void)close;

- (NSData*)fetchDataWithOffset:(off_t)offset length:(size_t)len;

- (void)fillData:(NSMutableData*)data offset:(off_t)offset length:(size_t)len;

- (NSString*)fetchStringWithOffset:(off_t)offset length:(size_t)len;

@end

NS_ASSUME_NONNULL_END
