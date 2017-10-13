//
//  STSensorManagement.swift
//  BasicStructure
//
//  Created by Stanley Rosenbaum on 10/5/17.
//  Copyright © 2017 Rosenbaum. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit




/**
Think of this as the core 'model' for dealing with the Structure Sensor.
*/
class STSensorManagement :
	NSObject,
	STSensorControllerDelegate,
	AVCaptureVideoDataOutputSampleBufferDelegate
	{

	
	var stSensorController : STSensorController = STSensorController.shared()
	
	// MARK: Class Properties
	
	// Set these f you want to use Wireless debugging.
	let netcatIP : String  = "1.1.1.1" //
	let netcatPort : Int32 = 4999
	
	let depthFrameQueue : DispatchQueue = DispatchQueue(
		label: "BasicStructure.depthFrameQueue",
		qos: .userInteractive
	)
	
	let colorFrameQueue : DispatchQueue = DispatchQueue(
		label: "BasicStructure.colorFrameQueue",
		qos: .userInteractive
	)
	
	// Camera Parameters and '*2' because we are working in 640x480.
	let focaleDistanceWidth : Float = 305.73 * 2;
	let focaleDistanceHeight : Float = 305.62 * 2;
	let opticalCenterX : Float = 159.69 * 2;
	let opticalCenterY : Float = 119.86 * 2;
	
	let bitsPerComponent: Int = 8
	let bitsPerPixel: Int = 32 // 8*4
	let bytesPerRow: Int = 2560 // width * 4

	var toRGBA : STDepthToRgba?
	var avVideoCaptureSession : AVCaptureSession?
	var avVideoCaptureDevice : AVCaptureDevice?
	
	var renderAndDisplayDepthAndColorImages : Bool = true
	
	var currentDepthFrame : STDepthFrame?
	var currentColorFrame : STColorFrame?
	
	var displayImagesDelegate : DisplayImages?
	
	
	// MARK: Inits
	
	override init() {
		super.init()
		
		STSensorController.shared().delegate = self
		
	}
	


	// MARK: STSensorControllerDelegate Protocol Functions
	
	/**
	Did the Sensor Connect?
	Required
	*/
	func sensorDidConnect() {
		BSNotifications.post(message: "sensorDidConnect()")
		
		if self.connectAndStartSTSStreaming() {
			NSLog( "STSensor Streaming" )
		} else {
			NSLog( "STSensor Connected" )
		}
	}
	
	/**
	Did the sensor disconnect
	Required
	*/
	func sensorDidDisconnect() {
		BSNotifications.post(message: "sensorDidDisconnect()")
		self.stopColorCamera()
		BSNotifications.post(message: "STS Sensor Disconnected.")

	}
	
	/**
	Required
	*/
	func sensorDidStopStreaming(_ reason: STSensorControllerDidStopStreamingReason) {
		BSNotifications.post(message: "sensorDidStopStreaming()")
		self.stopColorCamera()
		BSNotifications.post(message: "STS Sensor Stopped Streaming.")

	}
	
	/**
	Required
	*/
	func sensorDidLeaveLowPowerMode() {
		BSNotifications.post(message: "sensorDidLeaveLowPowerMode()")
	}
	
	/**
	Required
	*/
	func sensorBatteryNeedsCharging() {
		BSNotifications.post(message: "Structurem Sensor needs charging!")


	}
	
	/**
	What to do when the Structure outputs a frame.
	Occipital Says this is optional but Required for us.
	- Parameters:
	- depthFrame : STDepthFrame
	*/
	func sensorDidOutputDepthFrame( _ depthFrame: STDepthFrame! ) {
		if( self.renderAndDisplayDepthAndColorImages ) {
		
			// Not everyone has to copy the depth frame before doing anything with it.
			// But for my projects I had to, because of timing issues.
			// The frame would cease to exist before I was done with it.
			// I am leaving this here in case people wanted to see.
			self.currentDepthFrame = depthFrame.copy() as? STDepthFrame

		}
		
	}
	
	
	/**
	What to do when the Structure outputs a frame.
	Occipital Says this is optional but Required for us.
	- Parameters:
	- depthFrame : STDepthFrame
	- colorFrame : STColorFrame
	*/
	func sensorDidOutputSynchronizedDepthFrame(
		_ depthFrame: STDepthFrame,
		colorFrame: STColorFrame
		) {
		
		// Not everyone has to copy the depth/color frame before doing anything with it.
		// But for my projects I had to, because of timing issues.
		// The frame would cease to exist before I was done with it
		// I am leaving this here in case people wanted to see.
		let currentDepthFrame = depthFrame.copy() as? STDepthFrame
		let currentColorFrame = colorFrame.copy() as? STColorFrame

		let depthFrameOutput = self.process(theDepthFrame: currentDepthFrame!)
		let colorFrameOutput = self.process(theColorFrame: currentColorFrame!)
		
		self.displayImagesDelegate?.displayDepth( image: depthFrameOutput.image )
		self.displayImagesDelegate?.storeDistance( array: depthFrameOutput.distanceArray )
		self.displayImagesDelegate?.displayColor( image: colorFrameOutput )
		
	}
	
	
	// MARK: AVCaptureVideoDataOutputSampleBufferDelegate Protocol Functions
	//
	func captureOutput(
		_ captureOutput: AVCaptureOutput,
		didOutput sampleBuffer: CMSampleBuffer,
		from connection: AVCaptureConnection
		) {
		
		STSensorController.shared().frameSyncNewColorBuffer( sampleBuffer )
		
	}
	
	
	/**
	Activate the Sensor
	*/
	func activateSTSensor() {
		self.tryReconnect()
	}
	
	
	/**
	Check if SEAR-RL is Authorized to use onboard iDevice Camera
	
	http://stackoverflow.com/questions/39894630/how-to-get-front-camera-back-camera-and-audio-with-avcapturedevicediscoverysess
	
	- Returns: Bool
	*/
	func checkColorCameraAuthorized() -> Bool {
		
		let neededDevices : [AVCaptureDevice.DeviceType] = [AVCaptureDevice.DeviceType.builtInWideAngleCamera]
		
		let _ = AVCaptureDevice.DiscoverySession.init(
			deviceTypes: neededDevices,
			mediaType: AVMediaType.video,
			position: AVCaptureDevice.Position.back
		)
		
		let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
		if status != AVAuthorizationStatus.authorized {
			AVCaptureDevice.requestAccess(for: AVMediaType.video) {
				(granted: Bool) in
				if granted {
					DispatchQueue.main.async {
						NSLog( "iDevice Color Camera Authorization Granted" )
					}
				}
			}
		}
		
		return true
		
	}
	
	
	/**
	Setup onboard iDevice Color Camera
	- Throws: Device unavailable error.
	*/
	func setupColorCamera() {
		
		// Check if we are runnign in simulator or not.
		if UIImagePickerController.isSourceTypeAvailable(.camera) {
			
			if self.avVideoCaptureSession != nil {
				return
			}
			
			if !self.checkColorCameraAuthorized() {
				NSLog("Camera access not granted" )
				return
			}
			
			self.avVideoCaptureSession = AVCaptureSession()
			self.avVideoCaptureSession!.beginConfiguration()
			self.avVideoCaptureSession!.sessionPreset = AVCaptureSession.Preset.vga640x480
			
			self.avVideoCaptureDevice = AVCaptureDevice.default(for: AVMediaType.video)
			assert( avVideoCaptureDevice != nil )
			
			if let device = avVideoCaptureDevice {
				do {
					try device.lockForConfiguration()
				}
				catch let error as NSError {
					
					NSLog( error.localizedDescription )
					
					return
				}
				
				if device.isExposureModeSupported( AVCaptureDevice.ExposureMode.continuousAutoExposure ) {
					device.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure;
				}
				
				if device.isWhiteBalanceModeSupported( AVCaptureDevice.WhiteBalanceMode.continuousAutoWhiteBalance ) {
					device.whiteBalanceMode = AVCaptureDevice.WhiteBalanceMode.continuousAutoWhiteBalance
				}
				
				device.setFocusModeLocked( lensPosition: 1.0, completionHandler: nil )
				device.unlockForConfiguration()
				
				do {
					let input = try AVCaptureDeviceInput( device: device )
					self.avVideoCaptureSession!.addInput( input )
					let output = AVCaptureVideoDataOutput()
					output.alwaysDiscardsLateVideoFrames = true
					
					// Weird Color Space Thing
					output.videoSettings = [
						kCVPixelBufferPixelFormatTypeKey as AnyHashable as! String: Int( kCVPixelFormatType_420YpCbCr8BiPlanarFullRange )
					]
					
					output.setSampleBufferDelegate(self, queue: DispatchQueue.main )
					self.avVideoCaptureSession!.addOutput( output )
				}
				catch let error as NSError {
					NSLog( error.localizedDescription )
					return
				}
				
				do {
					try device.lockForConfiguration()
				}
				catch let error as NSError {
					NSLog( error.localizedDescription )
				}
				device.activeVideoMaxFrameDuration = CMTimeMake( 1, 30 )
				device.activeVideoMinFrameDuration = CMTimeMake( 1, 30 )
				device.unlockForConfiguration()
			}
			
			self.avVideoCaptureSession?.commitConfiguration()
			NSLog( "Camera Configured" )
		}
	}
	
	
	/**
	Start onboard iDevice Camera Streaming
	*/
	func startColorCamera() {
		self.setupColorCamera()
		
		if let session = avVideoCaptureSession {
			session.startRunning()
			NSLog( "Camera Started")
		}
	}
	
	
	/**
	Stop onboard iDevice Camera Streaming
	*/
	func stopColorCamera() {
		if let session = avVideoCaptureSession {
			session.stopRunning()
		}
		avVideoCaptureSession = nil
	}
	
	
	/**
	Init Structure Sensor
	*/
	func initializeSTSensor() -> Bool {
		let result = STSensorController.shared().initializeSensorConnection()
		if result == .alreadyInitialized || result == .success {
			return true
		}
		return false
	}
	
	
	/**
	Start Structure Sensor Streaming.
	*/
	func connectAndStartSTSStreaming() -> Bool {
		if self.initializeSTSensor() {
			let options : [NSObject : AnyObject] = [
				kSTStreamConfigKey as NSObject: NSNumber(value: STStreamConfig.depth640x480.rawValue),
				kSTFrameSyncConfigKey as NSObject: NSNumber(value: STFrameSyncConfig.depthAndRgb.rawValue),
				kSTHoleFilterEnabledKey as NSObject: true as AnyObject,
				kSTColorCameraFixedLensPositionKey as NSObject: 1.0 as AnyObject
			]
			do {
				try STSensorController.shared().startStreaming(options: options as [NSObject : AnyObject])
				let toRGBAOptions : [NSObject : AnyObject] = [
					kSTDepthToRgbaStrategyKey as NSObject : NSNumber(value: STDepthToRgbaStrategy.gray.rawValue)
				]
				self.toRGBA = STDepthToRgba(options: toRGBAOptions)
				self.startColorCamera()
				return true
			} catch let error as NSError {
				NSLog( error.localizedDescription )
			}
		}
		return false
	}
	
	
	/**
	*/
	func stopSensorAndCameraStreaming() {
		
		STSensorController.shared().stopStreaming()
		self.stopColorCamera()
		
	}
	
	
	/**
	Attempt Reconnect
	*/
	func tryReconnect() {
		if ( STSensorController.shared().isConnected() != false ) {
			self.sensorDidConnect()
		} else {
			self.sensorDidDisconnect()
		}
	}
	

	
	// MARK: Frame Processing
	
	/**
	Process the depth frame
	- Parameter theDepthFrame: STDepthFrame, the current depth frame
	- Returns: A Tuple of ( the depth UIImage, [Float] the depth array )
	*/
	func process( theDepthFrame: STDepthFrame ) -> ( image: UIImage, distanceArray: [Float] ) {
		let newDepthImage : UIImage = self.renderImageFromDepthFrame( theDepthFrame )
		let newDistanceArray : [Float] = self.createDistanceArrayFrom( depthFrame: theDepthFrame )
		
		return ( newDepthImage, newDistanceArray )
		
	}
	
	
	/**
	Processes the Color Frame.
	- Parameter theColorFrame: STColorFrame
	- Returns: The Color UIImage
	*/
	func process( theColorFrame : STColorFrame ) -> UIImage {
		let newColorImage : UIImage = self.renderImageFromColorFrame( sampleBuffer: theColorFrame.sampleBuffer )
		
		return newColorImage
		
	}
	
	
	/**
	Helper Function to convert Structure's DepthFrames.depthInMillimeters into a something we can use in Swift.
	Because otherwise it is an Obj-C *Float to a [Float]
	- Returns: [Float] of the pixel distances in millimeters.  Arranged Width * hieght starting from the top left.
	*/
	func createDistanceArrayFrom( depthFrame : STDepthFrame ) -> [Float] {
		let pointer : UnsafeMutablePointer<Float> = depthFrame.depthInMillimeters
		
		let theCount : Int32 = depthFrame.width * depthFrame.height
		
		let returnArray : [Float] = Array(
			UnsafeBufferPointer(
				start: pointer,
				count: Int( theCount )
			)
		)
		
		return returnArray
		
	}
	
	
	// MARK: Member Functions
	/**
	Top function for turning the Depth data into an image.
	
	- Parameter depthFrame: The STDepthFrame output from the sensor
	- Returns: UIImage
	*/
	func renderImageFromDepthFrame( _ depthFrame: STDepthFrame ) -> UIImage {
		
		var returnImage : UIImage?
		
		if let renderer = self.toRGBA {
			let pixels = renderer.convertDepthFrame( toRgba: depthFrame )
			
			// What to use for the system
			returnImage = renderImageFromDepthPixels(
				pixels!,
				width: Int( renderer.width ),
				height: Int( renderer.height )
				)!
		}
		
		return returnImage!
	}
	
	/**
	*/
	func renderImageFromDepthFrame() -> UIImage {
		
		var returnImage : UIImage?
		
		if let renderer = self.toRGBA {
			let pixels = renderer.convertDepthFrame( toRgba: self.currentDepthFrame )
			
			// What to use for the system
			returnImage = renderImageFromDepthPixels(
				pixels!,
				width: Int( renderer.width ),
				height: Int( renderer.height )
				)!
		}
		
		return returnImage!
	}
	
	
	/**
	Turn the Color Camera Buffer into an Image
	- Parameter sampleBuffer: CMSampleBuffer, a Sample Buffer from Color Camera
	- Returns: UIImage
	*/
	func renderImageFromColorFrame( sampleBuffer: CMSampleBuffer ) -> UIImage {
		
		var returnImage : UIImage?
		
		if let cvPixels = CMSampleBufferGetImageBuffer( sampleBuffer ) {
			let coreImage = CIImage( cvPixelBuffer: cvPixels )
			let context = CIContext()
			let rect = CGRect(
				x: 0,
				y: 0,
				width: CGFloat( CVPixelBufferGetWidth(cvPixels) ),
				height: CGFloat( CVPixelBufferGetHeight(cvPixels) )
			)
			let cgImage = context.createCGImage( coreImage, from: rect )
			
			returnImage = UIImage( cgImage: cgImage! )
			
		}
		
		return returnImage!
		
	}
	
	
	/**
	Turn the Color Camera Buffer into an Image
	- Returns: UIImage
	*/
	func renderImageFromColorFrame() -> UIImage {
		
		var returnImage : UIImage?
		
		if let cvPixels = CMSampleBufferGetImageBuffer( (self.currentColorFrame?.sampleBuffer)! ) {
			let coreImage = CIImage( cvPixelBuffer: cvPixels )
			let context = CIContext()
			let rect = CGRect(
				x: 0,
				y: 0,
				width: CGFloat( CVPixelBufferGetWidth(cvPixels) ),
				height: CGFloat( CVPixelBufferGetHeight(cvPixels) )
			)
			let cgImage = context.createCGImage( coreImage, from: rect )
			
			returnImage = UIImage( cgImage: cgImage! )
			
		}
		
		return returnImage!
		
	}
	
	
	/**
	Sub function to help turn the depth Data into an image.
	- Parameters:
	- pixels: The buffer of pixels
	- width: width of the image
	- height: height of the image
	- Returns: A UIImage of the depth data.
	*/
	func renderImageFromDepthPixels(
		_ pixels : UnsafeMutablePointer<UInt8>,
		width: Int,
		height: Int
		) -> UIImage? {
		
		let colorSpace = CGColorSpaceCreateDeviceRGB()
		let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(
			CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
		)
		
		let provider = CGDataProvider(
			data: Data( bytes: UnsafePointer<UInt8>(pixels), count: width * height * 4 ) as CFData
		)
		
		let image = CGImage(
			width: width,
			height: height,
			bitsPerComponent: 8,
			bitsPerPixel: 8 * 4,
			bytesPerRow: width * 4,
			space: colorSpace,
			bitmapInfo: bitmapInfo,
			provider: provider!,
			decode: nil,
			shouldInterpolate: false,
			intent: CGColorRenderingIntent.defaultIntent
		)
		
		return UIImage( cgImage: image! )
	}
	
	
	
	
	
	
	// MARK: STSWirelessConnection
	
	/**
	Set up STSWirelss Connection
	
	Messages sent to the stdout and stderr (such as NSLog, std::cout, std::cerr, printf) will be sent to the given IPv4 address on the specified port.
	
	In order to receive these messages on a remote machine, you can, for instance, use the netcat command-line utility
	(available by default on Mac OS X). Simply run in a terminal: nc -lk <port>
	
	Be sure to set self.netcatIP to the IP of the computer running nc
	We are using port 4999
	
	*/
	func setSTSWirelessCommuncation() {
		
		print("Setting Up Wireless Communication.")
		
		var error : NSError? = nil
		let remoteHost : String = self.netcatIP
		let remotePort : Int32 = self.netcatPort
		
		print( "Setting STWireless @: " + remoteHost + ":" + String( describing: remotePort ) )
		
		STWirelessLog.broadcastLogsToWirelessConsole(
			atAddress: remoteHost,
			usingPort: remotePort,
			error: &error
		)
		
		print("Setting Up Wireless Communication should be set up.")
		
		NSLog( "WIRELESS SET UP")
		
	}
	
}
