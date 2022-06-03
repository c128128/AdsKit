import UIKit
import AdsKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        _ = Ads.Google.report
            .debug("Ads.Google.report")
            .subscribe()
    }
    
    @IBAction func _bannerGadRemove(_ sender: Any) {
        print(#function)
        
//        Ads.Google.banner(.remove)
    }
    
    @IBAction func _bannerGadShow(_ sender: Any) {
        print(#function)
        
//        self.banner?.status
//            .subscribe(onNext: { result in
//                switch result {
//                    case .success(let banner):
//                        print("BANNER ==> \(banner)")
//
//                    case .failure(let error):
//                        print("BANNER ERROR ==> \(error)")
//                }
//            })
//            .disposed(by: self.bag)
    }
    
    @IBAction func _rewardGad(_ sender: Any) {
        print(#function)
        
//        _ = Ads.Google.reward()
//            .debug("Ads.Google.reward()")
//            .subscribe()
    }
    
    @IBAction func _interstitialGad(_ sender: Any) {
        print(#function)
        
//        _ = Ads.Google.interstitial()
//            .debug("Ads.Google.interstitial()")
//            .subscribe()
    }
}
