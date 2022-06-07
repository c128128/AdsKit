import UIKit
import GoogleMobileAds
import RxSwift

extension Ads.Google {
    final class Interstitial {
        private let _report = PublishSubject<Ads.Google.Report.Action>()
        internal var report: Observable<Ads.Google.Report.Action> {
            return self._report
        }
        
        private let _ad = ReplaySubject<Swift.Result<GADInterstitialAd?, Swift.Error>>.create(bufferSize: 1)
        private let key: String
        
        private var isShown = false
        
        init(key: String) {
            self.key = key
            
            self.preload()
        }
        
        // swiftlint:disable:next function_body_length
        func show() -> Completable {
            guard !self.isShown else {
                return .error("Interstitial is already shown.")
            }
            
            let window = Window.make()
            let delegate = InterstitialDelegate()
            let key = self.key
            
            self.isShown = true
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
                        .flatMap { (result: Swift.Result<GADInterstitialAd, Swift.Error>) -> Observable<Swift.Result<GADInterstitialAd, Swift.Error>> in
                            self._ad.onNext(.success(nil))
                            
                            return Observable.just(result)
                        }
                }
                .flatMapLatest { (result: Swift.Result<GADInterstitialAd, Swift.Error>) -> Observable<Never> in
                    switch result {
                        case .success(let ad):
                            ad.fullScreenContentDelegate = delegate
                        
                            return Completable.create { completable in
                                let willDismissScreen = delegate.rx.methodInvoked(#selector(InterstitialDelegate.adWillDismissFullScreenContent(_:)))
                                    .take(1)
                                    .subscribe(onNext: { _ in
                                        window.set(hidden: true)
                                    })
                                
                                let didDismissScreen = delegate.rx.methodInvoked(#selector(InterstitialDelegate.adDidDismissFullScreenContent(_:)))
                                    .take(1)
                                    .subscribe(onNext: { _ in
                                        // This is intentionally here, we keep a ref to ad, or it get deallocated
                                        _ = ad
                                        
                                        return completable(.completed)
                                    })

                                let didFail = delegate.rx.methodInvoked(#selector(InterstitialDelegate.ad(_:didFailToPresentFullScreenContentWithError:)))
                                    .take(1)
                                    .subscribe(onNext: { any in
                                        // This is intentionally here, we keep a ref to ad, or it get deallocated
                                        _ = ad
                                        
                                        guard let error = any[1] as? Swift.Error else {
                                            fatalError("Couldn't cast.")
                                        }
                                        
                                        window.set(hidden: true)

                                        return completable(.error(error))
                                    })
                                
                                let adDidRecordClick = delegate.rx.methodInvoked(#selector(InterstitialDelegate.adDidRecordClick(_:)))
                                    .map { _ in .click(key) }
                                    .subscribe(self._report)
                                
                                let adDidRecordImpression = delegate.rx.methodInvoked(#selector(InterstitialDelegate.adDidRecordImpression(_:)))
                                    .map { _ in .impression(key) }
                                    .subscribe(self._report)
                                
                                ad.present(fromRootViewController: window.rootViewController)
                                
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
                .ignoreElements()
                .asCompletable()
                .do(onDispose: {
                    self.isShown = false
                    self.preload()
                })
        }
        
        private func preload() {
            GADInterstitialAd.load(withAdUnitID: self.key, request: .init()) { ad, error in
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

    private final class InterstitialDelegate: NSObject, GADFullScreenContentDelegate {
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
