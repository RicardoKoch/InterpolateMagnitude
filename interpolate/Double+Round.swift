//
//  Decimal+Round.swift
//  interpolate
//
//  Created by Ricardo Koch on 8/1/16.
//  Copyright © 2016 Fabi. All rights reserved.
//

import Foundation

extension Double {
	
	func roundTo(digits: Int) -> Double {
		let multiplier = pow(10.0, Double(digits))
		return round(self * multiplier) / multiplier
	}
	
}
