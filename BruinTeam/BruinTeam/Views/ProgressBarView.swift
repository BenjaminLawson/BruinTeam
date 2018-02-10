import UIKit

@IBDesignable
class ProgressBarView: UIView {
    @IBInspectable
    var progress: CGFloat = 0.0 {
        didSet {
            // make sure it is in 0..1
            progress = max(0.0, min(1.0, progress))
            setNeedsDisplay()
        }
    }
    
    @IBInspectable
    var barColor: UIColor = UIColor.blue {
        didSet {
            setNeedsDisplay()
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
        self.contentMode = .redraw
    }
    
    override func draw(_ rect: CGRect) {
        let path = UIBezierPath(rect: CGRect(x: 0.0, y: 0.0, width: progress * rect.width, height: rect.height))
        barColor.setFill()
        path.fill()
    }
}
