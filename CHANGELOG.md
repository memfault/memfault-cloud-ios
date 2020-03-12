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
