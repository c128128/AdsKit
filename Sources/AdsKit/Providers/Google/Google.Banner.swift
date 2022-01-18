import UIKit
import GoogleMobileAds
import RxSwift

extension Ads.Google {
    final class Banner {
        /*
        deinit {
            print("\(type(of: self)) => deinit()")
        }
        */
        
        internal let bag = DisposeBag()
        fileprivate let banner: GADBannerView
        // swiftlint:disable:next weak_delegate
        private let delegate: BannerDelegate
        
        private let _report = PublishSubject<Ads.Google.Report.Action>()
        internal var report: Observable<Ads.Google.Report.Action> {
            return self._report
        }
        
        private let _status = PublishSubject<Result<Void, Swift.Error>>()
        var status: Observable<Result<Void, Swift.Error>> {
            return self._status
        }

        // swiftlint:disable:next function_body_length
        init(key: String, root: UIViewController) {
            self.delegate = BannerDelegate()
            self.banner = GADBannerView()
            self.banner.adUnitID = key
            self.banner.delegate = self.delegate
            self.banner.adSizeDelegate = self.delegate
            self.banner.rootViewController = root
            self.banner.translatesAutoresizingMaskIntoConstraints = false
            self.banner.isAutoloadEnabled = true
            
            if #available(iOS 13.0, *) {
                self.banner.backgroundColor = .systemBackground
            } else {
                self.banner.backgroundColor = .white
            }
            
            root.rx.methodInvoked(#selector(UIViewController.viewWillTransition(to:with:)))
                .flatMap { [unowned root] any -> Observable<CGFloat> in
                    guard let coordinator = any[1] as? UIViewControllerTransitionCoordinator else {
                        fatalError("Couldn't cast to UIViewControllerTransitionCoordinator")
                    }
                    
                    return .create { observable -> Disposable in
                        coordinator.animate(alongsideTransition: nil, completion: { _ in
                            observable.onNext(root.view.frame.width)
                        })
                        
                        return Disposables.create()
                    }
                }
                .startWith(root.view.frame.width)
                .subscribe(onNext: { [unowned self] width in
                    self.banner.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
                })
                .disposed(by: self.bag)
            
            self.delegate.rx.methodInvoked(#selector(BannerDelegate.bannerViewDidReceiveAd(_:)))
                .subscribe(onNext: { [unowned self] _ in
                    self._status.onNext(.success(Void()))
                })
                .disposed(by: self.bag)
            
            self.delegate.rx.methodInvoked(#selector(BannerDelegate.bannerView(_:didFailToReceiveAdWithError:)))
                .subscribe(onNext: { [unowned self] any in
                    guard let error = any[1] as? Error else {
                        fatalError("Couldn't cast to Error")
                    }
                    
                    self._status.onNext(.failure(error))
                })
                .disposed(by: self.bag)
            
            self.delegate.rx.methodInvoked(#selector(BannerDelegate.bannerViewDidRecordClick(_:)))
                .map { _ in .click }
                .subscribe(self._report)
                .disposed(by: self.bag)
            
            self.delegate.rx.methodInvoked(#selector(BannerDelegate.bannerViewDidRecordImpression(_:)))
                .map { _ in .impression }
                .subscribe(self._report)
                .disposed(by: self.bag)
        }
    }

    private final class BannerDelegate: NSObject, GADBannerViewDelegate, GADAdSizeDelegate {
        /*
        deinit {
            print("\(type(of: self)) => deinit()")
        }
        */
        
        func adView(_ bannerView: GADBannerView, willChangeAdSizeTo size: GADAdSize) {
            print(#function)
        }
        
        func bannerViewDidReceiveAd(_ bannerView: GADBannerView) {
            print(#function)
        }
        
        func bannerView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: Error) {
            print(#function)
        }
        
        func bannerViewDidRecordClick(_ bannerView: GADBannerView) {
            print(#function)
        }
        
        func bannerViewDidRecordImpression(_ bannerView: GADBannerView) {
            print(#function)
        }
        
        func bannerViewWillPresentScreen(_ bannerView: GADBannerView) {
            print(#function)
        }
        
        func bannerViewWillDismissScreen(_ bannerView: GADBannerView) {
            print(#function)
        }
        
        func bannerViewDidDismissScreen(_ bannerView: GADBannerView) {
            print(#function)
        }
    }

    internal final class BannerUnderWindow {
        /*
        deinit {
            print("\(type(of: self)) => deinit()")
        }
        */
        
        private let bag = DisposeBag()
        
        private var window: UnderWindow!
        private var banner: Banner!
        private let key: String
        
        private let _report = PublishSubject<Ads.Google.Report.Action>()
        internal var report: Observable<Ads.Google.Report.Action> {
            return self._report
        }
        
        internal var isShown: Bool {
            return self.banner != nil
        }
        
        init(key: String) {
            self.key = key
        }
        
        func show() {
            // swiftlint:disable:next force_unwrapping
            self.window = UnderWindow(main: UIApplication.shared.delegate!.window!!)
            self.banner = Banner(key: key, root: self.window.root)

            self.banner.status
                .subscribe(with: self, onNext: { _self, status in
                    switch status {
                        case .success:
                            _self.window.add(view: _self.banner.banner)
        
                        case .failure:
                            _self.remove()
                    }
                })
                .disposed(by: self.banner.bag)
            
            self.banner.report
                .subscribe(self._report)
                .disposed(by: self.banner.bag)
        }
        
        func remove() {
            self.window.remove(view: self.banner.banner)
            
            self.banner = nil
            self.window = nil
        }
    }
}
