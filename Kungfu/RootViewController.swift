/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This is a custom container view controller that is responsible for two things:
    1. Hosting the CameraViewController that presents video frames captured by camera or being read from video file
    2. Presentation and dismissal of overlay view controllers based on current game state
*/

import UIKit
import AVFoundation

let cameraEvent = "camera"
let poseGameEvent = "poseGame"

class GameManager {
    
    fileprivate var activeObservers = [UIViewController: NSObjectProtocol]()
    var recordedVideoSource: AVAsset?
    static var shared = GameManager()
    
    func reset() {
        // Reset all stored values
        recordedVideoSource = nil
        // Remove all observers and enter inactive state.
        let notificationCenter = NotificationCenter.default
        for observer in activeObservers {
            notificationCenter.removeObserver(observer)
        }
        activeObservers.removeAll()
    }
    func didEnter(newIdentify: String, previousIdentify: String?) {
        let note = GameStateChangeNotification(newIdentify: newIdentify, previousIdentify: previousIdentify);
        note.post()
    }
}

protocol GameStateChangeObserver: AnyObject {
    func gameManagerDidEnter(identify: String, previousIdentify: String?)
}

extension GameStateChangeObserver where Self: UIViewController {
    func startObservingStateChanges() {
        let token = NotificationCenter.default.addObserver(forName: GameStateChangeNotification.name,
                                                           object: GameStateChangeNotification.object,
                                                           queue: nil) { [weak self] (notification) in
            guard let note = GameStateChangeNotification(notification: notification) else {
                return
            }
            self?.gameManagerDidEnter(identify: note.newIdentify, previousIdentify: note.previousIdentify)
        }
        let gameManager = GameManager.shared
        gameManager.activeObservers[self] = token
    }
    
    func stopObservingStateChanges() {
        let gameManager = GameManager.shared
        guard let token = gameManager.activeObservers[self] else {
            return
        }
        NotificationCenter.default.removeObserver(token)
        gameManager.activeObservers.removeValue(forKey: self)
    }
}

struct GameStateChangeNotification {
    static let name = NSNotification.Name("GameStateChangeNotification")
    static let object = "obj"
    
    let newIdentifyKey = "newIdentify"
    let previousIdentifyKey = "previousIdentify"

    let newIdentify: String
    let previousIdentify: String?
    
    init(newIdentify: String, previousIdentify: String?) {
        self.newIdentify = newIdentify
        self.previousIdentify = previousIdentify
    }
    
    init?(notification: Notification) {
        guard notification.name == Self.name, let newIdentify = notification.userInfo?[newIdentifyKey] as? String else {
            return nil
        }
        self.newIdentify = newIdentify
        self.previousIdentify = notification.userInfo?[previousIdentifyKey] as? String
    }
    
    func post() {
        var userInfo = [newIdentifyKey: newIdentify]
        if let previousIdentify = previousIdentify {
            userInfo[previousIdentifyKey] = previousIdentify
        }
        NotificationCenter.default.post(name: Self.name, object: Self.object, userInfo: userInfo)
    }
}

typealias GameStateChangeObserverViewController = UIViewController & GameStateChangeObserver

class RootViewController: UIViewController {
    
//    @IBOutlet weak var closeButton: UIButton!
    
    private var cameraViewController: CameraViewController!
    private var overlayParentView: UIView!
    private var overlayViewController: UIViewController!
//    private let gameManager = GameManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraViewController = CameraViewController()
        cameraViewController.view.frame = view.bounds
        addChild(cameraViewController)
        cameraViewController.beginAppearanceTransition(true, animated: true)
        view.addSubview(cameraViewController.view)
        cameraViewController.endAppearanceTransition()
        cameraViewController.didMove(toParent: self)
        overlayParentView = UIView(frame: view.bounds)
        overlayParentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(overlayParentView)
        NSLayoutConstraint.activate([
            overlayParentView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 0),
            overlayParentView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: 0),
            overlayParentView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            overlayParentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0)
        ])
        
        startObservingStateChanges()
        // Make sure close button stays in front of other views.
//        view.bringSubviewToFront(closeButton)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        GameManager.shared.didEnter(newIdentify: cameraEvent, previousIdentify: nil)
    }
    
    private func presentOverlayViewController(_ newOverlayViewController: UIViewController?, completion: (() -> Void)?) {
        defer {
            completion?()
        }
        
        guard overlayViewController != newOverlayViewController else {
            return
        }
        
        if let currentOverlay = overlayViewController {
            currentOverlay.willMove(toParent: nil)
            currentOverlay.beginAppearanceTransition(false, animated: true)
            currentOverlay.view.removeFromSuperview()
            currentOverlay.endAppearanceTransition()
            currentOverlay.removeFromParent()
        }
        
        if let newOverlay = newOverlayViewController {
            newOverlay.view.frame = overlayParentView.bounds
            addChild(newOverlay)
            newOverlay.beginAppearanceTransition(true, animated: true)
            overlayParentView.addSubview(newOverlay.view)
            newOverlay.endAppearanceTransition()
            newOverlay.didMove(toParent: self)
        }
        
        overlayViewController = newOverlayViewController
    }
}

// MARK: - Handle states that require view controller transitions

// This is where the overlay controllers management happens.
extension RootViewController: GameStateChangeObserver {
    func gameManagerDidEnter(identify: String, previousIdentify: String?) {
        // Create an overlay view controller based on the game state
        let controllerToPresent: UIViewController
        
        if (identify == poseGameEvent) {
            controllerToPresent = PoseViewController.init();
        } else {
            return
        }
        
        // Remove existing overlay controller (if any) from game manager listeners
        if let currentListener = overlayViewController as? GameStateChangeObserverViewController {
            currentListener.stopObservingStateChanges()
        }
        
        presentOverlayViewController(controllerToPresent) {
            //Adjust safe area insets on overlay controller to match actual video outpput area.
            if let cameraVC = self.cameraViewController {
                let viewRect = cameraVC.view.frame
                let videoRect = cameraVC.viewRectForVisionRect(CGRect(x: 0, y: 0, width: 1, height: 1))
                let insets = controllerToPresent.view.safeAreaInsets
                let additionalInsets = UIEdgeInsets(
                        top: videoRect.minY - viewRect.minY - insets.top,
                        left: videoRect.minX - viewRect.minX - insets.left,
                        bottom: viewRect.maxY - videoRect.maxY - insets.bottom,
                        right: viewRect.maxX - videoRect.maxX - insets.right)
                controllerToPresent.additionalSafeAreaInsets = additionalInsets
            }

            // If new overlay controller conforms to GameManagerListener, add it to the listeners.
            if let gameManagerListener = controllerToPresent as? GameStateChangeObserverViewController {
                gameManagerListener.startObservingStateChanges()
            }
            
            // If new overlay controller conforms to CameraViewControllerOutputDelegate
            // set it as a CameraViewController's delegate, so it can process the frames
            // that are coming from the live camera preview or being read from pre-recorded video file.
            if let outputDelegate = controllerToPresent as? CameraViewControllerOutputDelegate {
                self.cameraViewController.outputDelegate = outputDelegate
            }
        }
    }
}
