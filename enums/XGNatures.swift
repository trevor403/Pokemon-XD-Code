//
//  Nature.swift
//  Mausoleum Tool
//
//  Created by StarsMmd on 11/01/2015.
//  Copyright (c) 2015 Steezy. All rights reserved.
//

import Foundation

enum XGNatures : Int, Codable, CaseIterable {
	
	case hardy		= 0x00
	case lonely		= 0x01
	case brave		= 0x02
	case adamant	= 0x03
	case naughty	= 0x04
	
	case bold		= 0x05
	case docile		= 0x06
	case relaxed	= 0x07
	case impish		= 0x08
	case lax		= 0x09
	
	case timid		= 0x0A
	case hasty		= 0x0B
	case serious	= 0x0C
	case jolly		= 0x0D
	case naive		= 0x0E
	
	case modest		= 0x0F
	case mild		= 0x10
	case quiet		= 0x11
	case bashful	= 0x12
	case rash		= 0x13
	
	case calm		= 0x14
	case gentle		= 0x15
	case sassy		= 0x16
	case careful	= 0x17
	case quirky		= 0x18
	
	case random     = 0xFF
	
	var string : String {
		get {
			switch self {
				case .hardy		: return "Hardy"
				case .lonely	: return "Lonely"
				case .brave		: return "Brave"
				case .adamant	: return "Adamant"
				case .naughty	: return "Naughty"
				case .bold		: return "Bold"
				case .docile	: return "Docile"
				case .relaxed	: return "Relaxed"
				case .impish	: return "Impish"
				case .lax		: return "Lax"
				case .timid		: return "Timid"
				case .hasty		: return "Hasty"
				case .serious	: return "Serious"
				case .jolly		: return "Jolly"
				case .naive		: return "Naive"
				case .modest	: return "Modest"
				case .mild		: return "Mild"
				case .quiet		: return "Quiet"
				case .bashful	: return "Bashful"
				case .rash		: return "Rash"
				case .calm		: return "Calm"
				case .gentle	: return "Gentle"
				case .sassy		: return "Sassy"
				case .careful	: return "Careful"
				case .quirky	: return "Quirky"
				case .random	: return "Random"
			}
		}
	}
	
	func cycle() -> XGNatures {
		
		return XGNatures(rawValue: self.rawValue + 1) ?? XGNatures(rawValue: 0)!
		
	}
	
	static func allNatures() -> [XGNatures] {
		var n = [XGNatures]()
		for i in 0 ... 24 {
			n.append(XGNatures(rawValue: i)!)
		}
		return n
	}
}

extension XGNatures: XGEnumerable {
	var enumerableName: String {
		return string
	}
	
	var enumerableValue: String? {
		return self == .random ? rawValue.hexString() : rawValue.string
	}
	
	static var enumerableClassName: String {
		return "Natures"
	}
	
	static var allValues: [XGNatures] {
		var values = allCases
		if game != .Colosseum {
			values.removeLast()
		}
		return values
	}
}





