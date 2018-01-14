import UIKit

class ControlView: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var controlLabel: UILabel!
    @IBOutlet weak var controlContainerView: UIView!
    
    var genericControl: UIControl? {
        didSet {
            controlContainerView.subviews.forEach({ $0.removeFromSuperview() })
            controlContainerView.addSubview(genericControl!)
            centerControl(control: genericControl!)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        print("ControlView Init")
        
        Bundle.main.loadNibNamed("ControlView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
    }
    
    private func centerControl(control: UIControl) {
        control.translatesAutoresizingMaskIntoConstraints = false
        control.widthAnchor.constraint(equalToConstant: control.frame.width).isActive = true
        control.heightAnchor.constraint(equalToConstant: control.frame.height).isActive = true
        control.centerXAnchor.constraint(equalTo: controlContainerView.centerXAnchor).isActive = true
        control.centerYAnchor.constraint(equalTo: controlContainerView.centerYAnchor).isActive = true
    }
}
