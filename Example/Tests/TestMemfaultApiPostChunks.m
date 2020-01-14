//! @file
//!
//! Copyright (c) 2020-Present Memfault, Inc.
//! See LICENSE for details

@import Specta;
@import Expecta;
@import OCHamcrest;
@import OCMockito;

#import "MemfaultApi.h"
#import "MFLTDeviceInfo.h"

SpecBegin(MemfaultApi_postChunks)

describe(@"MemfaultApi -postChunks", ^{
    NSString *projectKey = @"PROJECT_KEY";
    NSURL *apiChunksBaseURL = [NSURL URLWithString:@"//BASE_CHUNKS"];
    NSURL *apiDummyURL = [NSURL URLWithString:@"//DUMMY"];

    NSData *chunkData1 = [@"chunk1" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *chunkData2 = [@"chunk2" dataUsingEncoding:NSUTF8StringEncoding];

    __block MemfaultApi *api = nil;
    __block NSURLSession *mockSession = nil;
    __block NSString *boundary;
    __block NSMutableArray<NSHTTPURLResponse *> *mockResponses;
    __block NSError *requestError;
    __block NSData *responseData;
    __block dispatch_semaphore_t sema;
    __block NSURLRequest *request;
    __block NSError *postChunksError;

    beforeEach(^{
        mockSession = mock([NSURLSession class]);
        mockResponses = [NSMutableArray array];
        [mockResponses addObject:mock([NSHTTPURLResponse class])];
        api = [[MemfaultApi alloc] initApiWithSession:mockSession projectKey:projectKey apiBaseURL:apiDummyURL
                                       ingressBaseURL:apiDummyURL chunksBaseURL:apiChunksBaseURL];
        boundary = nil;
        request = nil;
        requestError = nil;
        responseData = nil;
        postChunksError = nil;
        sema = dispatch_semaphore_create(0);
        [given([mockSession dataTaskWithRequest:(id)anything() completionHandler:(id)anything()]) willDo:^id _Nonnull(NSInvocation * _Nonnull invocation) {
            __unsafe_unretained void(^block)(NSData *data, NSURLResponse *response, NSError *error) = nil;
            [invocation getArgument:&request atIndex:2];
            [invocation getArgument:&block atIndex:3];
            __auto_type mockResponse = [mockResponses firstObject];
            [mockResponses removeObjectAtIndex:0];
            block(responseData, mockResponse, requestError);
            return nil;
        }];
    });

    __auto_type postChunks = ^(NSArray *chunks){
         [api postChunks:chunks deviceSerial:@"TEST_SN" completion:^(NSError * _Nullable error) {
             postChunksError = error;
             dispatch_semaphore_signal(sema);
         } boundary:boundary];
         dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    };

    describe(@"-postChunks", ^{
        it(@"uses simple request for a single chunk", ^{
            [given([mockResponses[0] statusCode]) willReturnUnsignedInt:202];
            postChunks(@[chunkData1]);
            expect(request.URL.absoluteString).to.equal(@"//BASE_CHUNKS/api/v0/chunks/TEST_SN");
            expect(request.allHTTPHeaderFields[@"Content-Type"]).to.equal(@"application/octet-stream");
            expect(request.HTTPBody).to.equal(chunkData1);
            expect(postChunksError).to.beNil();
        });

        it(@"uses multipart/mixed request for a multiple chunks", ^{
            boundary = @"my_boundary";
            [given([mockResponses[0] statusCode]) willReturnUnsignedInt:202];
            postChunks(@[chunkData1, chunkData2]);
            expect(request.URL.absoluteString).to.equal(@"//BASE_CHUNKS/api/v0/chunks/TEST_SN");
            expect(request.allHTTPHeaderFields[@"Content-Type"]).to.match(@"^multipart/mixed; boundary=\"my_boundary\"");
            NSData *expectedBody = [@"--my_boundary\r\nContent-Length: 6Content-Type: application/octet-stream\r\n\r\nchunk1\r\n--my_boundary\r\nContent-Length: 6Content-Type: application/octet-stream\r\n\r\nchunk2\r\n--my_boundary--\r\n" dataUsingEncoding:NSUTF8StringEncoding];
            expect(request.HTTPBody).to.equal(expectedBody);
            expect(postChunksError).to.beNil();
        });

        it(@"errors out if called again while completion block of previous call has not yet been called", ^{
            [given([mockResponses[0] statusCode]) willReturnUnsignedInt:202];
            dispatch_semaphore_t firstCallSema = dispatch_semaphore_create(0);
            [api postChunks:@[chunkData1] deviceSerial:@"TEST_SN" completion:^(NSError * _Nullable error) {
                dispatch_semaphore_wait(firstCallSema, DISPATCH_TIME_FOREVER);
            }];
            waitUntil(^(DoneCallback done) {
                [api postChunks:@[chunkData1] deviceSerial:@"TEST_SN" completion:^(NSError * _Nullable error) {
                    expect(error.localizedDescription).to.equal(@"Not allowed to call -postChunks: while another call is still pending!");
                    expect(error.code).to.equal(MemfaultErrorCode_InvalidState);

                    dispatch_semaphore_signal(firstCallSema);
                    done();
                }];
            });
        });

        it(@"errors out if the internal networking call failed", ^{
            requestError = [NSError errorWithDomain:@"" code:-1 userInfo:nil];
            postChunks(@[chunkData1]);
            expect(postChunksError).to.equal(requestError);
        });

        it(@"errors out if the HTTP status was an error", ^{
            [given([mockResponses[0] statusCode]) willReturnUnsignedInt:403];
            // Ensure things don't blow up when something non-JSON is returned:
            responseData = [@"<html>Bla bla</html>" dataUsingEncoding:NSUTF8StringEncoding];
            postChunks(@[chunkData1]);
            expect(postChunksError.localizedDescription).to.equal(@"HTTP Error 403");
            expect(postChunksError.code).to.equal(MemfaultErrorCode_UnexpectedResponse);
        });

        it(@"errors out if the JSON error message if there was one", ^{
            [given([mockResponses[0] statusCode]) willReturnUnsignedInt:403];
            responseData = [NSJSONSerialization dataWithJSONObject:@{
                @"error": @{
                        @"message": @"Nice error message"
                },
            } options:0 error:NULL];
            postChunks(@[chunkData1]);
            expect(postChunksError.localizedDescription).to.equal(@"Nice error message");
            expect(postChunksError.code).to.equal(MemfaultErrorCode_UnexpectedResponse);
        });

        it(@"retries in case of HTTP status 503", ^{
            [given([mockResponses[0] statusCode]) willReturnUnsignedInt:503];
            [given([mockResponses[0] allHeaderFields]) willReturn:@{
                @"Retry-After": @"1"
            }];

            [mockResponses addObject:mock([NSHTTPURLResponse class])];

            postChunks(@[chunkData1]);
            expect(postChunksError).to.beNil();
        });
    });
});

SpecEnd
