//
//  ViewController.swift
//  BasicStructure
//
//  Created by Stanley Rosenbaum on 10/5/17.
//  Copyright © 2017 Rosenbaum. All rights reserved.
//

import UIKit

class MainViewController: UIViewController,
	UIPickerViewDataSource,
	UIPickerViewDelegate {
	

	// MARK: CLASS PROPERTIES
	var stairsPickerDataSource = [["UP", "NA", "DOWN"],["1","2","3","4","5","6","7","8"]];
	
	var stSensorManager : STSensorManagement = STSensorManagement()
	
	
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
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	
	override func viewWillDisappear(_ animated: Bool) {
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
	
}

