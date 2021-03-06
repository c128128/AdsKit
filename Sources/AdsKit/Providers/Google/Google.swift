// swiftlint:disable nesting
import UIKit
import GoogleMobileAds
import UserMessagingPlatform
import RxRelay
import RxSwift
import AppTrackingTransparency

public extension Ads {
    final class Google {
        public enum Report {
            public enum Action {
                case click(String)
                case impression(String)
            }
            
            case banner(Action)
            case interstitial(Action)
            case reward(Action)
        }
        
        private static let APPLICATION_IDENTIFIER = "GADApplicationIdentifier"
        private static let SK_AD_NETWORK_ITEMS = "SKAdNetworkItems"
        private static let NS_USER_TRACKING_USAGE_DESCRIPTION = "NSUserTrackingUsageDescription"
        private static let NS_APP_TRANSPORT_SECURITY = "NSAppTransportSecurity"
        
        private static let AUTOLOADED_KEY = "GADAutoload"
        private static let REWARD_KEY = "GADReward"
        private static let INTERSTITIAL_KEY = "GADInterstitial"
        private static let TEST_DEVICES_KEY = "GADTestDevices"
        
        internal static let shared = Google()
        
        private let bag = DisposeBag()
        
        private static let _report = PublishSubject<Report>()
        
        fileprivate let tracking = Tracking()
        
        private var reward: Ads.Google.Reward?
        private var interstitial: Ads.Google.Interstitial?
        
        private init() {
            #if DEBUG
            Self.checkMinimumNecessarySettings()
            #endif
            
            GADMobileAds.sharedInstance().start(completionHandler: nil)
            GADMobileAds.sharedInstance().disableSDKCrashReporting()
            
            #if targetEnvironment(simulator)
            GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [GADSimulatorID]
            #else
            GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = Bundle.main.object(forInfoDictionaryKey: Self.TEST_DEVICES_KEY) as? [String] ?? []
            #endif
            
            if let key = Bundle.main.object(forInfoDictionaryKey: Self.REWARD_KEY) as? String {
                self.reward = Ads.Google.Reward(key: key)

                self.reward?.report
                    .map { .reward($0) }
                    .subscribe(Self._report)
                    .disposed(by: self.bag)
            }
            
            if let key = Bundle.main.object(forInfoDictionaryKey: Self.INTERSTITIAL_KEY) as? String {
                self.interstitial = Ads.Google.Interstitial(key: key)

                self.interstitial?.report
                    .map { .interstitial($0) }
                    .subscribe(Self._report)
                    .disposed(by: self.bag)
            }
        }
        
        #if DEBUG
        private static func checkMinimumNecessarySettings() {
            guard Bundle.main.object(forInfoDictionaryKey: Self.APPLICATION_IDENTIFIER) != nil else {
                fatalError("Looks like you forget to set \(Self.APPLICATION_IDENTIFIER) in Info.plist, more details here: https://developers.google.com/admob/ios/quick-start#update_your_infoplist")
            }
            
            guard Bundle.main.object(forInfoDictionaryKey: Self.SK_AD_NETWORK_ITEMS) != nil else {
                fatalError("Looks like you forget to set \(Self.SK_AD_NETWORK_ITEMS) in Info.plist, more details here: https://developers.google.com/admob/ios/quick-start#update_your_infoplist")
            }
            
            guard let networks = Bundle.main.object(forInfoDictionaryKey: Self.SK_AD_NETWORK_ITEMS) as? [[String: String]] else {
                fatalError("\(Self.SK_AD_NETWORK_ITEMS) has an invalid format, more details here: https://developers.google.com/admob/ios/quick-start#update_your_infoplist")
            }
            
            guard networks.contains(["SKAdNetworkIdentifier": "cstr6suwn9.skadnetwork"]) else {
                fatalError("\(Self.SK_AD_NETWORK_ITEMS) don't contains Google cstr6suwn9.skadnetwork network, more details here: https://developers.google.com/admob/ios/quick-start#update_your_infoplist")
            }
            
            guard Bundle.main.object(forInfoDictionaryKey: Self.NS_USER_TRACKING_USAGE_DESCRIPTION) != nil else {
                fatalError("Looks like you forget to set \(Self.NS_USER_TRACKING_USAGE_DESCRIPTION) in Info.plist, more details here: https://developers.google.com/admob/ios/ios14#request")
            }
            
            guard Bundle.main.object(forInfoDictionaryKey: Self.NS_APP_TRANSPORT_SECURITY) != nil else {
                fatalError("Looks like you forget to set \(Self.NS_APP_TRANSPORT_SECURITY) in Info.plist, more details here: https://developers.google.com/admob/ios/app-transport-security")
            }
        }
        #endif
        
        fileprivate func add(banner: AdsKit.Banner) {
            banner.adapter.report
                .map { .banner($0) }
                .subscribe(Self._report)
                .disposed(by: banner.bag)
        }
        
        internal static func isAutoloaded() -> Bool {
            return Bundle.main.object(forInfoDictionaryKey: Self.AUTOLOADED_KEY) as? Bool ?? true
        }
        
        internal static func load() {
            _ = Self.shared
        }
        
