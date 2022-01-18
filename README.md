# AdsKit

## How to use:

### `Google Mobile Ads SDK (iOS)` version `8.13.0`, [Release Notes](https://developers.google.com/admob/ios/rel-notes), [Latest SDK](https://developers.google.com/admob/ios/download)

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

<!-- example: Banner -->
<key>GADBanner</key>
<string>ca-app-pub-3940256099942544/2934735716</string>
```

## Details:

* `AdsKit` will automatically check if minimum necessary settings are met, if not app will crash on startup.

* `AdsKit` will automatically `preload()` ads on app startup by default. Can be disabled, set `GADAutoload` in `Info.plist`, of type `Boolean` to `NO`.

* `AdsKit` automatically will request `requestTrackingAuthorization` on `load()`.
Please note: 
    * `GADAutoload` == `YES` (default), Tracking Permission will be shown on first app startup. 
    * `GADAutoload` == `NO`, Tracking Permission will be shown before calling `Banner`, `Interstitial` or `Reward` function.

### Banner
`Banner` automagically appear if `GADBanner` was defined in `Info.plist` with correct `adUnitID`.

If `GADAutoload` == `NO`, You need to call `Ads.Google.banner(.show)` to show the banner.

```swift
// Hide Banner
Ads.Google.banner(.remove)

// Show Banner
Ads.Google.banner(.show)
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