import UIKit
import GoogleMobileAds
import RxSwift

extension Ads.Google {
    final class Banner {
        enum Size {
            // More: https://developers.google.com/admob/ios/banner/inline-adaptive
            case inline(maxHeight: CGFloat)
            
            // More: https://developers.google.com/admob/ios/banner/anchored-adaptive
            case anchored
        }
        
        internal let bag = DisposeBag()
        internal let banner: GADBannerView
        // swiftlint:disable:next weak_delegate
        private let delegate: BannerDelegate
        
        private let _report = PublishSubject<Ads.Google.Report.Action>()
        internal var report: Observable<Ads.Google.Report.Action> {
            return self._report
        }
        
        private func load() {
            // swiftlint:disable:next force_unwrapping
            let width = self.banner.rootViewController!.view.frame.inset(by: self.banner.rootViewController!.view.safeAreaInsets).width

            switch self.size {
                case .inline(maxHeight: let maxHeight):
                    self.banner.adSize = GADInlineAdaptiveBannerAdSizeWithWidthAndMaxHeight(width, maxHeight)
                
                case .anchored:
                    self.banner.adSize = GADCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(width)
            }
            
            self.banner.load(GADRequest())
        }
        
        private let size: Size
        
        // swiftlint:disable:next force_unwrapping
        init(key: String, size: Size, root: UIViewController = UIApplication.shared.delegate!.window!!.rootViewController!) {
            self.size = size
            self.delegate = BannerDelegate()
            self.banner = GADBannerView()
            self.banner.adUnitID = key
            self.banner.delegate = self.delegate
            self.banner.adSizeDelegate = self.delegate
            self.banner.rootViewController = root
            self.banner.translatesAutoresizingMaskIntoConstraints = false
            self.banner.isAutoloadEnabled = false
            
            if #available(iOS 13.0, *) {
                self.banner.backgroundColor = .systemBackground
            } else {
                self.banner.backgroundColor = .white
            }
            
            root.rx.methodInvoked(#selector(UIViewController.viewWillTransition(to:with:)))
                .subscribe(onNext: { [unowned self] any in
                    guard let coordinator = any[1] as? UIViewControllerTransitionCoordinator else {
                        fatalError("Couldn't cast to UIViewControllerTransitionCoordinator")
                    }
                    
                    coordinator.animate(alongsideTransition: nil, completion: { _ in
                        self.load()
                    })
                })
                .disposed(by: self.bag)
            
            self.delegate.rx.methodInvoked(#selector(BannerDelegate.bannerViewDidRecordClick(_:)))
                .map { _ in .click(key) }
                .subscribe(self._report)
                .disposed(by: self.bag)
            
            self.delegate.rx.methodInvoked(#selector(BannerDelegate.bannerViewDidRecordImpression(_:)))
                .map { _ in .impression(key) }
                .subscribe(self._report)
                .disposed(by: self.bag)
            
            self.load()
        }
    }

    private final class BannerDelegate: NSObject, GADBannerViewDelegate, GADAdSizeDelegate {
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
}
