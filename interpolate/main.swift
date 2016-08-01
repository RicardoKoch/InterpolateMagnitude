//
//  main.swift
//  interpolate
//
//  Created by Ricardo Koch on 7/14/16.
//  Copyright © 2016 Fabi. All rights reserved.
//

import Foundation

let lambdaStartColumn = 5
let mBol:Double = 4.74

typealias InputFileType = [InputFileLine]
typealias InputFileLine = [String: Double?]

enum FindNextDirection {
	case lower
	case higher
}

let fileAHeaders = ["Teff", "logg", "fe/h", "av", "Rv", "ACS_WFC_F435W", "ACS_WFC_F475W", "ACS_WFC_F502N", "ACS_WFC_F550M", "ACS_WFC_F555W", "ACS_WFC_F606W", "ACS_WFC_F625W", "ACS_WFC_F658N", "ACS_WFC_F660N", "ACS_WFC_F775W",   "ACS_WFC_F814W", "ACS_WFC_F850LP", "ACS_WFC_F892N"]
let fileBHeaders = ["Teff", "logg", "logL", "age", "mass"]

let output = OutputFile()

func run(filename1: String, filename2: String, outputName: String?) {

	//read file A, get values
	let fileA = readFileContent(filename: filename1, headers: fileAHeaders)

	//read file B, get values
	let fileB = readFileContent(filename: filename2, headers: fileBHeaders)
	
	if fileA.count == 0 || fileB.count == 0 {
		print("Failed to load input files, check path")
		return
	}
	var totalPoints = 0
	//get line from input file B
	for lineB in fileB {
	
		//look for the four points in line from file A comparing Teff and logg columns from B
		let lowerPoints = findPoints(direction: .lower, lineB: lineB, fileA: fileA)
		let higherPoints = findPoints(direction: .higher, lineB: lineB, fileA: fileA)
		
//		NSLog("Line:   \(lineB["Teff"]!) - \(lineB["logg"]!)", "")
//		let fourPoints = lowerPoints + higherPoints
//		for point in fourPoints {
//			NSLog("Found Point:  \(point["Teff"]!) - \(point["logg"]!)", "")
//		}
	
		//use four points to interpolate
		if lowerPoints.count >= 2 && higherPoints.count >= 2 {
			interpolateLambdas(pointX: lineB, pointA: lowerPoints[1], pointB: higherPoints[1], pointC: lowerPoints[0], pointD: higherPoints[0])
		}
		totalPoints += lowerPoints.count + higherPoints.count
	}
	
	output.finish(writeInFile: outputName)
	print("Interpolation did finish running (calculating \(totalPoints) points)")
}

private func readFileContent(filename: String, headers:[String]) -> InputFileType {
	
	var content = InputFileType()
	
	if let aStreamReader = StreamReader(path: "\(FileManager.default().currentDirectoryPath)/\(filename)") {
		defer {
			aStreamReader.close()
		}
		var index = 0
		while let line = aStreamReader.nextLine() {
			//print("\(filename)-\(index): \(line)\n")
			
			var lineDict = InputFileLine()
			let columns = line.components(separatedBy: " ")
			var i = 0
			for column:String in columns where column.characters.count > 0 {
				if let dec = Double(column) {
					lineDict[headers[i]] = dec
				} else {
					print("\(filename)- unable to parse value \(column). Check your input data.")
				}
				i += 1
			}
			index += 1
			content.append(lineDict)
		}
	}
	return content
}

private func findPoints(direction:FindNextDirection, lineB:InputFileLine, fileA:InputFileType) -> InputFileType {

	let currentNexts = findNextValuesInDict(direction: direction, lineB: lineB, fileA: fileA, property: "Teff")
	
	let lowerLogg = findNextValuesInDict(direction: .lower, lineB: lineB, fileA: currentNexts, property: "logg")
	let higherLogg = findNextValuesInDict(direction: .higher, lineB: lineB, fileA: currentNexts, property: "logg")

	return lowerLogg + higherLogg
}

