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



class MainViewController: UIViewController,
	UIPickerViewDataSource,
	UIPickerViewDelegate,
    DisplayImages {


	// MARK: CLASS PROPERTIES
	var stairsPickerDataSource = [["UP", "BLOCK", "NA", "HOLE", "DOWN"],["1","2","3","4","5","6","7","8"],["NONE","LIP","OPEN"]];
	var stSensorManager : STSensorManagement = STSensorManagement()
	let cmMotionManager = CMMotionManager()
	var cmMotionManagerTimer : Timer?
	
	var distanceArray: [Float]?
	
	
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
		//
		
		AudioServicesPlaySystemSound(1057);
		
		let dir = FileManager.default.urls(
			for: FileManager.SearchPathDirectory.documentDirectory,
			in: FileManager.SearchPathDomainMask.userDomainMask).first!
		let fileURL =  dir.appendingPathComponent("log.txt")
		
		let string = "\(NSDate())\n"
		let data = string.data(using: .utf8, allowLossyConversion: false)!
		
		if FileManager.default.fileExists(atPath: fileURL.path) {
			if let fileHandle = try? FileHandle(forUpdating: fileURL) {
				fileHandle.seekToEndOfFile()
				fileHandle.write(data)
				fileHandle.closeFile()
			}
		} else {
			try! data.write(to: fileURL, options: Data.WritingOptions.atomic)
		}
		
		NSLog( "UNIX TIME: \(NSDate().timeIntervalSince1970)" )
		
		
		// Default camera sound
		AudioServicesPlaySystemSound(1108);
		self.stairsPickerView.selectRow(2, inComponent: 0, animated: false)
		self.stairsPickerView.selectRow(0, inComponent: 1, animated: false)
		self.stairsPickerView.selectRow(0, inComponent: 2, animated: false)
	}
	
	
	// MARK: OVERRIDES
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		self.stSensorManager.displayImagesDelegate = self
		
		self.stairsPickerView.dataSource = self
		self.stairsPickerView.delegate = self
		self.stairsPickerView.selectRow(2, inComponent: 0, animated: false)
		
		self.setupNotifications()
		
		self.startDeviceMotion()
		

		if( stSensorManager.stSensorController.isConnected() ) {
			self.messageField.text = "Sensor Connected.  Starting Up."
		} else {
			self.messageField.text = "Connect Structure Sensor"
		}
		

	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
	override func viewWillDisappear(_ animated: Bool) {
		
//		self.cmMotionManagerTimer?.invalidate()
		
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
	
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
	{
		var returnInt : Int = 0
		
		if( component == 0 ){
			returnInt = 5
		}
		
		if( component == 1){
			returnInt = 8
		}
		
		if( component == 2){
			returnInt = 3
		}
		
		return returnInt
	}
	
	// Catpure the picker view selection
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		// This method is triggered whenever the user makes a change to the picker selection.
		// The parameter named row and component represents what was selected.
		
		NSLog("Something Selected")
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
			name: NSNotification.Name.UIApplicationDidBecomeActive,
			object: nil
		)
		
		
		NotificationCenter.default.addObserver(
			self,
			selector: #selector(self.appDidBecomeInactive),
			name: NSNotification.Name.UIApplicationDidEnterBackground,
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
			name: NSNotification.Name.UIApplicationDidBecomeActive,
			object: nil
		)
		
		NotificationCenter.default.removeObserver(
			self,
			name: NSNotification.Name.UIApplicationDidEnterBackground,
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
						var rollD = BSMath.radToDeg(radians: roll)
//						let yawD = BSMath.radToDeg(radians: yaw)
						
						rollD = -(rollD + 90)
						
//						NSLog( String(format: "%.2f", rollD ) )
						// Use the motion data in your app.
					}
				}
			)
			
			// Add the timer to the current run loop.
			RunLoop.current.add(
				self.cmMotionManagerTimer!,
				forMode: .defaultRunLoopMode
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
	*/
	func save( image: UIImage, with filePrefix: String) {
		
		
		
		
	}
	
	
	
	/**
	Helper function I got here:
	https://www.hackingwithswift.com/example-code/media/how-to-save-a-uiimage-to-a-file-using-uiimagepngrepresentation
	- Returns: URL
	*/
	func getDocumentsDirectory() -> URL {
		let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
		return paths[0]
	}


}

