//! @file
//!
//! Copyright (c) 2020-Present Memfault, Inc.
//! See LICENSE for details

#import "MemfaultCloud.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MemfaultApi (Internal)
- (instancetype)initApiWithSession:(NSURLSession *)session
                        projectKey:(NSString *)projectKey
                        apiBaseURL:(NSURL *)apiBaseURL
                    ingressBaseURL:(NSURL *)ingressBaseURL
                     chunksBaseURL:(NSURL *)chunksBaseURL;

- (void)postStatusEvent:(NSString *)eventName deviceInfo:(MemfaultDeviceInfo *_Nullable)deviceInfo userInfo:(NSDictionary *_Nullable)userInfo;

- (NSURLSessionDownloadTask *)downloadFile:(NSURL *)url delegate:(nullable id<NSURLSessionDelegate>)delegate;

- (void)postChunks:(NSArray<NSData *> *_Nonnull)chunks
      deviceSerial:(NSString *_Nonnull)deviceSerial
        completion:(void(^)(NSError *_Nullable error))completion
          boundary:(NSString *_Nullable)boundary;

- (void)postCoredump:(NSData *)coredumpData;

- (void)postWatchEvent:(id)jsonBlob;
@end

NS_ASSUME_NONNULL_END
