import UIKit
import MultipeerConnectivity
import GameKit

class GameViewController: UIViewController {
    @IBOutlet weak var instructionLabel: UILabel?
    @IBOutlet weak var controlStackView: UIStackView?
    
    var gameManager: GameManager?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.reloadControls()
        self.reloadInstruction()
    }
    
    func reloadControls() {
        controlStackView?.subviews.forEach { $0.removeFromSuperview() }
        gameManager?.controls?.forEach { controlStackView?.addArrangedSubview(controlViewFromModel(controlModel: $0)) }
    }
    
    func reloadInstruction() {
        instructionLabel?.text = gameManager?.currentInstruction ?? "Wait for instruction..."
    }

    func controlViewFromModel(controlModel: Control) -> ControlView {
        let controlView = ControlView()
        controlView.controlLabel.text = controlModel.title
        
        switch controlModel.controlType {
        case .toggle:
            print("making toggle control for \(controlModel.title)")
            let controlSwitch = UISwitch()
            controlView.genericControl = controlSwitch
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
            button.addTarget(self, action: #selector(controlValueChanged(sender:)), for: .touchUpInside) // value doesn't change, listen for touch
        case .slider:
            // TODO
            print("making slider control for \(controlModel.title)")
            controlView.genericControl = UISlider()
        }
        
        controlView.genericControl?.tag = controlModel.uid
        controlView.genericControl?.addTarget(self, action: #selector(controlValueChanged(sender:)), for: .valueChanged)
        
        return controlView
    }
    
    @objc func controlValueChanged(sender: UIControl) {
        gameManager?.handleStateChange(of: sender)
        //let stateDict = InstructionManager.stateDictFromUIControl(control: sender)
        
        
        print("control \(sender.tag) value changed")
        if let control = sender as? UISwitch {
            print("switch control")
        }
        else if let control = sender as? UISegmentedControl {
            print("segmented control")
        }
        else if let control = sender as? UIButton {
            print("button press")
        }
        else if let control = sender as? UISlider {
            print("slider control")
        }
    }
}

extension GameViewController: GameManagerDelegate {
    func controlsChanged(to controls: [Control]) {
        self.reloadControls()
    }
    
    
    func instructionChanged(to command: String) {
        print("game view controller command changed")
        self.reloadInstruction()
    }
    
    
}
