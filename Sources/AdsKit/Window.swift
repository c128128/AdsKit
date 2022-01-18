import UIKit
import RxSwift
import RxCocoa

enum Window {
    static func make() -> UIWindow {
        let storyboard = UIStoryboard(name: "Window", bundle: Bundle.module)
        
        guard let initial = storyboard.instantiateInitialViewController() else {
            fatalError("Missing Controller in Storyboard.")
        }
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.backgroundColor = .clear
        window.windowLevel = .normal + 2
        window.screen = UIScreen.main
        window.rootViewController = initial
        window.tag = 666
        
        /*
        let _window = type(of: window)
        _ = window.rx.deallocated
            .subscribe(onNext: {
                print("\(_window) => deinit()")
            })
        
        let _initial = type(of: initial)
        _ = initial.rx.deallocated
            .subscribe(onNext: {
                print("\(_initial) => deinit()")
            })
        */
        
        return window
    }
}

final class WindowRootController: UIViewController {
    override var prefersStatusBarHidden: Bool {
        return false
    }
}
