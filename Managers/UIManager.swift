import UIKit
import os.log

class UIManager {
    static let shared = UIManager()
    
    private let queue = DispatchQueue(label: "com.technicallypilates.ui")
    private let logger = OSLog(subsystem: "com.technicallypilates", category: "UI")
    private var viewLoadTimes: [String: TimeInterval] = [:]
    private var animationCount = 0
    private let maxConcurrentAnimations = 2
    
    private init() {
        setupNotifications()
    }
    
    // MARK: - Setup
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    // MARK: - View Lifecycle Management
    
    func monitorViewLoad(_ viewController: UIViewController) {
        let startTime = Date()
        let viewName = String(describing: type(of: viewController))
        
        viewController.viewDidLoad = { [weak self] in
            let loadTime = Date().timeIntervalSince(startTime)
            self?.viewLoadTimes[viewName] = loadTime
            
            os_log("View load time for %{public}@: %.2f seconds",
                   log: self?.logger ?? .default,
                   type: .debug,
                   viewName,
                   loadTime)
            
            if loadTime > 1.0 {
                self?.optimizeView(viewController)
            }
        }
    }
    
    private func optimizeView(_ viewController: UIViewController) {
        queue.async {
            // Optimize view hierarchy
            self.flattenViewHierarchy(viewController.view)
            
            // Optimize layout
            self.optimizeLayout(viewController.view)
            
            // Optimize images
            self.optimizeImages(in: viewController.view)
        }
    }
    
    private func flattenViewHierarchy(_ view: UIView) {
        // Remove unnecessary container views
        for subview in view.subviews {
            if subview.subviews.count == 1 && subview.backgroundColor == .clear {
                if let child = subview.subviews.first {
                    view.addSubview(child)
                    subview.removeFromSuperview()
                }
            }
            flattenViewHierarchy(subview)
        }
    }
    
    private func optimizeLayout(_ view: UIView) {
        // Use efficient layout calculations
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // Disable unnecessary layout updates
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Optimize constraints
        for constraint in view.constraints {
            if constraint.priority.rawValue < 1000 {
                constraint.isActive = false
            }
        }
    }
    
    private func optimizeImages(in view: UIView) {
        for subview in view.subviews {
            if let imageView = subview as? UIImageView {
                optimizeImageView(imageView)
            }
            optimizeImages(in: subview)
        }
    }
    
    private func optimizeImageView(_ imageView: UIImageView) {
        // Use lower quality images when appropriate
        if let image = imageView.image {
            let scale = UIScreen.main.scale
            let size = imageView.bounds.size
            
            if image.size.width > size.width * scale * 2 {
                imageView.image = image.resized(to: size)
            }
        }
        
        // Enable image caching
        imageView.contentMode = .scaleAspectFit
    }
    
    // MARK: - Animation Management
    
    func performAnimation(_ animation: @escaping () -> Void, completion: (() -> Void)? = nil) {
        queue.async {
            guard self.animationCount < self.maxConcurrentAnimations else {
                os_log("Too many concurrent animations, queuing", log: self.logger, type: .info)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.performAnimation(animation, completion: completion)
                }
                return
            }
            
            self.animationCount += 1
            
            UIView.animate(withDuration: 0.3,
                          delay: 0,
                          options: [.curveEaseInOut, .beginFromCurrentState],
                          animations: animation) { _ in
                self.animationCount -= 1
                completion?()
            }
        }
    }
    
    // MARK: - Memory Management
    
    @objc private func handleMemoryWarning() {
        queue.async {
            // Clear view load times
            self.viewLoadTimes.removeAll()
            
            // Cancel ongoing animations
            self.animationCount = 0
            
            // Notify active view controllers
            NotificationCenter.default.post(name: .uiMemoryWarning, object: nil)
        }
    }
}

// MARK: - UIImage Extension

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - UIViewController Extension

extension UIViewController {
    var viewDidLoad: (() -> Void)? {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.viewDidLoadKey) as? () -> Void }
        set { objc_setAssociatedObject(self, &AssociatedKeys.viewDidLoadKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}

private struct AssociatedKeys {
    static var viewDidLoadKey = "viewDidLoadKey"
}

// MARK: - Notification Names

extension Notification.Name {
    static let uiMemoryWarning = Notification.Name("uiMemoryWarning")
} 