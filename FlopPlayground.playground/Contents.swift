//: Playground - noun: a place where people can play

import UIKit

var str = "Hello, playground"
//: Playground - noun: a place where people can play


let totalNumOfPixels : Int = 640 * 480
print(totalNumOfPixels)

func buildTestArray() -> [Float] {
	
	var returnArray : [Float] = [Float]()
	var colArray : [Float] = [Float]()
	
	for row in 0..<4 {
		for col in 0..<6 {
			colArray.append( Float( col + (6 * row) ))
		}
		
		let colArrayRev = Array( colArray.reversed())
		
		for element in colArrayRev {
			returnArray.append(element)
		}
		
		colArray.removeAll()
		
	}
	
	return returnArray
	
}





func flop( theArray: inout [Float] ) -> [Float] {
	var returnArray : [Float] = [Float]()
	
	while( theArray.count != 0 ){
		let oneRow : [Float] = Array(theArray[0..<6])
		theArray = Array(theArray[6...])
		
		print( theArray.count)
		
		var oneRowRev = Array( oneRow.reversed() )
		
		for element in oneRowRev {
			returnArray.append(element)
		}
		
		oneRowRev.removeAll()
		
	}
	return returnArray
	
}

var test = buildTestArray()
print( test )
var testRev = flop(theArray: &test)
print( testRev )

