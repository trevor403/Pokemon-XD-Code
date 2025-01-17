//
//  XGString.swift
//  XG Tool
//
//  Created by StarsMmd on 25/06/2015.
//  Copyright (c) 2015 StarsMmd. All rights reserved.
//

import Foundation

class XGString: NSObject, Codable {
	
	var chars = [XGUnicodeCharacters]()
	private var initString = "" // just for debugging
	
	var table = XGFiles.nameAndFolder("", .Documents)
	var id	  = 0
	
	var dataLength: Int {
		get {
			return self.byteStream.count
		}
	}
	
	var stringLength: Int {
		return chars.count
	}
	
	override var description: String {
		return self.unformattedString
	}
	
	var string : String {
		get {
			var str = ""
			for char in chars {
				str = str + char.string
			}
			return str
		}
	}

	var stringWithEscapedNewlines: String {
		return string.replacingOccurrences(of: "\n", with: "[New Line]")
	}

	var unformattedString : String {
		get {
			var str = ""
			for char in chars where !char.isFormattingChar {
				str = str + char.string
			}
			return str.replacingOccurrences(of: "\n", with: "[New Line]")
		}
	}
	
	var stringPlusIDAndFile : String {
		get {
			return "ID : 0x" + String(format: "%x", id) + " " + "\(id)" + " \nFile: \(table.fileName)\n\(string)\n"
		}
	}
	
	var byteStream : [UInt8] {
		get {
			var stream = [UInt8]()
			for char in chars {
				stream = stream + char.byteStream
			}
			if game == .PBR {
				stream += XGSpecialCharacters.dialogueEnd.byteStream
			} else {
				stream += [0, 0]
			}
			return stream
		}
	}
	
	func append(_ char: XGUnicodeCharacters) {
		self.chars.append(char)
		initString += char.string
	}
	
	init(string: String, file: XGFiles?, sid: Int?) {
		// Forgive me! I wrote this years ago when I was still learning swift and the default
		// swift library has some really bad string manipulation functions
		// The function works. It used to be a lot worse... trust me :-)
		super.init()
		
		self.table = file ?? XGFiles.nameAndFolder("", .Documents)
		self.id = sid ?? 0
		self.initString = string
		let string = string.replacingOccurrences(of: "\n", with: "[New Line]")

		var chars = [XGUnicodeCharacters]()
		
		var current   = 0
		let end		  = string.length

		while current != end {
			
			var char = string.substring(from: current, to: current + 1)
			current += 1
			
			if char == "[" {
				var midString = ""
				
				char = string.substring(from: current, to: current + 1)
				current += 1
				
				while char != "]" {
					midString = midString + char
					
					char = string.substring(from: current, to: current + 1)
					current += 1
				}
				
				let sp = XGSpecialCharacters.fromString(midString)

				var extraBytes = [Int]()

				if sp.extraBytes > 0 {
					current += 1

					for _ in 0 ..< sp.extraBytes {

						var byte = ""
						char = string.substring(from: current, to: current + 1)
						current += 1
						byte = byte + char

						char = string.substring(from: current, to: current + 1)
						current += 1
						byte = byte + char

						extraBytes.append(byte.hexStringToInt())

					}
					current += 1
				}

				let ch = XGUnicodeCharacters.special(sp, extraBytes)
				chars.append(ch)

				
			} else {
				
				let charScalar = String(char).unicodeScalars
				for char in charScalar {
					let charValue  = Int(char.value)

					var ch = XGUnicodeCharacters.unicode(charValue)
					if char == "'" {
						ch = .unicode(0x27)
					}

					chars.append(ch)
				}
			}
			
		}
		
		self.chars = chars
	}
	
	@discardableResult func replace(save: Bool = true) -> Bool {
		if self.id == 0 {
			return false
		}
		
		loadAllStrings()
		var success = false
		for table in allStringTables {
			if table.containsStringWithId(self.id) {
				let tableSuccess = table.replaceString(self, save: save)
				if !tableSuccess {
					printg("Could not replace string with id \(self.id) in table: \(table.file.fileName)")
				}
				success = success || tableSuccess
			}
		}
		return success
	}
	
	func replaceDirectly(save: Bool) -> Bool {
		stringsLoaded = false
		return self.table.stringTable.replaceString(self, save: save)
	}
	
	func containsSubstring(_ sub: String) -> Bool {
		return self.string.contains(sub)
	}
	
	func replaceSubstring(_ sub: String, withString new: String) {
		let str = self.string.replacingOccurrences(of: sub, with: new, options: [], range: nil)
		_ = self.duplicateWithString(str).replace()
	}
	
	func duplicateWithString(_ str: String) -> XGString {
		return XGString(string: str, file: self.table, sid: self.id)
	}
	
	enum CodingKeys: String, CodingKey {
		case text, id
	}
	
	required convenience init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let text = try container.decode(String.self, forKey: .text)
		let file: XGFiles? = nil
		let id = try? container.decode(Int.self, forKey: .id)
		self.init(string: text, file: file, sid: id)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(self.string, forKey: .text)
		if game != .PBR {
			try container.encode(self.id, forKey: .id)
		}
	}
}

extension XGString: XGDocumentable {
	
	static var documentableClassName: String {
		return "String"
	}
	
	var documentableName: String {
		return table.fileName + " - " + id.hexString()
	}
	
	static var DocumentableKeys: [String] {
		return ["id", "encoded length", "text"]
	}
	
	func documentableValue(for key: String) -> String {
		switch key {
		case "id":
			return id.hexString()
		case "encoded length":
			return dataLength.string
		case "text":
			return string
		default:
			return ""
		}
	}
}











