import Foundation
import UIKit
import RxSwift
import RxCocoa
import AppTrackingTransparency
import AdSupport

@_cdecl("ads_kit_autoload")
public func autoload() {
    Ads.autoload()
}

public final class Ads {
    internal static func autoload() {
        // Wait the app to have an AppDelegate
        _ = NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .take(1)
            .subscribe(onNext: { _ in
                if Ads.Google.isAutoloaded() {
                    Ads.Google.load()
                }
            })
    }
    
    private static func requestTrackingAuthorization() -> Single<Authorization> {
        guard #available(iOS 14, *) else {
            return .just(.authorized)
        }
        
        return Single<Void>.just(Void())
            // Workaround for ATTrackingManager.requestTrackingAuthorization
            // Alert don't appear if request was called right after app launch.
            // More here: https://developer.apple.com/forums/thread/690607
            .delay(.seconds(1), scheduler: MainScheduler.instance)
            .flatMap {
                return .create { single in
                    ATTrackingManager.requestTrackingAuthorization { status in
                        switch status {
                            case .authorized:
                                return single(.success(.authorized))
                            
                            default:
                                return single(.success(.denied))
                        }
                    }
                    
                    return Disposables.create()
                }
            }
            .observe(on: MainScheduler.instance)
    }
    
    /// This method is used to make sure that
    /// TrackingAuthorization was called before requesting ads
    internal static func tracking() -> Completable {
        guard #available(iOS 14, *) else {
            return .empty()
        }
        
        switch ATTrackingManager.trackingAuthorizationStatus {
            case .notDetermined, .restricted:
                return Self.requestTrackingAuthorization()
                    .asCompletable()

            case .denied, .authorized:
                return .empty()

            @unknown default:
                fatalError("Invalid Status")
        }
    }
}

extension Ads {
    public enum Reward {
        public enum Result {
            case rewarded(type: String, amount: Double)
            case canceled
        }
    }
    
    public enum Authorization {
        case authorized
        case denied
    }
}
