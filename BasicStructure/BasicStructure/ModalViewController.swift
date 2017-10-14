//
//  ModalViewController.swift
//  BasicStructure
//
//  Created by Stanley Rosenbaum on 10/13/17.
//  Copyright © 2017 Rosenbaum. All rights reserved.
//

import Foundation
import UIKit

class ModalViewController: UIViewController{
	
	// MARK: IBActions
	
	@IBAction func dismissHelp(_ sender: Any) {
		dismiss(animated: true, completion: nil)
		
	}
	
	// MARK: OVERRIDES
	
	override func viewDidLoad() {
		super.viewDidLoad()
	}
	
}
