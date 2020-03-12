//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

@import Specta;
@import Expecta;
@import OCHamcrest;
@import OCMockito;

#import "MFLTTemporaryChunkQueue.h"

SpecBegin(MFLTTemporaryChunkQueue)

describe(@"MFLTTemporaryChunkQueue", ^{
    __block id<MemfaultChunkQueue> queue = nil;

    NSData *testChunk1 = [@"CHUNK1" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *testChunk2 = [@"CHUNK2" dataUsingEncoding:NSUTF8StringEncoding];

    beforeEach(^{
        MFLTTemporaryChunkQueueProvider *provider = [[MFLTTemporaryChunkQueueProvider alloc] init];
        queue = [provider queueWithDeviceSerial:@"TEST"];
        expect(queue).notTo.beNil();
    });

    describe(@"-peek:", ^{
        it(@"caps to the count of the queue", ^{
            [queue addChunks:@[testChunk1, testChunk2]];
            NSArray *items = [queue peek:100];
            expect(items).to.equal(@[testChunk1, testChunk2]);
        });
        it(@"slices from the head of the queue", ^{
            [queue addChunks:@[testChunk1, testChunk2]];
            NSArray *items = [queue peek:1];
            expect(items).to.equal(@[testChunk1]);
        });
    });

    describe(@"-drop:", ^{
        it(@"caps to the count of the queue", ^{
            [queue addChunks:@[testChunk1, testChunk2]];
            [queue drop:100];
            NSArray *items = [queue peek:2];
            expect(items).to.equal(@[]);
        });
        it(@"drops from the head of the queue", ^{
            [queue addChunks:@[testChunk1, testChunk2]];
            [queue drop:1];
            NSArray *items = [queue peek:2];
            expect(items).to.equal(@[testChunk2]);
        });
    });
});

SpecEnd

