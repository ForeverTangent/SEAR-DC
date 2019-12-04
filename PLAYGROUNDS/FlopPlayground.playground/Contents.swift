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




/**
Flops the depth array
- Parameter depthArray: A [Float] to Flop
- Returns: [Float], A Float Array
*/
func flop( depthArray: [Float] ) -> [Float] {
	var returnArray : [Float] = [Float]()
	
	var theDepthArray = depthArray
	
	while( theDepthArray.count != 0 ){
		let oneRow : [Float] = Array(theDepthArray[0..<6])
		theDepthArray = Array(theDepthArray[6...])
		
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
var testRev = flop(depthArray: test)
print( testRev )
test[0]

test = Array(test[1...])

