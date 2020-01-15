//
//  MOMmapFile.m
//
//  Created by 方阳 on 2019/3/20.
//  Copyright © 2019年 方阳. All rights reserved.
//

#import "MOMmapFile.h"
#include <sys/mman.h>

typedef void (^ext_cleanupBlock_t)();
void cpp_ext_executeCleanupBlock (__strong ext_cleanupBlock_t *block);
#define cpp_onExit __strong ext_cleanupBlock_t extblk __attribute__((cleanup(cpp_ext_executeCleanupBlock), unused)) = ^

void cpp_ext_executeCleanupBlock (__strong ext_cleanupBlock_t *block) {
    (*block)();
}

#define INVALID_FILEHANDLE -1
@interface MOMmapFile () {
    NSString*       _filePath;
    uint8_t*        _fileData;
    int             _fileHandle;
    YMMapFileMode   _fileMode;
}

@property (atomic,readwrite,assign) size_t fileLength;

@end

@implementation MOMmapFile

- (instancetype)initWithPath:(NSString*)path mode:(YMMapFileMode)mode{
    self = [super init];
    if( self ) {
        _filePath = path;
        _fileHandle = INVALID_FILEHANDLE;
        _fileData = nil;
        _fileMode = mode;
        [self open];
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

- (BOOL)fileOpen {
    return _fileHandle != INVALID_FILEHANDLE;
}

#pragma mark file handle
- (void)open {
//    cpp_onExit{
//        [self close];
//    };
    if( _fileHandle != INVALID_FILEHANDLE || _fileData != nullptr ){
        return;
    }
    
    uint32_t fileFlag = O_RDONLY, protFlag = PROT_NONE;
    switch ( _fileMode ) {
        case YMMapFileModeORead:
            fileFlag = O_RDONLY;
            protFlag = PROT_READ;
            break;
        case YMMapFileModeOWrite:
            fileFlag = O_WRONLY;
            protFlag = PROT_WRITE;
            break;
        case YMMapFileModeRW:
            fileFlag = O_RDWR;
            protFlag = PROT_WRITE;
            break;
        default:
            break;
    }
    if( _fileHandle == INVALID_FILEHANDLE ){
        _fileHandle = open(_filePath.UTF8String, fileFlag);
    }
    NSAssert(_fileHandle != INVALID_FILEHANDLE, @"YMMmapFile open failed:%@",_filePath);
    NSAssert(_fileData == nullptr, @"YMMmapFile fileData not null");
    
    self.fileLength = lseek(_fileHandle, 0, SEEK_END);
    lseek(_fileHandle, 0, SEEK_SET);
    
    _fileData = (uint8_t*)mmap(NULL, self.fileLength, protFlag, MAP_SHARED, _fileHandle, 0);
}

- (void)close {
    if( _fileData != nil ){
        munmap(_fileData, self.fileLength);
        _fileData = nil;
    }
    if( _fileHandle != INVALID_FILEHANDLE ){
        close(_fileHandle);
        _fileHandle = INVALID_FILEHANDLE;
    }
}

- (NSData*)fetchDataWithOffset:(off_t)offset length:(size_t)len {
    if( len > self.fileLength - offset ) {
        return nil;
    }
    NSData* data = [NSData dataWithBytes:_fileData+offset length:len];
    return data;
}

- (void)fillData:(NSMutableData*)data offset:(off_t)offset length:(size_t)len {
    if( len > self.fileLength - offset ) {
        return;
    }
    [data replaceBytesInRange:NSMakeRange(0, len) withBytes:_fileData+offset];
}

- (NSString*)fetchStringWithOffset:(off_t)offset length:(size_t)len {
    if( len > self.fileLength - offset ) {
        return nil;
    }
    return [[NSString alloc] initWithBytes:_fileData+offset length:len encoding:NSUTF8StringEncoding];
}
@end
