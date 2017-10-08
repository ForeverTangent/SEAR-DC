//
//  ViewController.swift
//  BasicStructure
//
//  Created by Stanley Rosenbaum on 10/5/17.
//  Copyright © 2017 Rosenbaum. All rights reserved.
//

import UIKit
import CoreMotion

class MainViewController: UIViewController,
	UIPickerViewDataSource,
	UIPickerViewDelegate {
	

	// MARK: CLASS PROPERTIES
	var stairsPickerDataSource = [["UP", "NA", "DOWN"],["1","2","3","4","5","6","7","8"]];
	
	var stSensorManager : STSensorManagement = STSensorManagement()
	
	let cmMotionManager = CMMotionManager()
	
	var cmMotionManagerTimer : Timer?
	
	
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
	
	
	// MARK: OVERRIDES
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		self.stairsPickerView.dataSource = self
		self.stairsPickerView.delegate = self
		
		self.setupNotifications()
		
//		self.cmMotionManager.startAccelerometerUpdates()
//		self.cmMotionManager.startGyroUpdates()
//		self.cmMotionManager.startMagnetometerUpdates()
//		self.cmMotionManager.startDeviceMotionUpdates()
		
		
		self.startDeviceMotion()
		
//		self.cmMotionManagerTimer = Timer.scheduledTimer(
//			timeInterval: 3.0,
//			target: self,
//			selector: #selector(MainViewController.attitudeTimerUpdate),
//			userInfo: nil,
//			repeats: true
//		)
//		self.cmMotionManagerTimer?.fire()

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
	
	
	
	// MARK: IBOutputs
	
	@IBOutlet weak var ColorImageView: UIImageView!
	@IBOutlet weak var DepthImageView: UIImageView!
	
	@IBOutlet weak var stairsPickerView: UIPickerView!
	
	@IBOutlet weak var messageField: UITextField!
	
	
	// MARK: PROTOCOL FUNCTIONS
	// Picker Protocols
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 2
	}
	
	func pickerView(
		_ pickerView: UIPickerView,
		titleForRow row: Int,
		forComponent component: Int
		) -> String? {
		
		var returnString : String = ""
		
		if( component == 0) {
			returnString = stairsPickerDataSource[0][row]
		}
		
		if( component == 1) {
			returnString =  stairsPickerDataSource[1][row]
		}
	
		return returnString
		
	}
	
	
	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int
	{
		var returnInt : Int = 0
		
		if( component == 0 ){
			returnInt = 3
		}
		
		if( component == 1){
			returnInt = 8
		}
		
		return returnInt
	}
	
	// Catpure the picker view selection
	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		// This method is triggered whenever the user makes a change to the picker selection.
		// The parameter named row and component represents what was selected.
		
		NSLog("Something Selected")
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
		
//		let userInfo = timer.userInfo as! Dictionary<String, AnyObject>
//		let tempAttitude:CMAttitude = ( userInfo["attitude"] as! CMAttitude )
		
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
						
						NSLog( String(format: "%.2f", rollD ) )
						// Use the motion data in your app.
					}
				}
			)
			
			// Add the timer to the current run loop.
			RunLoop.current.add(
				self.cmMotionManagerTimer!,
				forMode: .defaultRunLoopMode
			)
			
//			self.cmMotionManagerTimer?.fire()
		}
	}
			
			
//			self.cmMotionManagerTimer = Timer(
//				fire: Date(),
//				interval: 1.0 / 60,
//				repeats: true,
//				block: {
//					(timer) in
//					if let data = self.cmMotionManager.deviceMotion {
//						// Get the attitude relative to the magnetic north reference frame.
//						let x = data.attitude.pitch
//						_ = data.attitude.roll
//						_ = data.attitude.yaw
//
//						NSLog( String( describing: x) )
//						// Use the motion data in your app.
//					}
//				}
//			)
//
//			// Add the timer to the current run loop.
//			RunLoop.current.add(
//				self.cmMotionManagerTimer!,
//				forMode: .defaultRunLoopMode
//			)
//		}
//	}

}

