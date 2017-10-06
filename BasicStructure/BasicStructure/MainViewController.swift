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
	
	

	

	

	// MARK: IBOutputs
	
	@IBOutlet weak var ColorImageView: UIImageView!
	@IBOutlet weak var DepthImageView: UIImageView!
	
	@IBOutlet weak var stairsPickerView: UIPickerView!
	
	
	// MARK: Variables
	var stairsPickerDataSource = [["UP", "NA", "DOWN"],["1","2","3","4","5","6","7","8"]];
	
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		
		self.stairsPickerView.dataSource = self
		self.stairsPickerView.delegate = self
		
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	// MARK: Picker Protocol Functions
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
	
	
	func pickerView(
		_ pickerView: UIPickerView,
		numberOfRowsInComponent component: Int
		) -> Int
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
		
		NSLog("SOmething Selected")
	}
	
	
	
	

}

