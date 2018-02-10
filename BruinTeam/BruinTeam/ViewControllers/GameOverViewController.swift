import UIKit

// TODO: set didWin on segue
class GameOverViewController: UIViewController {
    @IBOutlet weak var gameOverLabel: UILabel!
    
    var didWin: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameOverLabel.text = didWin ? "You won!!!" : "You lost!!!"
    }
    
    @IBAction func startOverButtonPressed(_ sender: Any) {
        self.navigationController?.popToRootViewController(animated: true)
    }
}
