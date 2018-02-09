import UIKit
import MultipeerConnectivity

class GameViewController: UIViewController {
    @IBOutlet weak var instructionLabel: UILabel?
    @IBOutlet weak var gpaLabel: UILabel!
    @IBOutlet weak var timerView: UIProgressView? // optional in case progress changed before view loaded
    @IBOutlet weak var controlStackView: UIStackView? // optional in case controls received before view loaded
    
    var gameManager: GameManager?
    
    // Timer
    var instructionTimer: Timer?
    var totalTime: Float = 0.0
    var currTime: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        timerView?.setProgress(100.0, animated: false)
        
        self.reloadControls()
        self.reloadInstruction()
    }
    
    /**
     Inserts assigned controls into the control stackview.
     */
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

    /**
    Makes a view with a centered UIControl corresponding to the ControlModel.
    Also sets up value change listener.
     */
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
            let possibleValues = controlModel.possibleValues as! [String]
            controlView.genericControl = LabeledSlider(names: possibleValues)
        }
        
        controlView.genericControl?.tag = controlModel.uid
        controlView.genericControl?.addTarget(self, action: #selector(controlValueChanged(sender:)), for: .valueChanged)
        
        return controlView
    }
    
    @objc func controlValueChanged(sender: UIControl) {
        gameManager?.handleStateChange(of: sender)
    }
    
    @objc func updateTimer() {
        if let instructionTimer = self.instructionTimer, instructionTimer.isValid {
            currTime -= 0.01
            if currTime <= 0.0 {
                print("timer expired")
                instructionTimer.invalidate()
                gameManager?.processTimerExpired()
            }
            else {
                timerView?.setProgress(currTime/totalTime, animated: true)
            }
        }
        else {
            instructionTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.updateTimer), userInfo: nil, repeats: true)
            totalTime = 0
            
            guard let gpa = gameManager?.gpa else { return }
            
            if gpa > 3.0 {
                totalTime = Float(arc4random_uniform(5)+5) // < 5 seconds is too hard, lol
            }
            else if gpa > 2.0 {
                totalTime = Float(arc4random_uniform(10)+3)
            }
            else if gpa > 1.0 {
                totalTime = Float(arc4random_uniform(15)+3)
            }
            else {
                totalTime = Float(arc4random_uniform(20)+3)
            }
            currTime = totalTime
            timerView?.setProgress(1.0, animated: false)
        }
    }
}

extension GameViewController: GameManagerDelegate {
    func gameEnded(withResult won: Bool) {
        instructionTimer?.invalidate()
        gameManager?.serviceManager.session.disconnect()
        
        performSegue(withIdentifier: "gameOverSegue", sender: nil)
    }
    
    func gpaChanged(to gpa: Float) {
        gpaLabel.text = "GPA: \(gpa)"
    }
    
    func controlsChanged(to controls: [Control]) {
        self.reloadControls()
    }
    
    
    func instructionChanged(to command: String) {
        self.reloadInstruction()
        
        instructionTimer?.invalidate()
        self.updateTimer()
    }
    
    
}
