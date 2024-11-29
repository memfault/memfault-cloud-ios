# MemfaultCloud iOS Changelog

## v1.0.0

- Initial release: split off cloud API functionality from
  [Memfault](https://cocoapods.org/pods/Memfault) into a separate, open-source
  library [MemfaultCloud](https://cocoapods.org/pods/MemfaultCloud)
- Introduced `-[MemfaultApi postChunks:deviceSerial:completion:]`

## v2.0.0

- Added singleton property `+[MemfaultApi sharedApi]` and singleton
  configuration class method `+[MemfaultApi configureSharedApi:]`.
- Added a new set of APIs to make it much easier to post chunks, notably
  `-[MemfaultApi chunkSenderWithDeviceSerial:]` and `MemfaultChunkSender`.
- Removed `-[MemfaultApi postChunks:deviceSerial:completion:]` in favor of the
  new APIs.

## v2.0.1

- Fixed race conditions in `MemfaultChunkSender` that could cause chunks to get
  sent out multiple times or only after enqueuing another chunk.

## v2.1.0

- Increase chunk upload timeout from 10 seconds to 60 seconds.
- Reduce the maximum number of batched chunks from 1000 to 100.
- Retry uploading chunks when receiving HTTP 429 Too Many Request.
- Increased the mimimum retry delay for HTTP 429 or 503 errors from 5 seconds to
  5 minutes.
- Drop chunks after 100 consecutive upload errors, to prevent accumulating
  chunks indefinitely on the device.

## v2.2.0

- Add support for installing the library using Swift Package Manager.

## v2.2.1

- Fix formatting in Package.swift file

## v3.0.0

- Breaking: Raised the minimum deployment target to iOS 13.0.
- Upgraded test dependencies (OCHamcrest, OCMockito and Specta) to the latest
  versions.
- Fix: better handle unexpected responses from Memfault. Fixes
  [#3](https://github.com/memfault/memfault-cloud-ios/issues/3). Thanks to
  @bgomberg for reporting the issue!
