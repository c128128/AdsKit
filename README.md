# AdsKit

## Installation
## Swift Package Manager
```swift
...

dependencies: [
    .package(url: "https://github.com/c128128/AdsKit.git", from: "2.0.0")
  ],
  targets: [
    .target(name: "MyProject", dependencies: ["AdsKit"])
  ]

...

```

## Setup:

1. Follow `Update your Info.plist` from official [`Google Mobile Ads SDK (iOS)`](https://developers.google.com/admob/ios/quick-start#update_your_infoplist)

2. Follow [`Request App Tracking Transparency authorization`](https://developers.google.com/admob/ios/ios14#request)

3. `AdsKit` automatically reads `adUnitID` from `Info.plist` and automatically `preload()` ads if needed.

```xml
<!-- example: Reward -->
<key>GADReward</key>
<string>ca-app-pub-3940256099942544/1712485313</string>

<!-- example: Interstitial -->
<key>GADInterstitial</key>
<string>ca-app-pub-3940256099942544/4411468910</string>
```

## Details:

* `AdsKit` will automatically check if minimum necessary settings are met, if not app will crash on startup.

* `AdsKit` will automatically `preload()` ads on app startup by default. Can be disabled, set `GADAutoload` in `Info.plist`, of type `Boolean` to `NO`.

* `AdsKit` automatically will request `requestTrackingAuthorization` on `load()`.
Please note: 
    * `GADAutoload` == `YES` (default), Tracking Permission will be shown on first app startup. 
    * `GADAutoload` == `NO`, Tracking Permission will be shown before calling `Banner`, `Interstitial` or `Reward` function.

### Banner
Create a `UIView` inherited from `Banner`.

<img width="257" alt="Screenshot 2022-06-03 at 17 53 12" src="https://user-images.githubusercontent.com/69604865/171901841-4a8230e9-526d-4579-a5b1-9032bc5558d2.png">

Don't forget to set the `adUnitID`.

<img width="260" alt="Screenshot 2022-06-03 at 17 54 33" src="https://user-images.githubusercontent.com/69604865/171901932-7b859b71-dcc3-4fc5-a02c-486639f48059.png">

If you want to set `Banner` only programmatically set empty string in `Ad UnitID` in the Storyboard.

```swift

@IBOutlet private weak var _banner: Banner!
...

// To set the Banner programmatically
self._banner.setAdUnitID("ca-app-pub-3940256099942544/2934735716")

// To remove the Banner
self._banner.setAdUnitID(nil)
```

### Interstitial
`Interstitial`. After ad was shown, new ad will be preloaded automatically.
```swift
Ads.Google.interstitial()
    .subscribe()
```

### Reward
`Reward`. After ad was shown, new ad will be preloaded automatically.
```swift
Ads.Google.reward()
    .subscribe()
```

### Reporting
`Reporting`. Subscribe to `Ads.Google.report` to observe events from Ad delegates.

```swift
Ads.Google.report
    .subscribe()
```

### TODO
- [ ] Add test devices.
