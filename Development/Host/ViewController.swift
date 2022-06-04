import UIKit
import AdsKit

final class ViewController: UIViewController {
    @IBOutlet private weak var _banner: Banner!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        _ = Ads.Google.report
            .debug("Ads.Google.report")
            .subscribe()
    }
    
    @IBAction func _bannerSetAdUnitID(_ sender: Any) {
        self._banner.setAdUnitID("ca-app-pub-3940256099942544/2934735716")
    }
    
    @IBAction func _bannerRemove(_ sender: Any) {
        self._banner.setAdUnitID(nil)
    }
    
    @IBAction func _rewardGad(_ sender: Any) {
        print(#function)
        
        _ = Ads.Google.reward()
            .debug("Ads.Google.reward()")
            .subscribe()
    }
    
    @IBAction func _interstitialGad(_ sender: Any) {
        print(#function)
        
        _ = Ads.Google.interstitial()
            .debug("Ads.Google.interstitial()")
            .subscribe()
    }
}
