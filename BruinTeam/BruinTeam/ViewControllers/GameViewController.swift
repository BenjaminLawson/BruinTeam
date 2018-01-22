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
        guard let label = instructionLabel,
        let text = gameManager?.currentInstruction else { return }

        let oldOrigin = label.frame.origin
        
        self.view.layoutIfNeeded()
        UIView.transition(with: label, duration: 1.0, options: [.curveEaseIn], animations: {
            label.frame.origin.y -= 30
            label.alpha = 0.0
        }, completion: { finished in
            label.frame.origin = oldOrigin
            label.text = text
            label.alpha = 1.0
        })
    }

    func controlViewFromModel(controlModel: Control) -> ControlView {
        let controlView = ControlView()
        controlView.controlLabel.text = controlModel.title
        
        switch controlModel.controlType {
        case .toggle:
            let controlSwitch = UISwitch()
            controlView.genericControl = controlSwitch
        case .segmentedControl:
            let segmentedControl = UISegmentedControl(items: controlModel.possibleValues as? [Any])
            segmentedControl.selectedSegmentIndex = 0
            controlView.genericControl = segmentedControl
        case .button:
            let button = UIButton(type: .roundedRect)
            button.setTitle(controlModel.possibleValues as? String, for: .normal)
            button.sizeToFit()
            controlView.genericControl = button
            button.addTarget(self, action: #selector(controlValueChanged(sender:)), for: .touchUpInside) // value doesn't change, listen for touch
        case .slider:
            // TODO
            print("making slider control for \(controlModel.title)")
            let slider = UISlider()
            slider.isContinuous = false // only trigger value change when you let go
            let possibleValues = controlModel.possibleValues as! [Int]
            slider.minimumValue = 0.0
            slider.maximumValue = Float(possibleValues.count - 1)
            slider.frame = CGRect(x: 0, y: 0, width: possibleValues.count * 40, height: 30)
            
            controlView.genericControl = slider
        }
        
        controlView.genericControl?.tag = controlModel.uid
        controlView.genericControl?.addTarget(self, action: #selector(controlValueChanged(sender:)), for: .valueChanged)
        
        return controlView
    }
    
    @objc func controlValueChanged(sender: UIControl) {
        // round slider value
        if let slider = sender as? UISlider {
            let index = Int(slider.value + 0.5)
            slider.setValue(Float(index), animated: false)
        }
        
        gameManager?.handleStateChange(of: sender)
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
