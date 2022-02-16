import UIKit
import RxSwift
import RxCocoa

final class Window {
    /*
    deinit {
        print("*********** \(type(of: self)) => deinit()")
    }
    */
    
    private let window: UIWindow
    
    lazy var rootViewController: UIViewController = {
        let storyboard = UIStoryboard(name: "Window", bundle: Bundle.module)
        
        guard let initial = storyboard.instantiateInitialViewController() else {
            fatalError("Missing Controller in Storyboard.")
        }
        
        return initial
    }()
    
    private init(window: UIWindow) {
        self.window = window
    }
    
    func set(hidden: Bool) {
        if !hidden {
            self.window.isHidden = false
        }
        
        let controller = { [unowned self] () -> UIViewController? in
            guard hidden else {
                return self.rootViewController
            }
            
            return nil
        }()
        
        let completion = { [weak self] () -> Void in
            if hidden {
                self?.window.isHidden = true
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            CATransaction.begin()
            let transition = CATransition()
            transition.type = CATransitionType.fade
            transition.subtype = nil
            transition.duration = CATransaction.animationDuration()
            transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            
            CATransaction.setCompletionBlock(completion)
            
            self.window.layer.add(transition, forKey: kCATransition)
            self.window.rootViewController = controller
            
            CATransaction.commit()
        }
    }

    static func make() -> Window {
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .clear
        window.windowLevel = .normal + 2
        window.screen = UIScreen.main
        window.tag = 666
        
        /*
        let _window = type(of: window)
        _ = window.rx.deallocated
            .subscribe(onNext: {
                print("**************** \(_window) => deinit()")
            })
        */
        
        return .init(window: window)
    }
}

final class WindowRootController: UIViewController {
    override var prefersStatusBarHidden: Bool {
        return UIApplication.shared.isStatusBarHidden
    }
}
