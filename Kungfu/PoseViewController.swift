//
//  PoseViewController.swift
//  Kungfu
//
//  Created by zhiqiang zhu on 2023/5/9.
//

import UIKit
import AVFoundation
import Vision

class PoseViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let detectPlayerRequest = VNDetectHumanBodyPoseRequest()

    private let jointSegmentView = JointSegmentView()
    private let bodyPoseDetectionMinConfidence: VNConfidence = 0.6
    private let bodyPoseRecognizedPointMinConfidence: VNConfidence = 0.1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(jointSegmentView)
    }
}


extension PoseViewController: CameraViewControllerOutputDelegate {
    
    func humanBoundingBox(for observation: VNHumanBodyPoseObservation) -> CGRect {
        var box = CGRect.zero
        var normalizedBoundingBox = CGRect.null
        // Process body points only if the confidence is high.
        guard observation.confidence > bodyPoseDetectionMinConfidence, let points = try? observation.recognizedPoints(forGroupKey: .all) else {
            return box
        }
        // Only use point if human pose joint was detected reliably.
        for (_, point) in points where point.confidence > bodyPoseRecognizedPointMinConfidence {
            normalizedBoundingBox = normalizedBoundingBox.union(CGRect(origin: point.location, size: .zero))
        }
        if !normalizedBoundingBox.isNull {
            box = normalizedBoundingBox
        }
        // Fetch body joints from the observation and overlay them on the player.
        let joints = getBodyJointsFor(observation: observation)
        DispatchQueue.main.async {
            self.jointSegmentView.joints = joints
        }
        // Store the body pose observation in playerStats when the game is in TrackThrowsState.
        // We will use these observations for action classification once the throw is complete.
    //    if gameManager.stateMachine.currentState is GameManager.TrackThrowsState {
    //        playerStats.storeObservation(observation)
    //        if trajectoryView.inFlight {
    //            trajectoryInFlightPoseObservations += 1
    //        }
    //    }
        return box
    }
    
    func cameraViewController(_ controller: CameraViewController, didReceiveBuffer buffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) {
        let visionHandler = VNImageRequestHandler(cmSampleBuffer: buffer, orientation: orientation, options: [:])
        DispatchQueue.main.async {
            // Get the frame of rendered view
            let normalizedFrame = CGRect(x: 0, y: 0, width: 1, height: 1)
            self.jointSegmentView.frame = controller.viewRectForVisionRect(normalizedFrame)
//            self.trajectoryView.frame = controller.viewRectForVisionRect(normalizedFrame)
        }
        do {
            try visionHandler.perform([detectPlayerRequest])
            if let result = detectPlayerRequest.results?.first {
                let box = humanBoundingBox(for: result)
            }
        } catch {
            AppError.display(error, inViewController: self)
        }
    }
}
