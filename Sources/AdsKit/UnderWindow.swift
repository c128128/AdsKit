import UIKit
import RxSwift
import RxCocoa

private class WindowController: UIViewController {
    /*
    deinit {
        print("\(type(of: self)) => deinit()")
    }
    */
    
    override var prefersStatusBarHidden: Bool {
        return false
    }
}

private final class BottomController: WindowController {
    /*
    deinit {
        print("\(type(of: self)) => deinit()")
    }
    */
    
    fileprivate lazy var _stack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false

        return stack
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self._stack)

        let safeArea = self.view.safeAreaLayoutGuide

        let heightConstraint = NSLayoutConstraint(item: self._stack, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 0)
        heightConstraint.priority = .defaultLow

        NSLayoutConstraint.activate([
            self._stack.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0),
            self._stack.leadingAnchor.constraint(equalTo: safeArea.leadingAnchor, constant: 0),
            self._stack.trailingAnchor.constraint(equalTo: safeArea.trailingAnchor, constant: 0),
            heightConstraint
        ])
    }
}

public class UnderWindow {
    /*
    deinit {
        print("\(type(of: self)) => deinit()")
    }
    */
    
    private let bag = DisposeBag()
    
    private let _main: UIWindow
    private lazy var _window: UIWindow = {
        let result = UIWindow(frame: .zero)
        result.clipsToBounds = true
        result.translatesAutoresizingMaskIntoConstraints = true
        result.windowLevel = .normal + 1
        result.screen = UIScreen.main
        result.rootViewController = self._root
        result.tag = 1_001
        
        if #available(iOS 13.0, *) {
            result.backgroundColor = .systemBackground
        } else {
            result.backgroundColor = .white
        }
        
        result.isHidden = false
        
        return result
    }()
    
    private lazy var _safeWindow: UIWindow = {
        let result = UIWindow(frame: UIScreen.main.bounds)
        result.clipsToBounds = true
        result.translatesAutoresizingMaskIntoConstraints = true
        result.windowLevel = .normal
        result.screen = UIScreen.main
        result.rootViewController = WindowController()
        
        return result
    }()
    
    private lazy var _root = BottomController()
    
    internal var root: UIViewController {
        return self._root
    }
    
    private var stackHeight: CGFloat = 0.0
    
    internal init(main: UIWindow) {
        self._main = main
        
        self.setUpOrientationChange()
    }
    
    private func setUpOrientationChange() {
        NotificationCenter.default.rx.notification(UIApplication.didChangeStatusBarOrientationNotification)
            .map { _ in UIApplication.shared.statusBarOrientation }
            .distinctUntilChanged()
            .observe(on: MainScheduler.asyncInstance)
            .subscribe(onNext: { [unowned self] _ in
                return self.render()
            })
            .disposed(by: self.bag)
    }
    
    internal func add(view: UIView) {
        self.stackHeight = view.frame.height
        
        self._root._stack.addArrangedSubview(view)
        
        return self.render()
    }
    
    internal func remove(view: UIView) {
        assert(view.frame.height >= self.stackHeight)
        
        view.removeFromSuperview()
        
        self.stackHeight -= view.frame.height
        
        return self.render()
    }
    
    private func render() {
        self.updateMainWindow(height: self.stackHeight)
        self.updateBottomWindow(height: self.stackHeight)
    }
    
    private func updateMainWindow(height: CGFloat) {
        let bounds = UIScreen.main.bounds
        let height = height.isZero ? 0 : height + self._safeWindow.safeAreaInsets.bottom
        
        self._main.frame = .init(
            x: bounds.origin.x,
            y: bounds.origin.y,
            width: bounds.width,
            height: bounds.height - height
        )
    }
    
    private func updateBottomWindow(height: CGFloat) {
        let bounds = UIScreen.main.bounds
        let height = height.isZero ? 0 : height + self._safeWindow.safeAreaInsets.bottom
        
        self._window.frame = .init(
            x: bounds.origin.x,
            y: bounds.size.height - height,
            width: bounds.width,
            height: height
        )
    }
}
