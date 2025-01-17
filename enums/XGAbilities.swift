//
//  XGAbilities.swift
//  XG Tool
//
//  Created by StarsMmd on 01/06/2015.
//  Copyright (c) 2015 StarsMmd. All rights reserved.
//

import Foundation

let kFirstAbilityNameID = 0xC1D
let kFirstAbilityDescriptionID = 0xCE5

let abilityListUpdated = game == .Colosseum ? false : XGFiles.dol.data!.getWordAtOffset(kAbilitiesStartOffset + 8) != 0

let kNumberOfAbilities		= abilityListUpdated ? (0x3A8 / 8) : 0x4E
let kAbilityNameIDOffset		= abilityListUpdated ? 0 : 4
let kAbilityDescriptionIDOffset = abilityListUpdated ? 4 : 8
let kSizeOfAbilityEntry			= abilityListUpdated ? 8 : 12

let kAbilitiesStartOffset = game == .XD ? 0x3FCC50 : (region == .JP ? 0x348D20 : 0x35C5E0)

enum XGAbilities {
	
	case ability(Int)
	
	var index : Int {
		get {
			switch self {
				case .ability(let i):
					if i > kNumberOfAbilities || i < 0 {
						return 0
					}
					return i
			}
		}
	}
	
	var hex : String {
		get {
			return String(format: "0x%x",self.index)
		}
	}
	
	var nameIDOffset : Int {
		let safeIndex = index < kNumberOfItems ? index : 0
		return kAbilitiesStartOffset + (safeIndex * kSizeOfAbilityEntry) + kAbilityNameIDOffset
	}
	
	var nameID : Int {
		get {
			let dol = XGFiles.dol.data!
			return Int(dol.getWordAtOffset(nameIDOffset))
		}
	}
	
	var name : XGString {
		get {
			return XGFiles.common_rel.stringTable.stringSafelyWithID(nameID)
		}
	}
	
	var descriptionIDOffset : Int {
		return kAbilitiesStartOffset + (index * kSizeOfAbilityEntry) + kAbilityDescriptionIDOffset
	}
	
	var descriptionID : Int {
		get {
			let dol = XGFiles.dol.data!
			return Int(dol.getWordAtOffset(descriptionIDOffset))
		}
	}
	
	var adescription : XGString {
		get {
			return XGFiles.common_rel.stringTable.stringSafelyWithID(descriptionID)
		}
	}
	
	func replaceNameID(newID: Int) {
		let dol = XGFiles.dol.data!
		dol.replace4BytesAtOffset(nameIDOffset, withBytes: newID)
		dol.save()
	}
	
	func replaceDescriptionID(newID: Int) {
		let dol = XGFiles.dol.data!
		dol.replace4BytesAtOffset(descriptionIDOffset, withBytes: newID)
		dol.save()
	}
	
	static func random() -> XGAbilities {
		var rand = 0
		while (XGAbilities.ability(rand).nameID == 0) || (XGAbilities.ability(rand).name.string.length < 2) {
			rand = Int.random(in: 1 ..< kNumberOfAbilities)
		}
		return XGAbilities.ability(rand)
	}
	
}

extension XGAbilities: Codable {
	enum CodingKeys: String, CodingKey {
		case index, name
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let index = try container.decode(Int.self, forKey: .index)
		self = .ability(index)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.index, forKey: .index)
		try container.encode(self.name.string, forKey: .name)
	}
}

extension XGAbilities: XGEnumerable {
	var enumerableName: String {
		return name.string.spaceToLength(20)
	}
	
	var enumerableValue: String? {
		return index.string
	}
	
	static var enumerableClassName: String {
		return "Abilities"
	}
	
	static var allValues: [XGAbilities] {
		var values = [XGAbilities]()
		for i in 0 ..< kNumberOfAbilities {
			values.append(.ability(i))
		}
		return values
	}
}

extension XGAbilities: XGDocumentable {
	
	static var documentableClassName: String {
		return "Abilities"
	}
	
	var documentableName: String {
		return name.string + "(\(index))"
	}
	
	static var DocumentableKeys: [String] {
		return ["index", "hex index", "name", "description"]
	}
	
	func documentableValue(for key: String) -> String {
		switch key {
		case "index":
			return index.string
		case "hex index":
			return index.hexString()
		case "name":
			return name.string
		case "description":
			return adescription.string
		default:
			return ""
		}
	}
}

func allAbilities() -> [String : XGAbilities] {
	var dic = [String : XGAbilities]()
	
	for i in 0 ..< kNumberOfAbilities {
		
		let a = XGAbilities.ability(i)
		dic[a.name.string.simplified] = a
		
	}
	
	return dic
}

let abilities = allAbilities()

func ability(_ name: String) -> XGAbilities {
	if abilities[name.simplified] == nil { printg("couldn't find: " + name) }
	return abilities[name.simplified] ?? .ability(0)
}





