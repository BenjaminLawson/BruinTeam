import UIKit

class GPAView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var barView: UIView!
    
    var fillView = UIView()
    
    
    var progress: CGFloat = 0.0 {
        didSet {
            setNeedsLayout()
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
        Bundle.main.loadNibNamed("GPAView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]

        fillView.backgroundColor = UIColor(red: 0, green: 0.6824, blue: 1, alpha: 1.0)
        barView.addSubview(fillView)
        
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateFillView()
    }
    
    func updateFillView() {
        fillView.frame = CGRect(x: 0.0, y: 0.0, width: progress * barView.bounds.width, height: barView.bounds.height)
    }
}
