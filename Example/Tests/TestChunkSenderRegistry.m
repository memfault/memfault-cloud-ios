//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

@import Specta;
@import Expecta;
@import OCHamcrest;
@import OCMockito;

#import "MFLTChunkSenderRegistry.h"
#import "MFLTChunkSender.h"
#import "MFLTTemporaryChunkQueue.h"

SpecBegin(MFLTChunkSenderRegistry)

describe(@"MFLTChunkSenderRegistry", ^{
    __block MFLTChunkSenderRegistry *registry = nil;
    __block id<MFLTChunkSenderFactory> mockSenderFactory = nil;
    __block id<MemfaultChunkSender> mockSender1 = nil;
    __block id<MemfaultChunkSender> mockSender2 = nil;

    NSString *testSerial1 = @"TEST_ONE";
    NSString *testSerial2 = @"TEST_TWO";

    beforeEach(^{
        mockSenderFactory = mockProtocol(NSProtocolFromString(@"MFLTChunkSenderFactory"));
        mockSender1 = mock([MFLTChunkSender class]);
        mockSender2 = mock([MFLTChunkSender class]);
        [given([mockSenderFactory createSenderWithDeviceSerial:testSerial1]) willReturn:mockSender1];
        [given([mockSenderFactory createSenderWithDeviceSerial:testSerial2]) willReturn:mockSender2];
        registry = [MFLTChunkSenderRegistry createRegistry:mockSenderFactory];
    });

    describe(@"-senderWithDeviceSerial:", ^{
        it(@"calls the factory to create the sender if there isn't one already and returns the existing one otherwise", ^{
            id<MemfaultChunkSender> sender1 = [registry senderWithDeviceSerial:testSerial1];
            id<MemfaultChunkSender> sender1again = [registry senderWithDeviceSerial:testSerial1];
            expect(sender1).to.equal(mockSender1);
            expect(sender1).to.equal(sender1again);
            [verify(mockSenderFactory) createSenderWithDeviceSerial:testSerial1];
        });
    });

    describe(@"-postChunks", ^{
        it(@"calls -postChunks on each existing sender", ^{
            id<MemfaultChunkSender> sender1 = [registry senderWithDeviceSerial:testSerial1];
            id<MemfaultChunkSender> sender2 = [registry senderWithDeviceSerial:testSerial2];
            (void)sender1;
            (void)sender2;
            [registry postChunks];
            [verify(sender1) postChunks];
            [verify(sender2) postChunks];
        });
    });
    describe(@"-stop", ^{
        it(@"calls -stop on each existing sender", ^{
            id<MemfaultChunkSender> sender1 = [registry senderWithDeviceSerial:testSerial1];
            id<MemfaultChunkSender> sender2 = [registry senderWithDeviceSerial:testSerial2];
            (void)sender1;
            (void)sender2;
            [registry stop];
            [verify(sender1) stop];
            [verify(sender2) stop];
        });
    });
});

SpecEnd