private func findNextValuesInDict(direction: FindNextDirection, lineB: InputFileLine, fileA: InputFileType, property: String) -> InputFileType  {

	var currentNexts = [InputFileLine]()
	var lastValue:Double = Double(Int.min)
	//find next effTempIndex.
	for i in stride(from: (direction == .higher ? 0 : fileA.count-1),
	                through: (direction == .higher ? fileA.count-1 : 0),
	                by: (direction == .higher ? 1 : -1)) {
		let lineA = fileA[i]
		if direction == .higher {
			if let value_A = lineA[property], value_B = lineB[property] {
				if value_A >= value_B {
					if lastValue != Double(Int.min) && lastValue != value_A {
						break
					}
					currentNexts.append(lineA)
					lastValue = value_A ?? 0
				}
			}
		} else {
			// .lower
			if let value_A = lineA[property], value_B = lineB[property] {
				if value_A <= value_B {
					if lastValue != Double(Int.min) && lastValue != value_A {
						break
					}
					currentNexts.append(lineA)
					lastValue = value_A ?? 0
				}
			}
		}
	}
	if direction == .lower {
		currentNexts.reverse()
	}
	return currentNexts
}

/*
Get each lambda contained in the point group and interpolate
*/
func interpolateLambdas(pointX x: InputFileLine, pointA a: InputFileLine, pointB b: InputFileLine, pointC c: InputFileLine, pointD d: InputFileLine) {

	let pointX: LambdaPoint
	if let teff = x["Teff"], logg = x["logg"], teffV = teff, loggV = logg {
		pointX = LambdaPoint(lambda: nil, x: teffV, y: loggV)
	} else {
		print("Warning: unable to create alpha point with input")
		return
	}
	
	var magnitudes = [Double]()
	
	//read all lambda values
	for i in stride(from: lambdaStartColumn, to: fileAHeaders.count, by: 1) {
	
		let lambdaHeader = fileAHeaders[i]
		
		if let pointA = convertDictToPoint(dict: a, lambdaHeader: lambdaHeader), pointB = convertDictToPoint(dict: b, lambdaHeader: lambdaHeader), pointC = convertDictToPoint(dict: c, lambdaHeader: lambdaHeader), pointD = convertDictToPoint(dict: d, lambdaHeader: lambdaHeader) {
		
			let lambdaX = interpolateLampda(pointX: pointX, pointA: pointA, pointB: pointB, pointC: pointC, pointD: pointD)
			//NSLog("Interpolation lambda \(lambdaHeader) with results: \(lambdaX)", "")
			
			//calculate magnitude
			if let lambdaX = lambdaX, logL = x["logL"], logLVal = logL {
				let magnitude = magnitudeLambda(lambdaX: lambdaX, logL: logLVal)
				if magnitude.isNaN {
					print("Magniture is NaN for lambda:\(lambdaX), logL:\(logLVal)")
				} else {
					magnitudes.append(magnitude)
				}
			}
		}
	}
	
	//append magnitudes to output file
	output.writeLine(inputLine: x, comparingLine: a, magnitudes: magnitudes)
}

func interpolateLampda(pointX x: LambdaPoint, pointA a: LambdaPoint, pointB b: LambdaPoint, pointC c: LambdaPoint, pointD d: LambdaPoint) -> Double? {
	
	if let z0 = a.lambda, z1 = b.lambda, z2 = c.lambda, z3 = d.lambda {
		let demon = (d.x-c.x)*(a.y-c.y)
		let Na = ((x.x-c.x)*(a.y-x.y)) / demon
		let Nb = ((d.x-x.x)*(a.y-x.y)) / demon
		let Nc = ((x.x-c.x)*(x.y-c.y)) / demon
		let Nd = ((d.x-x.x)*(x.y-c.y)) / demon
		let z = z0 * Nd + z1 * Nc + z2 * Nb + z3 * Na
		return z
	}
	else {
		print("Warning: informed points did not have a valid lambda value. Unable to interpolate.")
	}
	return nil
}

func magnitudeLambda(lambdaX: Double, logL: Double) -> Double {
	return mBol - 2.5 * logL - lambdaX
}

if Process.arguments.count < 2 {
	print("Error! must use the program like this-> interpolate filename1.txt filename2.txt output.txt")
	exit(1)
}

run(filename1: Process.arguments[1], filename2: Process.arguments[2], outputName: Process.arguments[3])

