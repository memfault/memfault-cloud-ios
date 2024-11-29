//! @file
//!
//! Copyright (c) Memfault, Inc.
//! See LICENSE for details

@import Specta;
@import Expecta;
@import OCHamcrest;
@import OCMockito;

#import "MemfaultApi.h"
#import "MFLTDeviceInfo.h"

SpecBegin(MemfaultApi)

describe(@"MemfaultApi", ^{

    __block MemfaultApi *api = nil;
    __block NSURLSession *mockSession = nil;
    NSString *projectKey = @"PROJECT_KEY";
    NSURL *apiBaseURL = [NSURL URLWithString:@"//BASE"];
    NSURL *apiIngressBaseURL = [NSURL URLWithString:@"//BASE_INGRESS"];
    NSURL *apiChunksBaseURL = [NSURL URLWithString:@"//BASE_CHUNKS"];
    __block void(^dataTaskCompletion)(NSData *data, NSURLResponse *response, NSError *error) = nil;

    MemfaultDeviceInfo *deviceInfo = [MemfaultDeviceInfo infoWithDeviceSerial:@"ID"
                                                              hardwareVersion:@"v1"
                                                              softwareVersion:@"v2"
                                                                 softwareType:@"main"];

    MemfaultDeviceInfo *legacyDeviceInfo = [MemfaultDeviceInfo infoWithDeviceSerial:@"ID"
                                                                    hardwareVersion:@"v1"
                                                                    softwareVersion:@"v2"
                                                                       softwareType:@""];
    NSError *testError = [NSError errorWithDomain:@"test" code:-1 userInfo:nil];

    beforeEach(^{
        mockSession = mock([NSURLSession class]);
        api = [[MemfaultApi alloc] initApiWithSession:mockSession projectKey:projectKey apiBaseURL:apiBaseURL
                                       ingressBaseURL:apiIngressBaseURL chunksBaseURL:apiChunksBaseURL chunkQueueProvider:(id _Nonnull)nil];
    });

    __auto_type assertDataRequest = ^(NSString *expectedMethod, NSString *expectedURLString, id expectedBodyObject){
        HCArgumentCaptor *requestCaptor = [[HCArgumentCaptor alloc] init];
        HCArgumentCaptor *handlerCaptor = [[HCArgumentCaptor alloc] init];
        [verify(mockSession) dataTaskWithRequest:(id)requestCaptor completionHandler:(id)handlerCaptor];
        NSURLRequest *request = (NSURLRequest *)requestCaptor.value;
        expect(request.HTTPMethod).to.equal(expectedMethod);
        expect(request.allHTTPHeaderFields[@"Memfault-Project-Key"]).to.equal(projectKey);
        expect(request.allHTTPHeaderFields[@"Accept"]).to.equal(@"application/json");
        if (expectedBodyObject) {
            if ([expectedBodyObject isKindOfClass:[NSData class]]) {
                expect(request.HTTPBody).to.equal(expectedBodyObject);
                expect(request.allHTTPHeaderFields[@"Content-Type"]).to.equal(@"application/octet-stream");
            } else {
                NSError *jsonError = nil;
                id bodyObject = [NSJSONSerialization JSONObjectWithData:request.HTTPBody options:0 error:&jsonError];
                expect(bodyObject).to.equal(expectedBodyObject);
                expect(jsonError).to.beNil();
                expect(request.allHTTPHeaderFields[@"Content-Type"]).to.equal(@"application/json");
            }
        } else {
            expect(request.allHTTPHeaderFields[@"Content-Type"]).to.equal(@"application/json");
        }
        expect(request.URL.absoluteString).to.equal(expectedURLString);
        dataTaskCompletion = handlerCaptor.value;
    };

    __auto_type mockDataTaskCompleted = ^(NSData *data, NSURLResponse *response, NSError *error) {
        expect(dataTaskCompletion).notTo.beNil(); // Make sure to call assertDataRequest() first in your test!
        dataTaskCompletion(data, response, error);
    };

    describe(@"-postStatusEvent:deviceInfo:userInfo:completion:", ^{
        NSString *eventId = @"event";

        it(@"is a noop when deviceInfo is nil", ^{
            [api postStatusEvent:eventId deviceInfo:nil userInfo:nil];
            [verifyCount(mockSession, never()) dataTaskWithRequest:anything()
                                                 completionHandler:anything()];
        });

        it(@"works with userInfo", ^{
            NSDictionary *userInfo = @{ @"foo": @(123), @"bar": @[]};
            [api postStatusEvent:eventId deviceInfo:deviceInfo userInfo:userInfo];
            id expectedBodyObject = @[@{ @"type": eventId,
                                         @"hardware_version": deviceInfo.hardwareVersion,
                                         @"device_serial": deviceInfo.deviceSerial,
                                         @"software_version": deviceInfo.softwareVersion,
                                         @"software_type": deviceInfo.softwareType,
                                         @"sdk_version": @"0.5.0",
                                         @"user_info": userInfo,
                                         }];
            assertDataRequest(@"POST", @"//BASE_INGRESS/api/v0/events", expectedBodyObject);
        });

        it(@"works without userInfo", ^{
            [api postStatusEvent:eventId deviceInfo:deviceInfo userInfo:nil];
            id expectedBodyObject = @[@{ @"type": eventId,
                                         @"hardware_version": deviceInfo.hardwareVersion,
                                         @"device_serial": deviceInfo.deviceSerial,
                                         @"software_version": deviceInfo.softwareVersion,
                                         @"software_type": deviceInfo.softwareType,
                                         @"sdk_version": @"0.5.0",
                                         }];
            assertDataRequest(@"POST", @"//BASE_INGRESS/api/v0/events", expectedBodyObject);
        });

        it(@"works for legacy deviceInfo", ^{
            // No softwareType -- see MFLTBleDeviceInfoQuery:
            [api postStatusEvent:eventId deviceInfo:legacyDeviceInfo userInfo:nil];
            id expectedBodyObject = @[@{ @"type": eventId,
                                         @"hardware_version": deviceInfo.hardwareVersion,
                                         @"device_serial": deviceInfo.deviceSerial,
                                         @"fw_version": deviceInfo.softwareVersion,
                                         @"sdk_version": @"0.1.0",
                                         }];
            assertDataRequest(@"POST", @"//BASE_INGRESS/api/v0/events", expectedBodyObject);
        });
    });

    describe(@"-postCoredump", ^{
        it(@"works", ^{
            NSData *coredumpData = [@"such core" dataUsingEncoding:NSUTF8StringEncoding];
            [api postCoredump:coredumpData];
            assertDataRequest(@"POST", @"//BASE_INGRESS/api/v0/upload/coredump", coredumpData);
        });
    });

    describe(@"-getLatestReleaseForDeviceInfo:completion:", ^{
        NSString *expectedURLString = @"//BASE/api/v0/releases/latest?current_version=v2&device_serial=ID&hardware_version=v1&software_type=main";
        __block NSHTTPURLResponse *mockResponse = nil;
        NSString *expectedMethod = @"GET";

        beforeEach(^{
            mockResponse = mock([NSHTTPURLResponse class]);
        });

        __auto_type getAssertCompletionBlock = ^(DoneCallback done, MemfaultOtaPackage * _Nullable expectedRelease,
                                                 BOOL expectedUpToDate, NSInteger expectedErrorCode){
            return ^(MemfaultOtaPackage * _Nullable latestRelease, BOOL isDeviceUpToDate, NSError * _Nullable error) {
                expect(latestRelease).to.equal(expectedRelease);
                expect(isDeviceUpToDate).to.equal(expectedUpToDate);
                expect(error.code).to.equal(expectedErrorCode);
                done();
            };
        };

        it(@"propagates errors from the data task", ^{
            waitUntil(^(DoneCallback done) {
                [api getLatestReleaseForDeviceInfo:deviceInfo completion:getAssertCompletionBlock(done, nil, NO, testError.code)];
                assertDataRequest(expectedMethod, expectedURLString, nil);
                mockDataTaskCompleted(nil, nil, testError);
            });
        });

        it(@"treats HTTP 204 as 'up to date'", ^{
            waitUntil(^(DoneCallback done) {
                [api getLatestReleaseForDeviceInfo:deviceInfo completion:getAssertCompletionBlock(done, nil, YES, 0)];
                assertDataRequest(expectedMethod, expectedURLString, nil);
                [given(mockResponse.statusCode) willReturnInt:204];
                mockDataTaskCompleted(nil, mockResponse, nil);
            });
        });

        it(@"propagates JSON parsing errors", ^{
            waitUntil(^(DoneCallback done) {
                NSData *bodyData = [@"{" dataUsingEncoding:NSUTF8StringEncoding];
                NSError *jsonError = nil;
                [NSJSONSerialization JSONObjectWithData:bodyData options:0 error:&jsonError];

                [api getLatestReleaseForDeviceInfo:deviceInfo completion:getAssertCompletionBlock(done, nil, NO, jsonError.code)];
                assertDataRequest(expectedMethod, expectedURLString, nil);
                [given(mockResponse.statusCode) willReturnInt:200];
                mockDataTaskCompleted(bodyData, mockResponse, nil);
            });
        });

        it(@"handles unexpected body of successful response", ^{
            NSArray<NSData *> *unexpectedResponses = @[
                // Empty response:
                [NSData data],
                // String:
                [@"\"a string\"" dataUsingEncoding:NSUTF8StringEncoding],
                // Empty object:
                [NSJSONSerialization dataWithJSONObject:@{} options:0 error:nil],
                // "artifacts" is not an array:
                [NSJSONSerialization dataWithJSONObject:@{@"artifacts": @{}, @"version": @"", @"notes": @""} options:0 error:nil],
                // artifact is not an object:
                [NSJSONSerialization dataWithJSONObject:@{@"artifacts": @[@"not an object"], @"version": @"", @"notes": @""} options:0 error:nil],
                // "url" does not exist:
                [NSJSONSerialization dataWithJSONObject:@{@"artifacts": @[@{}], @"version": @"", @"notes": @""} options:0 error:nil],
                // "url" is not a string:
                [NSJSONSerialization dataWithJSONObject:@{@"artifacts": @[@{@"url": @123}], @"version": @"", @"notes": @""} options:0 error:nil],
                // "version" does not exist:
                [NSJSONSerialization dataWithJSONObject:@{@"artifacts": @[@{@"url": @""}], @"notes": @""} options:0 error:nil],
                // "version" is not a string:
                [NSJSONSerialization dataWithJSONObject:@{@"artifacts": @[@{@"url": @""}], @"version": @123, @"notes": @""} options:0 error:nil],
                // "notes" does not exist:
                [NSJSONSerialization dataWithJSONObject:@{@"artifacts": @[@{@"url": @""}], @"version": @""} options:0 error:nil],
                // "notes" is not a string:
                [NSJSONSerialization dataWithJSONObject:@{@"artifacts": @[@{@"url": @""}], @"version": @"", @"notes": @123} options:0 error:nil],
            ];

            for (NSData *bodyData in unexpectedResponses) {
                waitUntil(^(DoneCallback done) {
                    [api getLatestReleaseForDeviceInfo:deviceInfo completion:getAssertCompletionBlock(done, nil, NO, MemfaultErrorCode_UnexpectedResponse)];
                    assertDataRequest(expectedMethod, expectedURLString, nil);
                    [given(mockResponse.statusCode) willReturnInt:200];
                    mockDataTaskCompleted(bodyData, mockResponse, nil);
                });
            }
        });

        it(@"propagates error when non-200 HTTP status is responded with", ^{
            waitUntil(^(DoneCallback done) {
                // NOTE: a JSON body is expected, even for all error responses!
                id bodyObj = @{@"error": @{ @"message": @"test"}};
                NSData *bodyData = [NSJSONSerialization dataWithJSONObject:bodyObj options:0 error:nil];

                [api getLatestReleaseForDeviceInfo:deviceInfo completion:getAssertCompletionBlock(done, nil, NO, MemfaultErrorCode_UnexpectedResponse)];
                assertDataRequest(expectedMethod, expectedURLString, nil);
                [given(mockResponse.statusCode) willReturnInt:403];
                mockDataTaskCompleted(bodyData, mockResponse, nil);
            });
        });

        it(@"handles error with unexpected response body", ^{
            NSArray<NSData *> *unexpectedResponses = @[
                // Empty response:
                [NSData data],
                // String:
                [@"\"a string\"" dataUsingEncoding:NSUTF8StringEncoding],
                // Empty object:
                [NSJSONSerialization dataWithJSONObject:@{} options:0 error:nil],
                // "error" is not an object:
                [NSJSONSerialization dataWithJSONObject:@{@"error": @123} options:0 error:nil],
                // "message" is not a string:
                [NSJSONSerialization dataWithJSONObject:@{@"error": @{ @"message": @123 }} options:0 error:nil],
            ];

            for (NSData *bodyData in unexpectedResponses) {
                waitUntil(^(DoneCallback done) {
                    [api getLatestReleaseForDeviceInfo:deviceInfo completion:getAssertCompletionBlock(done, nil, NO, MemfaultErrorCode_UnexpectedResponse)];
                    assertDataRequest(expectedMethod, expectedURLString, nil);
                    [given(mockResponse.statusCode) willReturnInt:403];
                    mockDataTaskCompleted(bodyData, mockResponse, nil);
                });
            }
        });
        
        it(@"works for legacy deviceInfo", ^{
            // No "software_type" query arg:
            NSString *expectedLegacyURLString = @"//BASE/api/v0/releases/latest?current_version=v2&device_serial=ID&hardware_version=v1";
            waitUntil(^(DoneCallback done) {
                [api getLatestReleaseForDeviceInfo:legacyDeviceInfo completion:getAssertCompletionBlock(done, nil, NO, 0)];
                assertDataRequest(expectedMethod, expectedLegacyURLString, nil);
                done();
            });
        });

        it(@"works", ^{
            waitUntil(^(DoneCallback done) {
                NSString *artifactURLString = @"http://test";
                NSString *version = @"v1.0.0";
                NSString *notes = @"shiny new stuff";
                id bodyObj = @{@"version": version,
                               @"notes": notes,
                               @"artifacts": @[@{@"url": artifactURLString}]};
                NSData *bodyData = [NSJSONSerialization dataWithJSONObject:bodyObj options:0 error:nil];

                MemfaultOtaPackage *expectedPackage = [[MemfaultOtaPackage alloc] init];
                expectedPackage.softwareVersion = version;
                expectedPackage.releaseNotes = notes;
                expectedPackage.location = [NSURL URLWithString:artifactURLString];

                [api getLatestReleaseForDeviceInfo:deviceInfo completion:getAssertCompletionBlock(done, expectedPackage, NO, 0)];
                assertDataRequest(expectedMethod, expectedURLString, nil);
                [given(mockResponse.statusCode) willReturnInt:200];
                mockDataTaskCompleted(bodyData, mockResponse, nil);
            });
        });
    });
});

SpecEnd
