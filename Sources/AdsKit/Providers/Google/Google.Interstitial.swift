import UIKit
import GoogleMobileAds
import RxSwift

extension Ads.Google {
    final class Interstitial {
        private let _report = PublishSubject<Ads.Google.Report.Action>()
        internal var report: Observable<Ads.Google.Report.Action> {
            return self._report
        }
        
        private var _ad: ReplaySubject<GADInterstitialAd>!
        private let key: String
        
        private var isShown = false
        
        init(key: String) {
            self.key = key
            
            self.preload()
        }
        
        func show(from controller: UIViewController) -> Completable {
            #if DEBUG
            guard controller.viewIfLoaded?.window != nil else {
                fatalError("Looks like controller is hidden!")
            }
            #endif
            
            guard !self.isShown else {
                return .error("Interstitial is already shown.")
            }
            
            let delegate = InterstitialDelegate()
            let key = self.key
            
            self.isShown = true
            
            return self._ad
                .flatMapLatest { [weak controller, weak self] ad -> Completable in
                    ad.fullScreenContentDelegate = delegate
                    
                    return Completable.create { completable in
                        guard let controller = controller, let self = `self` else {
                            return Disposables.create()
                        }
                        
                        let didDismissScreen = delegate.rx.methodInvoked(#selector(InterstitialDelegate.adDidDismissFullScreenContent(_:)))
                            .take(1)
                            .subscribe(onNext: { _ in
                                return completable(.completed)
                            })

                        let didFail = delegate.rx.methodInvoked(#selector(InterstitialDelegate.ad(_:didFailToPresentFullScreenContentWithError:)))
                            .take(1)
                            .subscribe(onNext: { any in
                                guard let error = any[1] as? Swift.Error else {
                                    fatalError("Couldn't cast.")
                                }

                                return completable(.error(error))
                            })
                        
                        let adDidRecordClick = delegate.rx.methodInvoked(#selector(InterstitialDelegate.adDidRecordClick(_:)))
                            .map { _ in .click(key) }
                            .subscribe(self._report)
                        
                        let adDidRecordImpression = delegate.rx.methodInvoked(#selector(InterstitialDelegate.adDidRecordImpression(_:)))
                            .map { _ in .impression(key) }
                            .subscribe(self._report)
                        
                        ad.present(fromRootViewController: controller)
                        
                        return Disposables.create(
                            didDismissScreen,
                            didFail,
                            adDidRecordClick,
                            adDidRecordImpression
                        )
                    }
                }
                .ignoreElements()
                .asCompletable()
                .do(onDispose: { [weak self] in
                    self?.isShown = false
                    self?.preload()
                })
        }
        
        private func preload() {
            self._ad = .create(bufferSize: 1)
            
            GADInterstitialAd.load(withAdUnitID: self.key, request: .init()) { [weak self] ad, error in
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
