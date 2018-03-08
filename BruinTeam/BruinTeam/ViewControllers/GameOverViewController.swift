import UIKit

// TODO: set didWin on segue
class GameOverViewController: UIViewController {
    @IBOutlet weak var gameOverLabel: UILabel!
    
    var didWin: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameOverLabel.text = didWin ? "You won!!!" : "You lost!!!"

        if (didWin) {
            self.view.addBackground(imageName: "ucla")
        } else {
            self.view.addBackground(imageName: "usc")
        }
    }
    
    @IBAction func startOverButtonPressed(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
}

extension UIView {
    func addBackground(imageName: String = "ucla", contentMode: UIViewContentMode = .scaleToFill) {
        // setup the UIImageView
        let backgroundImageView = UIImageView(frame: UIScreen.main.bounds)
        backgroundImageView.image = UIImage(named: imageName)
        backgroundImageView.contentMode = contentMode
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(backgroundImageView)
        sendSubview(toBack: backgroundImageView)
        
        // adding NSLayoutConstraints
        let leadingConstraint = NSLayoutConstraint(item: backgroundImageView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0.0)
        let trailingConstraint = NSLayoutConstraint(item: backgroundImageView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        let topConstraint = NSLayoutConstraint(item: backgroundImageView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
        let bottomConstraint = NSLayoutConstraint(item: backgroundImageView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: 0.0)
        
        NSLayoutConstraint.activate([leadingConstraint, trailingConstraint, topConstraint, bottomConstraint])
    }
}
