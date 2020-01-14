//! @file
//!
//! Copyright (c) 2020-Present Memfault, Inc.
//! See LICENSE for details

#import "MemfaultCloud.h"
#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

NS_ASSUME_NONNULL_BEGIN

@interface MemfaultDeviceInfo (Internal)
@property (readwrite, nonnull) NSString *softwareVersion;
@property (readwrite, nonnull) NSString *softwareType;
@property (readwrite, nonnull) NSString *deviceSerial;
@property (readwrite, nonnull) NSString *hardwareVersion;
@end

NS_ASSUME_NONNULL_END
