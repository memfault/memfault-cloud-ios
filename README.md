# MemfaultCloud iOS Library

## Demo App

The Xcode workspace `Example/MemfaultCloud.xcworkspace` contains a `DemoApp`
target. This is a very basic iOS app that demonstrates the functionality of this
library.

Before building the app, make sure to update the Project API Key in
`AppDelegate.swift`. To find your Project API Key, log in to
https://app.memfault.com/ and navigate to Settings.

```swift
class AppDelegate: UIResponder, UIApplicationDelegate {

    lazy var api: MemfaultApi = MemfaultApi(configuration: [
        kMFLTProjectKey: "<YOUR_PROJECT_KEY_HERE>",
    ])

    // ...
}
```

## Integration Guide

### Adding MemfaultCloud to your project

#### CocoaPods

In case you are using CocoaPods, you can add `MemfaultCloud` as a dependency to
your `Podfile`:

```
target 'MyApp' do
  pod 'MemfaultCloud'
end
```

It's probably a good idea to specify the version to use. See the [Podfile
documentation] for more information.

After adding the new dependency, run `pod install` inside your terminal, or from
CocoaPods.app.

#### Without dependency manager

To use `MemfaultCloud` without using a dependency manager such as CocoaPods,
just clone this repo and add the `.h` and `.m` files inside `MemfaultCloud`
folder to your project.

### Initialization

The `MemfaultApi` class is the main class of the MemfaultCloud library. It is
recommended to create only one `MemfaultApi` instance and use it across your
entire application. This ensures that requests to our servers are made
sequentially, when required.

When creating the instance, you will need to pass in a configuration dictionary.
The Project API Key is the only mandatory piece of configuration. To find your
Project API Key, log in to https://app.memfault.com/ and navigate to Settings.

```swift
var api: MemfaultApi = MemfaultApi(configuration: [
    kMFLTProjectKey: "<YOUR_PROJECT_KEY_HERE>",
])
```

### Getting the latest release

The `api.getLatestRelease` can be used to see if a device is up-to-date or
whether there is a new OTA update payload available for it.

The app is expected to be able to communicate with the device and fetch its
serial number, hardware version, current software version and type. Create a
`MemfaultDeviceInfo` object from that information and pass it to
`api.getLatestRelease`:

```swift
let deviceInfo = MemfaultDeviceInfo(
  deviceSerial: "DEMO_SERIAL",
  hardwareVersion: "proto",
  softwareVersion: "1.0.0",
  softwareType: "main")

api.getLatestRelease(for: deviceInfo) { (package, isUpToDate, error) in
  if error != nil {
    print("There was an error, handle it here.")
    return
  }
  if package == nil {
    print("Device is already up to date!")
    return
  }
  print("Update available: \(package!.description)")
}
```

The `MemfaultOtaPackage package` object has a `location` property, which
contains the URL to the OTA payload.

### Uploading Chunks

The Memfault Firmware SDK packetizes data that needs to be sent back to
Memfault's cloud into "chunks". See
[this tutorial for more information on the device/firmware details](https://docs.memfault.com/docs/embedded/data-from-firmware-to-the-cloud).

This iOS library contains a high-level API to submit the chunks to Memfault.

Getting the chunks out of the device and into the iOS app is part of the
integration work. The assumption is that you already have a communication
mechanism between the device and iOS app that can be leveraged.

```swift
// Array with Data objects, each with chunk bytes
// (produced by the Memfault Firmware SDK packetizer and sent
// to the iOS app to be posted to the cloud):
let chunks = ...

api.postChunks(chunks, deviceSerial: "DEMO_SERIAL") { (error) in
    if error != nil {
        print("There was an error. Retry sending these chunks later.")
        return
    }
    print("Succesfully sent chunks")
}
```

## API Documentation

`MemfaultCloud.h` contains detailed documentation for each API.

## Unit Tests

The Xcode workspace `Example/MemfaultCloud.xcworkspace` also contains a
`MemfaultCloud_Tests` scheme. To run the tests, select this scheme, then select
Product > Test (cmd + U).

## Changelog

See [CHANGELOG.md] file.

[changelog.md]: CHANGELOG.md
[podfile documentation]: https://guides.cocoapods.org/syntax/podfile.html#pod
