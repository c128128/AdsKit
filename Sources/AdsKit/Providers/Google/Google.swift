// swiftlint:disable nesting
import UIKit
import GoogleMobileAds
import RxRelay
import RxSwift

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
        
        private static let AUTOLOADED_KEY = "GADAutoload"
        private static let REWARD_KEY = "GADReward"
        private static let INTERSTITIAL_KEY = "GADInterstitial"
        private static let TEST_DEVICES_KEY = "GADTestDevices"
        
        internal static let shared = Google()
        
        private let bag = DisposeBag()
        
        private static let _report = PublishSubject<Report>()
        
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
        }
        #endif
        
        fileprivate func add(banner: AdsKit.Banner) {
            banner.adapter.report
                .take(until: banner.rx.deallocated)
                .map { .banner($0) }
                .subscribe(Self._report)
                .disposed(by: self.bag)
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
        
        public static func reward() -> Single<Ads.Reward.Result> {
            guard let reward = Self.shared.reward else {
                fatalError("Looks like you forget to set in Info.plist the \(Self.REWARD_KEY), with AdUnitID.")
            }

            return Ads.tracking()
                .andThen(.deferred {
                    return reward.show()
                })
        }
        
        public static func interstitial() -> Completable {
            guard let interstitial = Self.shared.interstitial else {
                fatalError("Looks like you forget to set in Info.plist the \(Self.INTERSTITIAL_KEY), with AdUnitID.")
            }

            return Ads.tracking()
                .andThen(.deferred {
                    return interstitial.show()
                })
        }
    }
}

public final class Banner: UIView {
    @IBInspectable var adUnitID: String = ""
    
    fileprivate var adapter: Ads.Google.Banner!
    
    public override func awakeFromNib() {
        super.awakeFromNib()
        
        self.setUp()
    }
    
    public func setAdUnitID(_ key: String) {
        self.adUnitID = key
        
        self.setUp()
    }
    
    private func setUp() {
        if self.adapter != nil {
            self.show(.no)
        }
        
        _ = Ads.tracking()
            .andThen(.deferred {
                #if DEBUG
                guard !self.adUnitID.isEmpty else {
                    fatalError("Looks like you forget to set adUnitID into Banner View or to call setAdUnitID()")
                }
                #endif
                
                self.adapter = .init(key: self.adUnitID, size: .anchored)
                
                self.adapter.banner.translatesAutoresizingMaskIntoConstraints = false
                
                _ = self.adapter.delegate.rx.methodInvoked(#selector(Ads.Google.BannerDelegate.bannerViewDidReceiveAd(_:)))
                    .take(until: self.rx.deallocated)
                    .subscribe(onNext: { [unowned self] _ in
                        self.show(.yes)
                    })
                
                _ = self.adapter.delegate.rx.methodInvoked(#selector(Ads.Google.BannerDelegate.bannerView(_:didFailToReceiveAdWithError:)))
                    .take(until: self.rx.deallocated)
                    .subscribe(onNext: { [unowned self] _ in
                        self.show(.no)
                    })
                
                Ads.Google.shared.add(banner: self)
                
                return .empty()
            })
            .subscribe()
    }
    
    private enum Show {
        case yes
        case no
    }
    
    private func show(_ show: Show) {
        switch show {
            case .yes:
                self.addSubview(self.adapter.banner)
            
                return self.constraints(.activate)
            
            case .no:
                self.adapter.banner.removeFromSuperview()
                
                return self.constraints(.deactivate)
        }
    }
    
    private enum Activate {
        case activate
        case deactivate
    }
    
    private func constraints(_ activate: Activate) {
        let constraints: [NSLayoutConstraint] = [
            .init(item: self.adapter.banner, attribute: .top, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .top, multiplier: 1.0, constant: 0),
            .init(item: self.adapter.banner, attribute: .left, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .left, multiplier: 1.0, constant: 0),
            .init(item: self.adapter.banner, attribute: .right, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .right, multiplier: 1.0, constant: 0),
            .init(item: self.adapter.banner, attribute: .bottom, relatedBy: .equal, toItem: self.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: 0)
        ]
        
        switch activate {
            case .activate:
                NSLayoutConstraint.activate(constraints)
            
            case .deactivate:
                NSLayoutConstraint.deactivate(constraints)
        }
    }
}
