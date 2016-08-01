//
//  Point.swift
//  interpolate
//
//  Created by Ricardo Koch on 7/20/16.
//  Copyright © 2016 Fabi. All rights reserved.
//

import Foundation

struct LambdaPoint {
	
	var lambda: Double?
	var x: Double
	var y: Double
	
}

func convertDictToPoint(dict: InputFileLine, lambdaHeader: String) -> LambdaPoint? {
	if let teff = dict["Teff"], logg = dict["logg"], lambda = dict[lambdaHeader], teffV = teff, loggV = logg {
		return LambdaPoint(lambda: lambda, x: teffV, y: loggV)
	} else {
		return nil
	}
}
