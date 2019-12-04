//: A UIKit based Playground for presenting user interface
  
import UIKit
import PlaygroundSupport
import CoreImage

class MyViewController : UIViewController {
	
	
	var context: CIContext!
	var filter: CIFilter!
	var beginImage: CIImage!
	
	
    override func loadView() {
        let view = UIView()
//		let fileURL = Bundle.main.url(forResource: "COLOR-BARS", withExtension: "jpeg")
		let orgImage = UIImage(named: "COLOR-BARS.jpeg")
		let imageView = UIImageView(
			frame: CGRect(
				x: 0,
				y: 0,
				width: 320,
				height: 240
			)
		)
		
		let context = CIContext()                                           // 1
		let filter = CIFilter(name: "CIColorControls")!                        // 2
		filter.setValue(0.0, forKey: "inputSaturation")
		
		let image = CIImage(image: orgImage!)
		filter.setValue(image, forKey: kCIInputImageKey)
		
		let result = filter.outputImage!                                    // 4
		let cgImage = context.createCGImage(result, from: result.extent)    // 5

		imageView.image = UIImage(cgImage: cgImage!)
		
		view.backgroundColor = .white
		view.addSubview(imageView)
		
		imageView.contentMode = UIViewContentMode.scaleToFill

        self.view = view
    }
}
// Present the view controller in the Live View window
PlaygroundPage.current.liveView = MyViewController()