        public static var report: Observable<Report> {
            return Self._report
        }
        
        public static func reward(_ root: UIViewController) -> Single<Ads.Reward.Result> {
            guard let reward = Self.shared.reward else {
                fatalError("Looks like you forget to set in Info.plist the \(Self.REWARD_KEY), with AdUnitID.")
            }

            return Self.shared.tracking.request(from: root)
                .andThen(.deferred {
                    return reward.show(from: root)
                })
        }
        
        public static func interstitial(_ root: UIViewController) -> Completable {
            guard let interstitial = Self.shared.interstitial else {
                fatalError("Looks like you forget to set in Info.plist the \(Self.INTERSTITIAL_KEY), with AdUnitID.")
            }

            return Self.shared.tracking.request(from: root)
                .andThen(.deferred {
                    return interstitial.show(from: root)
                })
        }
    }
}

public final class Banner: UIView {
    fileprivate var adapter: Ads.Google.Banner!
    fileprivate var bag = DisposeBag()
    
    public func setAdUnitID(_ key: String?) {
        self.show(.no)
        self.bag = DisposeBag()
        self.adapter = nil
        
        let key = key ?? ""
        
        guard !key.isEmpty else {
            return
        }
        
        // swiftlint:disable:next force_unwrapping
        Ads.Google.shared.tracking.request(from: UIApplication.shared.delegate!.window!!.rootViewController!)
            .andThen(.deferred { [unowned self] in
                self.adapter = .init(key: key, size: .anchored)
                
                self.adapter.banner.translatesAutoresizingMaskIntoConstraints = false
                
                self.adapter.delegate.rx.methodInvoked(#selector(Ads.Google.BannerDelegate.bannerViewDidReceiveAd(_:)))
                    .subscribe(onNext: { [unowned self] _ in
                        self.show(.yes)
                    })
                    .disposed(by: self.bag)
                
                self.adapter.delegate.rx.methodInvoked(#selector(Ads.Google.BannerDelegate.bannerView(_:didFailToReceiveAdWithError:)))
                    .subscribe(onNext: { [unowned self] _ in
                        self.show(.no)
                    })
                    .disposed(by: self.bag)
                
                Ads.Google.shared.add(banner: self)
                
                return .empty()
            })
            .subscribe()
            .disposed(by: self.bag)
    }
    
    private enum Show {
        case yes
        case no
    }
    
    private func show(_ show: Show) {
        switch show {
            case .yes:
                guard let adapter = self.adapter else {
                    return
                }
            
                self.addSubview(adapter.banner)
            
                return self.constraints(.activate, adapter: adapter)
            
            case .no:
                guard let adapter = self.adapter else {
                    return
                }
            
                adapter.banner.removeFromSuperview()
                
                return self.constraints(.deactivate, adapter: adapter)
        }
    }
    
    private enum Activate {
        case activate
        case deactivate
    }
    
    private func constraints(_ activate: Activate, adapter: Ads.Google.Banner) {
        let constraints: [NSLayoutConstraint] = [
            .init(item: adapter.banner, attribute: .top, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .top, multiplier: 1.0, constant: 0),
            .init(item: adapter.banner, attribute: .left, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .left, multiplier: 1.0, constant: 0),
            .init(item: adapter.banner, attribute: .right, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .right, multiplier: 1.0, constant: 0),
            .init(item: adapter.banner, attribute: .bottom, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0)
        ]
        
        switch activate {
            case .activate:
                NSLayoutConstraint.activate(constraints)
            
            case .deactivate:
                NSLayoutConstraint.deactivate(constraints)
        }
    }
}

extension String: Swift.Error {}

private extension Ads.Google {
    final class Tracking {
        private var _tracking: ReplaySubject<Void>!
        
        func request(from controller: UIViewController) -> Completable {
            if let tracking = self._tracking {
                return tracking
                    .take(1)
                    .ignoreElements()
                    .asCompletable()
            }

            self._tracking = .create(bufferSize: 1)
            
            return Self._request(from: controller)
                .andThen(.deferred {
                    self._tracking.onNext(Void())
                    
                    return self.request(from: controller)
                })
        }
        
        private static func _request(from controller: UIViewController) -> Completable {
            guard #available(iOS 14, *) else {
                return .empty()
            }
            
            guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else {
                return .empty()
            }
            
            let ump = Completable.create { completable in
                UMPConsentInformation.sharedInstance.requestConsentInfoUpdate(with: UMPRequestParameters()) { error in
                    if let error = error {
                        return completable(.error(error))
                    }
    
                    switch UMPConsentInformation.sharedInstance.consentStatus {
                        case .required:
                            UMPConsentForm.load { form, error in
                                if let error = error {
                                    return completable(.error(error))
                                }
                                
                                form?.present(from: controller, completionHandler: { error in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        if let error = error {
                                            return completable(.error(error))
                                        }
                                        
                                        return completable(.completed)
                                    }
                                })
                            }

                        default:
                            return completable(.completed)
                    }
                }
                
                return Disposables.create()
            }
            
            return ump
                .catch { _ in
                    return Ads.tracking()
                }
        }
    }
}
