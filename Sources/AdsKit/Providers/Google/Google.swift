// swiftlint:disable nesting
import UIKit
import GoogleMobileAds
import RxRelay
import RxSwift

public extension Ads {
    final class Google {
        public enum Report {
            public enum Action {
                case click
                case impression
            }
            
            case banner(Action)
            case interstitial(Action)
            case reward(Action)
        }
        
        private static let APPLICATION_IDENTIFIER = "GADApplicationIdentifier"
        private static let SK_AD_NETWORK_ITEMS = "SKAdNetworkItems"
        private static let NS_USER_TRACKING_USAGE_DESCRIPTION = "NSUserTrackingUsageDescription"
        
        private static let REWARD_KEY = "GADReward"
        private static let INTERSTITIAL_KEY = "GADInterstitial"
        private static let BANNER_KEY = "GADBanner"
        
        private static let AUTOLOADED_KEY = "GADAutoload"
        
        private static let shared = Google()
        
        private let bag = DisposeBag()
        
        private static let _report = PublishSubject<Report>()
        
        private var reward: Ads.Google.Reward?
        private var interstitial: Ads.Google.Interstitial?
        private var banner: Ads.Google.BannerUnderWindow?
        
        private init() {
            #if DEBUG
            Self.checkMinimumNecessarySettings()
            #endif
            
            GADMobileAds.sharedInstance().start(completionHandler: nil)
            GADMobileAds.sharedInstance().disableSDKCrashReporting()
            
            #if targetEnvironment(simulator)
            GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = [GADSimulatorID]
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
            
            if let key = Bundle.main.object(forInfoDictionaryKey: Self.BANNER_KEY) as? String {
                self.banner = Ads.Google.BannerUnderWindow(key: key)
                
                self.banner?.report
                    .map { .banner($0) }
                    .subscribe(Self._report)
                    .disposed(by: self.bag)
            }
        }
        
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
        
        internal static func isAutoloaded() -> Bool {
            return Bundle.main.object(forInfoDictionaryKey: Self.AUTOLOADED_KEY) as? Bool ?? true
        }
        
        internal static func load() {
            guard Self.shared.banner != nil else {
                return
            }
            
            return Self.banner(.show)
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
        
        public static func banner(_ option: Option) {
            guard let holder = Self.shared.banner else {
                fatalError("Looks like you forget to set in Info.plist the \(Self.BANNER_KEY), with AdUnitID.")
            }
            
            switch option {
                case .show:
                    guard !holder.isShown else {
                        return
                    }
                    
                    _ = Ads.tracking()
                        .andThen(.deferred {
                            holder.show()

                            return .empty()
                        })
                        .subscribe()
                
                case .remove:
                    guard holder.isShown else {
                        return
                    }
                
                    holder.remove()
            }
        }
    }
    
    enum Option {
        case show
        case remove
    }
}
