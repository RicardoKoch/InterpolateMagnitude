//
//  OutputFile.swift
//  interpolate
//
//  Created by Ricardo Koch on 7/20/16.
//  Copyright © 2016 Fabi. All rights reserved.
//

import Foundation

class OutputFile {

	var outputFile = "output.txt"
	private var fileContent: String
	
	init() {
		fileContent = ""
	}
	
	func writeLine(inputLine: InputFileLine, comparingLine: InputFileLine, magnitudes: [Double]) {
		var line = ""
		if let teff = inputLine["Teff"],
			logg = inputLine["logg"],
			logl = inputLine["logL"],
			age = inputLine["age"],
			mass = inputLine["mass"],
			teffV = teff, loggV = logg, ageV = age, massV = mass, loglV = logl {
			line.append("\(teffV.roundTo(digits: 3)) \(loggV.roundTo(digits: 3)) \(loglV.roundTo(digits: 3)) \(ageV.roundTo(digits: 3)) \(massV.roundTo(digits: 3)) ")
		}
		if let feh = comparingLine["fe/h"],
			av = comparingLine["av"],
			rv = comparingLine["Rv"],
			fehV = feh, avV = av, rvV = rv {
			line.append("\(fehV.roundTo(digits: 3)) \(avV.roundTo(digits: 3)) \(rvV.roundTo(digits: 3)) ")
		}
		for mag in magnitudes {
			line.append("\(mag.roundTo(digits: 3)) ")
		}
		line = line.trimmingCharacters(in: CharacterSet.whitespaces)
		
		fileContent.append(line+"\n")
	}
	
	func finish(writeInFile file:String?) {
		if let f = file {
			outputFile = f
		}
		let data = fileContent.data(using: String.Encoding.utf8)
		if !FileManager.default().createFile(atPath: outputFile, contents: data, attributes: nil) {
			print("Failed to save output file to \(outputFile)")
		}
	}

	
}
