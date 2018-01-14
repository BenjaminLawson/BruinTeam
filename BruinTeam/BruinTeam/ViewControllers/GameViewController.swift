import UIKit

class GameViewController: UIViewController {
    @IBOutlet weak var instructionLabel: UILabel!
    @IBOutlet weak var controlStackView: UIStackView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        instructionLabel.text = "Toggle caffeine on!"
        
        //Controls.controls.forEach({ controlStackView.addArrangedSubview(controlViewFromModel(controlModel: $0)) })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            controlView.genericControl = UISegmentedControl(items: controlModel.possibleValues as? [Any])
        case .button:
            print("making button control for \(controlModel.title)")
            let button = UIButton(type: .roundedRect)
            button.setTitle(controlModel.possibleValues as? String, for: .normal)
            button.sizeToFit()
            controlView.genericControl = button
        case .slider:
            print("making slider control for \(controlModel.title)")
            controlView.genericControl = UISlider()
        }
        
        return controlView
    }
}
