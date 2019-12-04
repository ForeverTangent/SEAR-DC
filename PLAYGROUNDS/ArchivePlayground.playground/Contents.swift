//: Playground - noun: a place where people can play

import UIKit
import Foundation

var str = "Hello, playground"


//https://stackoverflow.com/questions/27331576/saving-arrays-in-swift#27332429
//https://www.hackingwithswift.com/example-code/system/how-to-save-and-load-objects-with-nskeyedarchiver-and-nskeyedunarchiver


let iArray : [Float] = [1.1,2.2,3.3,4.4,5.5,6.6,7.7,8.8,9.9,0.10]

let dir = FileManager.default.urls(
	for: FileManager.SearchPathDirectory.documentDirectory,
	in: FileManager.SearchPathDomainMask.userDomainMask).first!

let fileURL =  dir.appendingPathComponent("DEPTH_DATA+ANGLE.csv")

var csvText = ""

csvText = csvText + "\(Int(NSDate().timeIntervalSince1970)),"

for element in iArray {
	csvText.append("\(element),")
}

csvText.append("HONK")

csvText.append("\n")

let data = csvText.data(using: .utf8, allowLossyConversion: false)!

if FileManager.default.fileExists(atPath: fileURL.path) {
	if let fileHandle = try? FileHandle(forUpdating: fileURL) {
		fileHandle.seekToEndOfFile()
		fileHandle.write(data)
		fileHandle.closeFile()
	}
} else {
	try! data.write(to: fileURL, options: Data.WritingOptions.atomic)
}

