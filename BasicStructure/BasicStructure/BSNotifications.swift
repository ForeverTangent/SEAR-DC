//
//  BSNotifications.swift
//  BasicStructure
//
//  Created by Stanley Rosenbaum on 10/7/17.
//  Copyright © 2017 Rosenbaum. All rights reserved.
//

import Foundation

class BSNotifications {
	
	static func post( message : String ) {
		
		let notificaitonMessage : [ String : String ] = [ "MESSAGE" : message ]
		
		NSLog( message )
		
		NotificationCenter.default.post(
			name: NSNotification.Name(rawValue: "MESSAGE"),
			object: self,
			userInfo: notificaitonMessage
		)
		
	}
	
	
	static func postDisplaySensor( image : UIImage ) {
		
		let notificaitonMessage : [ String : UIImage ] = [ "DEPTH_IMAGE" : image ]
		
		NotificationCenter.default.post(
			name: NSNotification.Name(rawValue: "SENSOR_IMAGE"),
			object: self,
			userInfo: notificaitonMessage
		)
		
	}
	
	
	static func postDisplayCamera( image : UIImage ) {
		
		let notificaitonMessage : [ String : UIImage ] = [ "COLOR_IMAGE" : image ]
		
		NotificationCenter.default.post(
			name: NSNotification.Name(rawValue: "CAMERA_IMAGE"),
			object: self,
			userInfo: notificaitonMessage
		)
		
	}
	
	
}

