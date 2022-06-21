import UIKit
import GoogleMobileAds
import RxSwift
 
extension Ads.Google {
    final class Reward {
        private let _report = PublishSubject<Ads.Google.Report.Action>()
        internal var report: Observable<Ads.Google.Report.Action> {
            return self._report
        }

        private var _ad: ReplaySubject<GADRewardedAd>!
        private let key: String
        
        private var isShown = false
        
        init(key: String) {
            self.key = key
            
            self.preload()
        }
        
        // swiftlint:disable:next function_body_length
        func show(from controller: UIViewController) -> Single<Ads.Reward.Result> {
            #if DEBUG
            guard controller.viewIfLoaded?.window != nil else {
                fatalError("Looks like controller is hidden!")
            }
            #endif

            guard !self.isShown else {
                return .error("Interstitial is already shown.")
            }

            let delegate = RewardDelegate()
            let key = self.key

            self.isShown = true
            
            return self._ad
                .flatMapLatest { [weak controller, weak self] ad -> Single<Ads.Reward.Result> in
                    ad.fullScreenContentDelegate = delegate
                
                    return Single<Ads.Reward.Result>.create { single in
                        guard let controller = controller, let self = `self` else {
                            return Disposables.create()
                        }
                        
                        var rewarded: _Reward?
                        
                        let didDismissScreen = delegate.rx.methodInvoked(#selector(RewardDelegate.adDidDismissFullScreenContent(_:)))
                            .take(1)
                            .subscribe(onNext: { _ in
                                if let rewarded = rewarded {
                                    return single(.success(.rewarded(type: rewarded.type, amount: rewarded.amount)))
                                }
                                
                                return single(.success(.canceled))
                            })
                        
                        let didFail = delegate.rx.methodInvoked(#selector(RewardDelegate.ad(_:didFailToPresentFullScreenContentWithError:)))
                            .take(1)
                            .subscribe(onNext: { any in
                                guard let error = any[1] as? Swift.Error else {
                                    fatalError("Couldn't cast.")
                                }
                                
                                return single(.failure(error))
                            })
                        
                        let adDidRecordClick = delegate.rx.methodInvoked(#selector(RewardDelegate.adDidRecordClick(_:)))
                            .map { _ in .click(key) }
                            .subscribe(self._report)
                        
                        let adDidRecordImpression = delegate.rx.methodInvoked(#selector(RewardDelegate.adDidRecordImpression(_:)))
                            .map { _ in .impression(key) }
                            .subscribe(self._report)
                        
                        ad.present(fromRootViewController: controller) {
                            rewarded = .init(type: ad.adReward.type, amount: ad.adReward.amount.doubleValue)
                        }
                        
                        return Disposables.create(
                            didDismissScreen,
                            didFail,
                            adDidRecordClick,
                            adDidRecordImpression
                        )
                    }
                }
                .asSingle()
                .do(onDispose: { [weak self] in
                    self?.isShown = false
                    self?.preload()
                })
        }
        
        private func preload() {
            self._ad = .create(bufferSize: 1)
            
            GADRewardedAd.load(withAdUnitID: self.key, request: .init()) { [weak self] ad, error in
                if let error = error {
                    self?._ad.onError(error)
                    
                    return
                }
                
                guard let ad = ad else {
                    fatalError("Invalid state!")
                }
                
                self?._ad.onNext(ad)
                self?._ad.onCompleted()
            }
        }
    }

    private struct _Reward {
        let type: String
        let amount: Double
    }

    private final class RewardDelegate: NSObject, GADFullScreenContentDelegate {
        func ad(_ ad: GADFullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
            print(#function)
        }
        
        func adWillDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
            print(#function)
        }
        
        func adDidRecordClick(_ ad: GADFullScreenPresentingAd) {
            print(#function)
        }
        
        func adDidRecordImpression(_ ad: GADFullScreenPresentingAd) {
            print(#function)
        }
        
        func adWillPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
            print(#function)
        }
        
        func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
            print(#function)
        }
    }
}
