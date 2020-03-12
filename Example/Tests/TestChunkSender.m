//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

@import Specta;
@import Expecta;
@import OCHamcrest;
@import OCMockito;

#import "MFLTChunkSender.h"

#import "MemfaultApi.h"
#import "MFLTBackoff.h"
#import "MFLTTemporaryChunkQueue.h"

SpecBegin(MFLTChunkSender)

describe(@"MFLTChunkSender", ^{
    NSString *testSerial1 = @"TEST_ONE";
    NSData *testChunk1 = [@"CHUNK1" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *testChunk2 = [@"CHUNK2" dataUsingEncoding:NSUTF8StringEncoding];
    NSError *testError = [NSError errorWithDomain:@"" code:-1 userInfo:nil];

    __block MFLTChunkSender *sender = nil;
    __block MFLTTemporaryChunkQueue *queue = nil;
    __block dispatch_queue_t dispatchQueue = nil;
    __block dispatch_queue_t networkingQueue = nil;
    __block MemfaultApi *mockApi = nil;
    __block MFLTBackoff *mockBackoff = nil;
    __block NSMutableArray<NSArray<NSData *> *> *postedChunks = nil;
    __block NSArray<NSData *> *postedDeviceSerial = nil;
    __block NSError *postError = nil;
    __block void (^beforePostComplete)(void) = nil;

    beforeEach(^{
        queue = [[MFLTTemporaryChunkQueue alloc] init];
        dispatchQueue = dispatch_queue_create("com.memfault.test", NULL);
        networkingQueue = dispatch_queue_create("com.memfault.test.network", NULL);

        beforePostComplete = nil;
        postedChunks = [NSMutableArray array];
        postedDeviceSerial = nil;
        postError = nil;
        mockApi = mock([MemfaultApi class]);

        [givenVoid([mockApi postChunks:(id)anything() deviceSerial:(id)anything() completion:(id)anything()]) willDo:^id _Nonnull(NSInvocation * _Nonnull invocation) {
            __unsafe_unretained void(^block)(NSError * _Nullable error) = nil;
            __unsafe_unretained id chunks = nil;
            [invocation getArgument:&chunks atIndex:2];
            [postedChunks addObject:chunks];
            [invocation getArgument:&postedDeviceSerial atIndex:3];
            [invocation getArgument:&block atIndex:4];
            if (beforePostComplete) {
                beforePostComplete();
            }
            dispatch_async(networkingQueue, ^{
                block(postError);
                postError = nil;
            });
            return nil;
        }];

        mockBackoff = mock([MFLTBackoff class]);
        [given([mockBackoff bump]) willReturnDouble:0.0];

        sender = [[MFLTChunkSender alloc] initWithDeviceSerial:testSerial1 chunkQueue:queue dispatchQueue:dispatchQueue api:mockApi backoff:mockBackoff];
    });

    __auto_type waitUntilQueueDrained = ^{
         waitUntil(^(DoneCallback done) {
            while (queue.count > 0);
            done();
        });
    };

    describe(@"-postChunks:", ^{
        it(@"retries upon failure after a backoff period and resets backoff after successful post", ^{
            postError = testError;
            [sender postChunks:@[testChunk1]];

            waitUntilQueueDrained();

            [verify(mockBackoff) bump];
            [verify(mockBackoff) reset];
            [verifyCount(mockApi, times(2)) postChunks:@[testChunk1]
                                          deviceSerial:testSerial1
                                            completion:(id)anything()];
        });

        it(@"batches chunks", ^{
            beforePostComplete = ^{
                // These chunks are expected to get batched into a single post request because
                // they were enqueued while the previous post request was happening:
                [sender postChunks:@[testChunk2]];
                [sender postChunks:@[testChunk1]];
                [sender postChunks:@[testChunk2]];
                beforePostComplete = nil;
            };
            [sender postChunks:@[testChunk1]];

            waitUntilQueueDrained();

            [verify(mockApi) postChunks:@[testChunk1]
                           deviceSerial:testSerial1
                             completion:(id)anything()];

            [verify(mockApi) postChunks:@[testChunk2, testChunk1, testChunk2]
                           deviceSerial:testSerial1
                             completion:(id)anything()];
        });

        it(@"is a no-op when passing an empty array", ^{
            [sender postChunks:@[]];
            expect(sender.isPosting).to.beFalsy();
        });
    });
});

SpecEnd
