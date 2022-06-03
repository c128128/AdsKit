import Foundation
import UIKit
import RxSwift
import RxCocoa
import AppTrackingTransparency
import AdSupport

public final class Ads {
    private static func requestTrackingAuthorization() -> Single<Authorization> {
        guard #available(iOS 14, *) else {
            return .just(.authorized)
        }
        
        return Single<Void>.just(Void())
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
