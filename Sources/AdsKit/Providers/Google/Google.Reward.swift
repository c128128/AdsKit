import UIKit
import GoogleMobileAds
import RxSwift
 
extension Ads.Google {
    final class Reward {
        private let _report = PublishSubject<Ads.Google.Report.Action>()
        internal var report: Observable<Ads.Google.Report.Action> {
            return self._report
        }

        private let _ad = ReplaySubject<Swift.Result<GADRewardedAd?, Swift.Error>>.create(bufferSize: 1)
        private let key: String
        
        init(key: String) {
            self.key = key
            
            self.preload()
        }
        
        // swiftlint:disable:next function_body_length
        func show() -> Single<Ads.Reward.Result> {
            let window = Window.make()
            let delegate = RewardDelegate()
            
            window.set(hidden: false)
            
            return window.rootViewController.rx.methodInvoked(#selector(UIViewController.viewDidAppear(_:)))
                .take(1)
                .flatMapLatest { _ in
                    return self._ad
                        .compactMap {
                            switch $0 {
                                case .failure(let error):
                                    return .failure(error)
                                
                                case .success(let ad):
                                    guard let ad = ad else {
                                        return nil
                                    }
                                
                                    return .success(ad)
                            }
                        }
                        .take(1)
                        .observe(on: MainScheduler.asyncInstance)
                        .flatMap { (result: Swift.Result<GADRewardedAd, Swift.Error>) -> Observable<Swift.Result<GADRewardedAd, Swift.Error>> in
                            self._ad.onNext(.success(nil))
                            
                            return Observable.just(result)
                        }
                }
                .flatMapLatest { (result: Swift.Result<GADRewardedAd, Swift.Error>) -> Observable<Ads.Reward.Result> in
                    switch result {
                        case .success(let ad):
                            ad.fullScreenContentDelegate = delegate
                        
                            return Single<Ads.Reward.Result>.create { single in
                                var rewarded: _Reward?
                                
                                let willDismissScreen = delegate.rx.methodInvoked(#selector(RewardDelegate.adWillDismissFullScreenContent(_:)))
                                    .take(1)
                                    .subscribe(onNext: { _ in
                                        window.set(hidden: true)
                                    })
                                
                                let didDismissScreen = delegate.rx.methodInvoked(#selector(RewardDelegate.adDidDismissFullScreenContent(_:)))
                                    .take(1)
                                    .subscribe(onNext: { _ in
                                        // This is intentionally here, we keep a ref to ad, or it get deallocated
                                        _ = ad
                                        
                                        if let rewarded = rewarded {
                                            return single(.success(.rewarded(type: rewarded.type, amount: rewarded.amount)))
                                        }

                                        return single(.success(.canceled))
                                    })

                                let didFail = delegate.rx.methodInvoked(#selector(RewardDelegate.ad(_:didFailToPresentFullScreenContentWithError:)))
                                    .take(1)
                                    .subscribe(onNext: { any in
                                        // This is intentionally here, we keep a ref to ad, or it get deallocated
                                        _ = ad
                                        
                                        guard let error = any[1] as? Swift.Error else {
                                            fatalError("Couldn't cast.")
                                        }
                                        
                                        window.set(hidden: true)

                                        return single(.failure(error))
                                    })
                                
                                let adDidRecordClick = delegate.rx.methodInvoked(#selector(RewardDelegate.adDidRecordClick(_:)))
                                    .map { _ in .click }
                                    .subscribe(self._report)
                                
                                let adDidRecordImpression = delegate.rx.methodInvoked(#selector(RewardDelegate.adDidRecordImpression(_:)))
                                    .map { _ in .impression }
                                    .subscribe(self._report)
                                
                                ad.present(fromRootViewController: window.rootViewController) {
                                    rewarded = .init(type: ad.adReward.type, amount: ad.adReward.amount.doubleValue)
                                }
                                
                                return Disposables.create(
                                    willDismissScreen,
                                    didDismissScreen,
                                    didFail,
                                    adDidRecordClick,
                                    adDidRecordImpression
                                )
                            }
                            .asObservable()
                        
                        case .failure(let error):
                            return .error(error)
                    }
                }
                .asSingle()
                .do(onDispose: {
                    self.preload()
                })
        }
        
        private func preload() {
            GADRewardedAd.load(withAdUnitID: self.key, request: .init()) { ad, error in
                if let error = error {
                    return self._ad.onNext(.failure(error))
                }
                
                guard let ad = ad else {
                    fatalError("Invalid state!")
                }
                
                return self._ad.onNext(.success(ad))
            }
        }
    }

    private struct _Reward {
        let type: String
        let amount: Double
    }

    private final class RewardDelegate: NSObject, GADFullScreenContentDelegate {
        /*
        deinit {
            print("*********** \(type(of: self)) => deinit()")
        }
        */
        
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
        
        func adDidPresentFullScreenContent(_ ad: GADFullScreenPresentingAd) {
            print(#function)
        }
        
        func adDidDismissFullScreenContent(_ ad: GADFullScreenPresentingAd) {
            print(#function)
        }
    }
}
