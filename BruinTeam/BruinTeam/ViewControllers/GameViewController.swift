import UIKit
import MultipeerConnectivity
import GameKit

class GameViewController: UIViewController {
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var controlStackView: UIStackView!
    
    var serviceManager: DiscoveryServiceManager?
    var gameManager: GameManager?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // instructionLabel.text = "Toggle caffeine on!"
        
        //Controls.controls.forEach({ controlStackView.addArrangedSubview(controlViewFromModel(controlModel: $0)) })
        if let manager = self.gameManager {
            if let controls = manager.controls {
                controls.forEach({ controlStackView.addArrangedSubview(controlViewFromModel(controlModel: $0)) })
            }
        }
    }
    
    func updateControls(controls: [Control]) {
        controlStackView.subviews.forEach({ $0.removeFromSuperview() })
        controls.forEach({ controlStackView.addArrangedSubview(controlViewFromModel(controlModel: $0)) })
    }

    func controlViewFromModel(controlModel: Control) -> ControlView {
        let controlView = ControlView()
        controlView.controlLabel.text = controlModel.title
        
        switch controlModel.controlType {
        case .toggle:
            print("making toggle control for \(controlModel.title)")
            controlView.genericControl = UISwitch()
        case .segmentedControl:
            print("making segmented control for \(controlModel.title)")
            let segmentedControl = UISegmentedControl(items: controlModel.possibleValues as? [Any])
            segmentedControl.selectedSegmentIndex = 0
            controlView.genericControl = segmentedControl
        case .button:
            print("making button control for \(controlModel.title)")
            let button = UIButton(type: .roundedRect)
            button.setTitle(controlModel.possibleValues as? String, for: .normal)
            button.sizeToFit()
            controlView.genericControl = button
        case .slider:
            // TODO
            print("making slider control for \(controlModel.title)")
            controlView.genericControl = UISlider()
        }
        
        return controlView
    }
    
    
}

extension GameViewController: GameManagerDelegate {
    func receivedControls(controls: [Control]) {
        self.updateControls(controls: controls)
    }
    
    func commandChanged(command: String) {
        print("game view controller command changed")
        self.instructionLabel.text = command
    }
    
    
}
