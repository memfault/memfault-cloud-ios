//! @file
//!
//! Copyright (c) 2020-Present Memfault, Inc.
//! See LICENSE for details

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@class MemfaultDeviceInfo;
@class MemfaultOtaPackage;

typedef NS_ENUM(NSUInteger, MemfaultLogLevel);

//! Configuration dictionary key to specify your Memfault API key.
extern NSString* const kMFLTProjectKey;

//! Configuration dictionary key to specify Memfault API url to use
//! (Not needed by default)
extern NSString* const kMFLTApiBaseURL;

//! Configuration dictionary key to specify Memfault Ingress API url to use
//! (Not needed by default)
extern NSString *const kMFLTApiIngressBaseURL;

//! Configuration dictionary key to specify Memfault Chunks API url to use
//! (Not needed by default)
extern NSString *const kMFLTApiChunksBaseURL;

//! Configuration dictionary key to specify NSURLSession to use.
//! (sharedSession is used by default)
extern NSString* const kMFLTApiUrlSession;

@interface MemfaultApi : NSObject
+ (instancetype)apiWithConfiguration:(NSDictionary *)configuration;

//! Get the latest OTA package release for a given device.
//! @param deviceInfo Device for which to retrieve the latest release.
//! @param block Completion block that will be called when the request has completed.
- (void)getLatestReleaseForDeviceInfo:(MemfaultDeviceInfo *_Nonnull)deviceInfo
                           completion:(nullable void(^)(MemfaultOtaPackage *_Nullable latestRelease, BOOL isDeviceUpToDate,
                                                        NSError *_Nullable error))block;

//! Uploads one or more chunks from the given device to Memfault for processing.
//! The chunks are to be obtained by the device through the Memfault Firmware SDK
//! (https://github.com/memfault/memfault-firmware-sdk)
//! It provides a streamlined way of getting arbitrary data (coredumps, events,
//! heartbeats, etc.) out of devices and into Memfault.
//! Check out the conceptual documentation (https://mflt.io/2MGMoIl) to learn more.
//! @note After calling -postChunks:deviceSerial:completion:, it is only allowed to call the method
//! again after the completion block has been called. If the completion block is called with an error,
//! the failed chunks must be sent again before sending the next set of chunks. Otherwise the
//! chunks will arrive out-of-order with data loss as result.
//! @param chunks An array of data objects, one for each chunk. The array must not be empty.
- (void)postChunks:(NSArray<NSData *> *_Nonnull)chunks
      deviceSerial:(NSString *_Nonnull)deviceSerial
        completion:(void(^)(NSError *_Nullable error))block;

@end


//! Information describing a device
@interface MemfaultDeviceInfo : NSObject
+ (instancetype)infoWithDeviceSerial:(NSString *)deviceSerial
                     hardwareVersion:(NSString *)hardwareVersion
                     softwareVersion:(NSString *)softwareVersion
                        softwareType:(NSString *)softwareType;
@property (readonly, nonnull) NSString *softwareVersion;
@property (readonly, nonnull) NSString *softwareType;
@property (readonly, nonnull) NSString *deviceSerial;
@property (readonly, nonnull) NSString *hardwareVersion;
@end


//! An OTA package.
//! @see MemfaultBluetoothDevice.checkForUpdate
@interface MemfaultOtaPackage : NSObject
@property NSURL *location;
@property NSString *releaseNotes;
@property NSString *softwareVersion;
@end

//! Global logging level for the Memfault iOS SDK as a whole.
extern MemfaultLogLevel gMFLTLogLevel;

typedef NS_ENUM(NSUInteger, MemfaultLogLevel) {
    MemfaultLogLevel_Debug,
    MemfaultLogLevel_Info,
    MemfaultLogLevel_Warning,
    MemfaultLogLevel_Error,
};

typedef NS_ENUM(NSUInteger, MemfaultErrorCode) {
    MemfaultErrorCode_Success = 0,
    MemfaultErrorCode_InvalidArgument = 1,
    MemfaultErrorCode_InternalError = 2,
    MemfaultErrorCode_InvalidState = 3,
    MemfaultErrorCode_Unsupported = 10,
    MemfaultErrorCode_UnexpectedResponse = 11,
    MemfaultErrorCode_NotFound = 12,
    MemfaultErrorCode_NotImplemented = 13,
    MemfaultErrorCode_TransportNotAvailable = 14,
    MemfaultErrorCode_EndpointNotFound = 15,
    MemfaultErrorCode_Disconnected = 16,
    MemfaultErrorCode_Timeout = 17,
    MemfaultErrorCode_AuthenticationFailure = 18,
    MemfaultErrorCode_PlatformSpecificBase = 100000,
};


NS_ASSUME_NONNULL_END
