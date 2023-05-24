//
//  ContainNavigationController.swift
//  Test
//
//  Created by ZZJ on 2022/7/18.
//

import UIKit

extension UIViewController: STSpaceProtocol {}

public extension STSpace where Base: UIViewController {
    var navigationController: STNavigationController? {
        mutating set {
            objc_setAssociatedObject(base, &kjt_navigationController, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            return objc_getAssociatedObject(base, &kjt_navigationController) as? STNavigationController
        }
        
    }
    
    var containViewController: ContainViewController? {
        set {
            objc_setAssociatedObject(base, &kjt_containViewController, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            return objc_getAssociatedObject(base, &kjt_containViewController) as? ContainViewController
        }
        
    }
    
    // 修改状态栏
    func statusBarStyle(_ newValue: UIStatusBarStyle) {
        containViewController?.statusBarFlag = newValue
    }
    var statusBarStyle: UIStatusBarStyle {
        return containViewController?.statusBarFlag ?? .default
    }
    
    
}

public extension UIViewController {
    /// 是否允许侧滑返回
    /// - 默认true
    var popGestureEnabled: Bool {
        set {
            objc_setAssociatedObject(self, &kjt_popGestureEnabled, newValue, .OBJC_ASSOCIATION_ASSIGN)
            self.st.navigationController?.interactivePopGestureRecognizer?.isEnabled = newValue
        }
        get {
            let pop = objc_getAssociatedObject(self, &kjt_popGestureEnabled) as? Bool
            if pop == nil {
                return true
            }
            return pop!
        }
    }
}

/*
extension UIViewController {
    var jt_navigationController: STNavigationController? {
        set {
            objc_setAssociatedObject(self, &kjt_navigationController, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            return objc_getAssociatedObject(self, &kjt_navigationController) as? STNavigationController
        }
        
    }
    
    var jt_containViewController: ContainViewController? {
        set {
            objc_setAssociatedObject(self, &kjt_containViewController, newValue, .OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            return objc_getAssociatedObject(self, &kjt_containViewController) as? ContainViewController
        }
        
    }
    ///  设置状态栏样式
     var statusBarStyle: UIStatusBarStyle  {
         set {
             st.containViewController?.statusBarFlag = newValue
         }
         get {
             return st.containViewController?.statusBarFlag ?? .default
         }
         
     }
    
    
}
*/
private var kjt_navigationController: Int8 = 0
private var kjt_containViewController: Int8 = 0
private var kjt_popGestureEnabled: Int8 = 0

// MARK: ContainViewController
public class ContainViewController: UIViewController {

    static func containViewController(with viewController: UIViewController) -> ContainViewController {
        
        let containNavController = ContainNavigationController()
        containNavController.viewControllers = [viewController]
        
        let containViewController = ContainViewController()
        containViewController.navViewController = containNavController
        containViewController.addChild(containNavController)
        
        return containViewController
        
    }
    
    public var navViewController:ContainNavigationController!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        if #available(iOS 13.0, *) {
            UIScrollView.appearance().automaticallyAdjustsScrollIndicatorInsets = false
        } else {
            // Fallback on earlier versions
        }
        UIScrollView.appearance().contentInsetAdjustmentBehavior = .automatic
        
        view.addSubview(navViewController.view)
        
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isTranslucent = true
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _statusBarFlag = true
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _statusBarFlag = false
    }
    
    ///  设置状态栏样式
    var statusBarFlag: UIStatusBarStyle = .default {
        didSet {
            if statusBarFlag != oldValue {
                self.setNeedsStatusBarAppearanceUpdate()
            }
            
        }
    }
    private var _statusBarFlag: Bool = false
    
    // 修改状态栏样式
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        if _statusBarFlag == false {
            return rootViewController?.preferredStatusBarStyle ?? .default
        }
        return statusBarFlag
    }

    //MARK: getter
    public var rootViewController: UIViewController? {
        let containNavController = children.first as? ContainNavigationController
        return containNavController?.viewControllers.first
    }
    
    deinit {
//        debugPrint("\(Self.self):\(#function)")
    }
    
}

// MARK: ContainNavigationController
public class ContainNavigationController: UINavigationController {
    public override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if barStyle == .clear {
            // 适配iOS13以下系统, 在viewWillAppear设置无效
            barBackgroudView?.alpha = 0
        }
        
    }
    
    public override func popViewController(animated: Bool) -> UIViewController? {
        return navigationController?.popViewController(animated: animated)
    }
    
    public override func popToRootViewController(animated: Bool) -> [UIViewController]? {
        return navigationController?.popToRootViewController(animated: animated)
    }
    
    public override func popToViewController(_ viewController: UIViewController, animated: Bool) -> [UIViewController]? {
        let jtNav = viewController.st.navigationController
        let index = jtNav?.st.viewControllers.firstIndex(of: viewController) ?? 0
        guard let rawVC = jtNav?.viewControllers[index] else {
            return nil
        }
        return navigationController?.popToViewController(rawVC, animated: animated)
    }
    
    public override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        var _viewController = viewController
        _viewController.st.navigationController = navigationController as? STNavigationController
        
        let containVC = ContainViewController.containViewController(with: _viewController)
        _viewController.navigationController?.navigationBar.isTranslucent = false
        
        _viewController.st.containViewController = containVC
        
        navigationController?.pushViewController(containVC, animated: animated)
    }
    
    @objc func didTapBackButton() {
        navigationController?.popViewController(animated: true)
    }
    
    public override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        navigationController?.dismiss(animated: flag, completion: completion)
        var fist = viewControllers.first
        fist?.st.navigationController = nil
    }
    
    deinit {
//        debugPrint("\(Self.self):\(#function)")
    }
    
}
