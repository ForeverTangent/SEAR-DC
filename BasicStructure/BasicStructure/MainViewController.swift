//
//  ViewController.swift
//  BasicStructure
//
//  Created by Stanley Rosenbaum on 10/5/17.
//  Copyright © 2017 Rosenbaum. All rights reserved.
//

// Help from:
// https://www.hackingwithswift.com/example-code/media/how-to-save-a-uiimage-to-a-file-using-uiimagepngrepresentation


import UIKit
import CoreMotion


protocol DisplayImages {
	func displayDepth( image : UIImage )
	func displayColor( image : UIImage )
	func storeDistance( array: [Float] )
}


class MainViewController: UIViewController,
	UIPickerViewDataSource,
	UIPickerViewDelegate,
    DisplayImages {


	// MARK: CLASS PROPERTIES
	var stairsPickerDataSource = [["UP", "BLOCK", "NA", "HOLE", "DOWN"],["NONE","LIP","OPEN"],["CLEAR","OCCUPIED"]];
	var stSensorManager : STSensorManagement = STSensorManagement()
	let cmMotionManager = CMMotionManager()
	var cmMotionManagerTimer : Timer?
	
	var pickerSelection : [String] = ["", "",""]
	var currentDeviceAngle : Double = 0.0
	
	var lastPicturePrefixID : Int = 0

	var distanceArray: [Float] = [Float]()
	
	// MARK: LAZY PROPERTIES
	/**
	Set a class various to check if we are running in simulator so we
	Don't always have to check UIApplication.shared.delegate
	*/
	lazy var runningSimulator : Bool = self.getIfRunningInSim()
	func getIfRunningInSim() -> Bool {
		let appDelegate = UIApplication.shared.delegate as! AppDelegate
		return appDelegate.runningSimulator
		
	}

	
	// MARK: IBOutputs
	
	@IBOutlet weak var ColorImageView: UIImageView!
	@IBOutlet weak var DepthImageView: UIImageView!
	@IBOutlet weak var stairsPickerView: UIPickerView!
	@IBOutlet weak var messageField: UITextField!
	
	
	// MARK: IBActions
	/**
	Our Capture Data button
	https://stackoverflow.com/questions/42365486/writing-to-text-file-in-swift-3
	https://stackoverflow.com/questions/11776737/how-can-i-access-default-ios-sound-to-set-it-as-notification-sound#11776907
	
	*/
	@IBAction func CaptureButtonTouchUp(_ sender: UIButton) {
		
		// Play Start Tone
		AudioServicesPlaySystemSound(1057);
		
		// Get Unix Time for Prefix ID.
		// This if statement is jsut a safety to make sure no one then 1 photo is taken a
		// sec to prevent ID collisions.
		if( self.lastPicturePrefixID != Int(NSDate().timeIntervalSince1970) ) {
			
			// Only take a picture if the sensor is connected.
			if self.stSensorManager.stSensorController.isConnected() {
				
				self.lastPicturePrefixID = Int(NSDate().timeIntervalSince1970)
				let currentID : String = String(self.lastPicturePrefixID)
				let floppedDistanceArray = flop(depthArray: self.distanceArray)
				
				let dataRecord = self.createDataStringForCSVWith(
					prefix: currentID,
					obstacle: self.pickerSelection[0],
					type: self.pickerSelection[1],
					occupated: self.pickerSelection[2],
					angle: Float(self.currentDeviceAngle)
				)
				self.save(csvRecordData: dataRecord)
				
				
//				let dataString = self.createDataStringForCSVWith(
//					prefix: currentID,
//					obstacle: self.pickerSelection[0],
//					type: self.pickerSelection[1],
//					occupated: self.pickerSelection[2],
//					angle: Float(self.currentDeviceAngle),
//					depthArray: self.distanceArray
//				)
//				self.save(csvData: dataString)
//
//
//				let dataStringFlopped = self.createDataStringForCSVWith(
//					prefix: currentID,
//					obstacle: self.pickerSelection[0],
//					type: self.pickerSelection[1],
//					occupated: self.pickerSelection[2],
//					angle: Float(self.currentDeviceAngle),
//					depthArray: floppedDistanceArray
//				)
//				self.saveFlopped(csvData: dataStringFlopped)
				
				self.save(
					depthData: self.createDataStringForCSVForJust(depthArray: self.distanceArray),
					for: currentID,
					flopped: false
				)
				
				
				self.save(
					depthData: self.createDataStringForCSVForJust(depthArray: floppedDistanceArray),
					for: currentID,
					flopped: true
				)
				
				
				self.saveImages(with: currentID)
				
				// Default camera sound
				AudioServicesPlaySystemSound(1108);
				
				
				self.messageField.text = "Data Captured. Free Space: \(self.remainingDiskSpaceOnThisDevice())"
				
			
			}
		}
	}
	
	
	@IBAction func showHelp(_ sender: Any) {
		
		let modalViewController = storyboard?.instantiateViewController(withIdentifier: "ModalView") as! ModalViewController
		
		present(modalViewController, animated: true, completion: nil)
		
		
	}
	
	
	
	// MARK: OVERRIDES
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		self.stSensorManager.displayImagesDelegate = self
		
		self.stairsPickerView.dataSource = self
		self.stairsPickerView.delegate = self
		
		// Set up Initial Picker Data
		self.stairsPickerView.selectRow(0, inComponent: 0, animated: false)
		self.pickerSelection[0] = self.stairsPickerDataSource[0][0]
		self.stairsPickerView.selectRow(0, inComponent: 1, animated: false)
		self.pickerSelection[1] = self.stairsPickerDataSource[1][0]
		self.stairsPickerView.selectRow(0, inComponent: 2, animated: false)
		self.pickerSelection[2] = self.stairsPickerDataSource[2][0]
		
		self.setupNotifications()
		
		self.startDeviceMotion()

		if( stSensorManager.stSensorController.isConnected() ) {
			self.messageField.text = "Sensor Connected.  Starting Up."
		} else {
			self.messageField.text = "Connect Structure Sensor"
		}

//		UIApplication.shared.isIdleTimerDisabled = true
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
	override func viewWillDisappear(_ animated: Bool) {

		self.cmMotionManager.stopGyroUpdates()
		self.cmMotionManager.stopDeviceMotionUpdates()

		self.removeNotifications()
		
	}

	
	
	// MARK: PROTOCOL FUNCTIONS Picker
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 3
	}
	
	func pickerView(
		_ pickerView: UIPickerView,
		titleForRow row: Int,
		forComponent component: Int
		) -> String? {
		
		var returnString : String = ""
		
		if( component == 0) {
			returnString = self.stairsPickerDataSource[0][row]
		}
		
		if( component == 1) {
			returnString = self.stairsPickerDataSource[1][row]
		}

		if( component == 2) {
			returnString = self.stairsPickerDataSource[2][row]
		}
		
		return returnString
		
	}
	
	
	func pickerView(
		_ pickerView: UIPickerView,
		numberOfRowsInComponent component: Int
		) -> Int
	{
		var returnInt : Int = 0
		
		if( component == 0 ){
			returnInt = 5
		}
		
		if( component == 1){
			returnInt = 3
		}
		
		if( component == 2){
			returnInt = 2
		}
		
		return returnInt
	}
	
	
	// Catpure the picker view selection
	func pickerView(
		_ pickerView: UIPickerView,
		didSelectRow row: Int,
		inComponent component: Int
		) {
		// This method is triggered whenever the user makes a change to the picker selection.
		// The parameter named row and component represents what was selected.
		
//		NSLog("Picker Selected : \(self.stairsPickerDataSource[component][row])")
		self.pickerSelection[component] = self.stairsPickerDataSource[component][row]
		
	}
	
	
	// MARK: PROTOCOL FUNCTIONS ImageDisplay

	/**
	Displays the Depth Image in the Viewer
	*/
	func displayDepth(image: UIImage) {
		self.DepthImageView.image = image
	}
	
	
	/**
	Displays the Color Image [as grayscale in the Viewer
	*/
	func displayColor(image: UIImage) {
		let grayImageOfColorCamera = self.createGrayScaleImageFrom(originalImage: image)
		self.ColorImageView.image = grayImageOfColorCamera
	}
	
	
	/**
	Store the distance array.
	*/
	func storeDistance( array: [Float] ) {
		self.distanceArray = array
	}
	
	
	//MARK: MEMBER FUNCTIONS
	/**
	Set up the Notification Receivers
	*/
	func setupNotifications() {
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(self.appDidBecomeActive),
			name: UIApplication.didBecomeActiveNotification,
			object: nil
		)
		
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(self.appDidBecomeInactive),
			name: UIApplication.didEnterBackgroundNotification,
			object: nil
		)
		
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(self.setDebugSensorViewWith(imageNotification:)),
			name: NSNotification.Name(rawValue: "SENSOR_IMAGE" ),
			object: nil
		)
		
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(self.setDebugSensorViewWith(imageNotification:)),
			name: NSNotification.Name(rawValue: "COLOR_IMAGE" ),
			object: nil
		)
		

		// Message notification
		NotificationCenter.default.addObserver(
			self,
			selector: #selector( self.updateTextFieldWith(notification:) ),
			name: NSNotification.Name(rawValue: "MESSAGE" ),
			object: nil
		)
		
		
	}
	
	/**
	Remove Notifications.
	*/
	func removeNotifications() {
		
		NotificationCenter.default.removeObserver(
			self,
			name: NSNotification.Name( rawValue: "MESSAGE" ),
			object: nil
		)
		
		NotificationCenter.default.removeObserver(
			self,
			name: NSNotification.Name( rawValue: "SENSOR_IMAGE" ),
			object: nil
		)
		
		NotificationCenter.default.removeObserver(
			self,
			name: NSNotification.Name( rawValue: "COLOR_IMAGE" ),
			object: nil
		)
		
		NotificationCenter.default.removeObserver(
			self,
			name: UIApplication.didBecomeActiveNotification,
			object: nil
		)
		
		NotificationCenter.default.removeObserver(
			self,
			name: UIApplication.didEnterBackgroundNotification,
			object: nil
		)
		
	}
	
	
	/**
	Setup Timer
	*/
	func setUpTimer() {
		
	}
	
	
	
	/**
	Update Status bar with info
	- Parameter notification: NSNotification, with heading info.
	*/
	@objc func updateTextFieldWith( notification: NSNotification ) {
		let message : String = notification.userInfo!["MESSAGE"] as! String
		self.setTextFieldWith( newMessage: message )
		
	}
	
	/**
	Update the Status Info Labael
	*/
	func setTextFieldWith( newMessage: String ) {
		self.messageField.text = newMessage
		NSLog( newMessage )
		
	}
	

	/**
	Check if Application became active.
	*/
	@objc func appDidBecomeActive() {
		if( self.stSensorManager.connectAndStartSTSStreaming() ) {
			self.setTextFieldWith( newMessage: "STSensor Connected and Streaming" )
		}
		
	}
	
	
	/**
	Check if Application became paused.
	*/
	@objc func appDidBecomeInactive() {
		self.stSensorManager.stopSensorAndCameraStreaming()
		
	}
	
	
	/**
	NSNotification Function so set Sensor View.
	- Parameter imageNotification: NSNotification, with UIImage Data.
	*/
	@objc func setDebugSensorViewWith( imageNotification: NSNotification ) {
		let theImage : UIImage = imageNotification.userInfo!["DEPTH-IMAGE"] as! UIImage
		self.setDebugSensorView( image : theImage )
		
	}
	
	
	/**
	NSNotification Function so set Camera View.
	- Parameter imageNotification: NSNotification, with UIImage Data.
	*/
	@objc func setDebugCameraViewWith( imageNotification: NSNotification ) {
		let theImage : UIImage = imageNotification.userInfo!["COLOR-IMAGE"] as! UIImage
		self.setDebugCameraView( image : theImage )

	}
	
	
	/**
	Sets the sensor views for debugging
	- Parameters:
	- image: The UIImage
	*/
	func setDebugSensorView(image: UIImage) {
		self.DepthImageView.image = image

	}
	
	
	/**
	Sets the camera views for debugging
	- Parameters:
	- image: The UIImage
	*/
	func setDebugCameraView(image: UIImage) {
		self.ColorImageView.image = image

	}
	
	/**
	- Parameters:
	- timer: The Timer passing info,
	*/
	@objc func attitudeTimerUpdate() {
		
		if let accelerometerData = self.cmMotionManager.accelerometerData {
			NSLog( String( describing:accelerometerData) )
		}
		if let gyroData = self.cmMotionManager.gyroData {
			NSLog( String( describing:gyroData) )
		}
		if let magnetometerData = self.cmMotionManager.magnetometerData {
			NSLog( String( describing:magnetometerData) )
		}
		if let deviceMotion = self.cmMotionManager.deviceMotion {
			NSLog( String( describing:deviceMotion) )
		}
		
	}
	
	/**
	From Apple's Getting Processed Device Motion Data article.
	*/
	func startDeviceMotion() {
		if self.cmMotionManager.isDeviceMotionAvailable {
			self.cmMotionManager.deviceMotionUpdateInterval = 1.0 / 60
			self.cmMotionManager.showsDeviceMovementDisplay = true
			self.cmMotionManager.startDeviceMotionUpdates(using: .xMagneticNorthZVertical)
			
			// Configure a timer to fetch the motion data.
			
			self.cmMotionManagerTimer = Timer(
				timeInterval: 1.0 / 60,
				repeats: true,
				block: {
					(timer) in
					if let data = self.cmMotionManager.deviceMotion {
						// Get the attitude relative to the magnetic north reference frame.
//						let pitch = data.attitude.pitch
						let roll = data.attitude.roll
//						let yaw = data.attitude.yaw
						
//						let pitchD = BSMath.radToDeg(radians: pitch)
						let rollD = BSMath.radToDeg(radians: roll)
//						let yawD = BSMath.radToDeg(radians: yaw)
						
						self.currentDeviceAngle = -(rollD + 90)
						
//						NSLog( String(format: "%.2f", rollD ) )
						// Use the motion data in your app.
					}
				}
			)
			
			// Add the timer to the current run loop.
			RunLoop.current.add(
				self.cmMotionManagerTimer!,
				forMode: RunLoop.Mode.default
			)

		}
	}
	
	
	/**
	Creates a GrayScale Image
	- Parameters:
	- image: A UIImage to filter.
	- Returns: A UIImage
	*/
	func createGrayScaleImageFrom( originalImage: UIImage ) -> UIImage {

		// Create Context
		let context = CIContext()
		
		// Create Filter  [CIColorControls for Saturation access]
		let filter = CIFilter(name: "CIColorControls")!                        // 2
		filter.setValue(0.0, forKey: "inputSaturation")
		
		// Create a CIImage object representing the image to be processed
		let originalCIImage = CIImage(image: originalImage)
		
		// Apply filter to image.
		filter.setValue(originalCIImage, forKey: kCIInputImageKey)
		
		// Get a CIImage object representing the filter’s output.
		let returnCGImage = filter.outputImage!                                    // 4
		
		// Render the output image to a Core Graphics image
		let cgImage = context.createCGImage(returnCGImage, from: returnCGImage.extent)    // 5
		
		// Return UI version of CGImage
		return UIImage(cgImage: cgImage!)
		
	}
	
	
	/**
	To build the string to record in the CSV.
	[This function is particular for the data for SEAR-DC]
	-Parameters:
	-prefix: String of the IDing Prefix
	-obstacle: String, of what is in encountered
	-type: String, type of obstacle, if stairs
	-depthArray: the Depth array.
	-Returns: a String
	*/
	func createDataStringForCSVWith(
		prefix: String,
		obstacle : String,
		type: String,
		occupated: String,
		angle: Float,
		depthArray: [Float]
		) -> String {
		
		var returnString : String = ""
		
		returnString.append(prefix)
		returnString.append("," + String(format: "%.2f", angle))
		returnString.append("," + obstacle)
		returnString.append("," + type)
		returnString.append("," + occupated)
		
		for element in depthArray {
			returnString.append(",\(element)")
		}
		
		returnString.append("\n")
		
		return returnString
		
	}
	
	
	/**
	To build the string to record all info but depth data.
	[This function is particular for the data for SEAR-DC]
	-Parameters:
	-prefix: String of the IDing Prefix
	-obstacle: String, of what is in encountered
	-type: String, type of obstacle, if stairs
	-Returns: a String
	*/
	func createDataStringForCSVWith(
		prefix: String,
		obstacle : String,
		type: String,
		occupated: String,
		angle: Float
		) -> String {
		
		var returnString : String = ""
		
		returnString.append(prefix)
		returnString.append("," + String(format: "%.2f", angle))
		returnString.append("," + obstacle)
		returnString.append("," + type)
		returnString.append("," + occupated)
		
		returnString.append("\n")
		
		return returnString
		
	}


	/**
	To builds a String of the Depth Data only.

	-depthArray: the Depth array.
	-Returns: a String
	*/
	func createDataStringForCSVForJust(
		depthArray: [Float]
		) -> String {
		
		var returnString : String = ""
		returnString.append("\(depthArray[0])")
		
		let remainingArray = Array(depthArray[1...])
		
		for element in remainingArray {
			returnString.append(",\(element)")
		}
		
		returnString.append("\n")
		
		return returnString
		
	}
	
	
	/**
	Saves the Point Cloud Data in CSV.
	- Parameter csvData: The String with all the CSV data
	*/
	func save(depthData: String, for ID: String, flopped: Bool ) {
		
		// Set a Filename for the Files.
		var fileURL : URL
		
		if( flopped ) {
			fileURL = getDocumentsDirectory().appendingPathComponent("\(ID)_PCLOUD_FLOP.csv")
		} else {
			fileURL = getDocumentsDirectory().appendingPathComponent("\(ID)_PCLOUD_NORM.csv")
		}
		
		
		let data = depthData.data(using: .utf8, allowLossyConversion: false)!
		
		if FileManager.default.fileExists(atPath: fileURL.path) {
			if let fileHandle = try? FileHandle(forUpdating: fileURL) {
				fileHandle.seekToEndOfFile()
				fileHandle.write(data)
				fileHandle.closeFile()
			}
		} else {
			try! data.write(to: fileURL, options: Data.WritingOptions.atomic)
		}
		
	}
	
	
	/**
	Saves the Record Data as CSV
	- Parameter csvData: The String with all the CSV data
	*/
	func save(csvRecordData: String) {
		
		// Set a Filename for the Files.
		let fileURL =  getDocumentsDirectory().appendingPathComponent("SEAR_DC_INFO.csv")
		
		let data = csvRecordData.data(using: .utf8, allowLossyConversion: false)!
		
		if FileManager.default.fileExists(atPath: fileURL.path) {
			if let fileHandle = try? FileHandle(forUpdating: fileURL) {
				fileHandle.seekToEndOfFile()
				fileHandle.write(data)
				fileHandle.closeFile()
			}
		} else {
			try! data.write(to: fileURL, options: Data.WritingOptions.atomic)
		}
		
	}
	
	/**
	Saves the Record and NORMAL Point Cloud Data as CSV
	- Parameter csvData: The String with all the CSV data
	*/
	func save(csvData: String) {

		// Set a Filename for the Files.
		let fileURL =  getDocumentsDirectory().appendingPathComponent("SEAR_DC_INFO+DEPTH_NORM.csv")
		
		let data = csvData.data(using: .utf8, allowLossyConversion: false)!
		
		if FileManager.default.fileExists(atPath: fileURL.path) {
			if let fileHandle = try? FileHandle(forUpdating: fileURL) {
				fileHandle.seekToEndOfFile()
				fileHandle.write(data)
				fileHandle.closeFile()
			}
		} else {
			try! data.write(to: fileURL, options: Data.WritingOptions.atomic)
		}
		
	}
	
	/**
	Saves the Record and FLOPPED Point Cloud Data as CSV
	- Parameter csvData: The String with all the CSV data
	*/
	func saveFlopped(csvData: String) {
		
		// Set a Filename for the Files.
		let fileURL =  getDocumentsDirectory().appendingPathComponent("SEAR_DC_INFO+DEPTH_FLOP.csv")
		
		let data = csvData.data(using: .utf8, allowLossyConversion: false)!
		
		if FileManager.default.fileExists(atPath: fileURL.path) {
			if let fileHandle = try? FileHandle(forUpdating: fileURL) {
				fileHandle.seekToEndOfFile()
				fileHandle.write(data)
				fileHandle.closeFile()
			}
		} else {
			try! data.write(to: fileURL, options: Data.WritingOptions.atomic)
		}
		
	}
	
	
	/**
	Save the Images as PNGs
	- Parameter prefix: the File ID Prefix
	*/
	func saveImages(with prefix: String ){
		
		let depthImage = self.DepthImageView.image
		let colorImage = self.ColorImageView.image
		
		let depthImageFlopped = self.flipImageLeftRight( self.DepthImageView.image!)
		let colorImageFlopped = self.flipImageLeftRight( self.ColorImageView.image!)
		
		if let depthImageData = depthImage!.pngData() {
			let depthImageFilename = getDocumentsDirectory().appendingPathComponent("\(prefix)_IDEPTH_NORM.png")
			try? depthImageData.write(to: depthImageFilename)
		}

		if let depthImageFlopData = depthImageFlopped!.pngData() {
			let depthImageFlopFilename = getDocumentsDirectory().appendingPathComponent("\(prefix)_IDEPTH_FLOP.png")
			try? depthImageFlopData.write(to: depthImageFlopFilename)
		}
		
		if let colorImageData = colorImage!.pngData() {
			let colorImageFilename = getDocumentsDirectory().appendingPathComponent("\(prefix)_ICOLOR_NORM.png")
			try? colorImageData.write(to: colorImageFilename)
		}
		
		if let colorImageFlopData = colorImageFlopped!.pngData() {
			let colorImageFlopFilename = getDocumentsDirectory().appendingPathComponent("\(prefix)_ICOLOR_FLOP.png")
			try? colorImageFlopData.write(to: colorImageFlopFilename)
		}
		
	}
	
	/**
	Tiny helper function to get Document Directory
	- Returns: a URL
	*/
	func getDocumentsDirectory() -> URL {
		let path = FileManager.default.urls(
			for: FileManager.SearchPathDirectory.documentDirectory,
			in: FileManager.SearchPathDomainMask.userDomainMask).first!
		return path
	}

	
	/**
	Found Here:
	https://stackoverflow.com/questions/5712527/how-to-detect-total-available-free-disk-space-on-the-iphone-ipad-device
	*/
	func remainingDiskSpaceOnThisDevice() -> String {
		var remainingSpace = NSLocalizedString("Unknown", comment: "Free space unknown.")
		if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
			let freeSpaceSize = attributes[FileAttributeKey.systemFreeSize] as? Int64 {
			remainingSpace = ByteCountFormatter.string(fromByteCount: freeSpaceSize, countStyle: .file)
		}
		return remainingSpace
	}
	
	
	/**
	Flops the depth array
	- Parameter depthArray: A [Float] to Flop
	- Returns: [Float], A Float Array
	*/
	func flop( depthArray: [Float] ) -> [Float] {
		var returnArray : [Float] = [Float]()
		
		var theDepthArray = depthArray
		
		while( theDepthArray.count != 0 ){
			let oneRow : [Float] = Array(theDepthArray[0..<640])
			theDepthArray = Array(theDepthArray[640...])
			
			var oneRowRev = Array( oneRow.reversed() )
			
			for element in oneRowRev {
				returnArray.append(element)
			}
			
			oneRowRev.removeAll()
			
		}
		return returnArray
		
	}
	
	
	
	/**
	https://stackoverflow.com/questions/24965638/how-to-flip-uiimage-horizontally-with-swift#24965768
	*/
	func flipImageLeftRight(_ image: UIImage) -> UIImage? {
		
		UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
		let context = UIGraphicsGetCurrentContext()!
		context.translateBy(x: image.size.width, y: image.size.height)
		context.scaleBy(x: -image.scale, y: -image.scale)
		
		context.draw(image.cgImage!, in: CGRect(origin:CGPoint.zero, size: image.size))
		
		let newImage = UIGraphicsGetImageFromCurrentImageContext()
		
		UIGraphicsEndImageContext()
		
		return newImage
		
	}

}

