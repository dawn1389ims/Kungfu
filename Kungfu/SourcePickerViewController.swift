/*
See LICENSE folder for this sample’s licensing information.

Abstract:
This view controller allows to choose the video source used by the app.
     It can be either a camera or a prerecorded video file.
*/

import UIKit
import AVFoundation

class SourcePickerViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
//        gameManager.stateMachine.enter(GameManager.InactiveState.self)
        
        var button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
          button.backgroundColor = .green
          button.setTitle("UploadVideo", for: .normal)
        button.addTarget(self, action: #selector(handleUploadVideoButton), for: .touchUpInside)
        self.view.addSubview(button)
        
        button = UIButton(frame: CGRect(x: 100+100*2, y: 100, width: 100, height: 50))
          button.backgroundColor = .green
          button.setTitle("LiveVideo", for: .normal)
        button.addTarget(self, action: #selector(goRootVC), for: .touchUpInside)
        self.view.addSubview(button)
    }
    
    @objc func handleUploadVideoButton(_ sender: Any) {
        let docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.movie], asCopy: true)
        docPicker.delegate = self
        present(docPicker, animated: true)
    }
    
    @objc func goRootVC(_ sender: Any) {
        self.present(RootViewController.init(), animated: true)
    }
    
    func revertToSourcePicker(_ segue: UIStoryboardSegue) {
        // This is for unwinding to this controller in storyboard.
        GameManager.shared.reset()
    }
}

extension SourcePickerViewController: UIDocumentPickerDelegate {
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        GameManager.shared.recordedVideoSource = nil
    }
    
    func  documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        GameManager.shared.recordedVideoSource = AVAsset(url: url)
        self.present(RootViewController.init(), animated: true)
    }
}
