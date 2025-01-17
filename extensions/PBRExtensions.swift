//
//  PBRExtensions.swift
//  GoDToolCL
//
//  Created by The Steez on 24/12/2018.
//

import Foundation

enum XGRegions : UInt32 {
	
	case US = 0x52504245 // RPBE
	case EU = 0x52504250 // RPBP
	case JP = 0x5250424A // RPBJ
	
	var index : Int {
		switch self {
		// arbitrary values
		case .US: return 0
		case .EU: return 1
		case .JP: return 2
		}
	}

	var name: String {
		switch self {
		case .EU: return "PAL"
		case .JP: return "JP"
		case .US: return "US"
		}
	}
}

let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/Revolution-Tool"
let region: XGRegions = {
	guard let isoData = XGFiles.iso.data else { return .EU }
	return XGRegions(rawValue: isoData.getWordAtOffset(0)) ?? .EU
}()
let game = XGGame.PBR
let isDemo = false

let date = Date(timeIntervalSinceNow: 0)
var logString = ""


extension XGString {
	var hasFurigana: Bool {
		return chars.contains(where: { (c) -> Bool in
			switch c {
			case .special(.id(1), _): // check for furigana character
				return true
			default:
				return false
			}
		})
	}

	func removeKanji() {
		// Looks for any instances of furigana. Uses the furigana as regular text and removes the kanji after it.
		var updatedChars = [XGUnicodeCharacters]()
		var includeCounter = 0
		var skipCounter = 0
		for char in chars {
			if includeCounter > 0 {
				updatedChars.append(char)
				includeCounter -= 1
			} else if skipCounter > 0 {
				skipCounter -= 1
			} else {
				switch char {
				case .unicode:
					updatedChars.append(char)
				case .special(.id(1), let args): // furigana
					includeCounter = args[0]
					skipCounter = args[1]
				default:
					updatedChars.append(char)
				}
			}
		}
		chars = updatedChars
	}
}

class XGUtility {
	class func saveData(_ data: Data, toFile file: XGFiles) -> Bool {
		if !file.folder.exists {
			file.folder.createDirectory()
		}
		do {
			try data.write(to: URL(fileURLWithPath: file.path), options: [.atomic])
		} catch {
			return false
		}
		return true
	}
	
	class func saveString(_ str: String, toFile file: XGFiles) {
		
		if let string = str.data(using: String.Encoding.utf8) {
			if !saveData(string, toFile: file) {
				// if printging to a log fails, don't keep printging :)
				if file.folder.name != XGFolders.Logs.name {
					printg("Couldn't save string to file: \(file.path)")
				} else {
					print("Couldn't save string to file: \(file.path)")
				}
			}
		} else {
			// if printging to a log fails, don't keep printging :)
			if file.folder.name != XGFolders.Logs.name {
				printg("Couldn't encode string for file: \(file.path)")
			} else {
				print("Couldn't encode string for file: \(file.path)")
			}
		}
	}
	
	class func saveJSON(_ json: AnyObject, toFile file: XGFiles) {
		if !file.folder.exists {
			file.folder.createDirectory()
		}
		do {
			try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted).write(to: URL(fileURLWithPath: file.path), options: [.atomic])
		} catch {
			printg("couldn't save json to file: \(file.path)")
		}
	}

	class func encodeJSONObject<T: Encodable>(_ object: T, toFile file: XGFiles) {
		if !file.folder.exists {
			file.folder.createDirectory()
		}
		object.writeJSON(to: file)
	}

	class func decodeJSONObject<T: Decodable>(from file: XGFiles) -> T? {
		return try? T.fromJSON(file: file)
	}
	
	class func loadJSONFromFile(_ file: XGFiles) -> AnyObject? {
		do {
			let json = try JSONSerialization.jsonObject(with: file.data!.data as Data, options: [])
			return json as AnyObject?
		} catch {
			printg("couldn't load json from file: \(file.path)")
			return nil
		}
	}
	
	// extraction
	@discardableResult
	class func decompileISO(printOutput: Bool = true) -> String? {
        printg("decompiling ISO using wit. This will overwrite any existing files...")
        if !XGFiles.iso.exists {
            printg("ISO doesn't exist:", XGFiles.iso.path)
            return nil
        }
        let verbose = settings.verbose ? "-v " : ""
        let overwrite = "-o"
        let args = "extract --raw \(verbose) \(overwrite) \(XGFiles.iso.path) \(XGFolders.ISODump.path)"
        return GoDShellManager.run(.wit, args: args, printOutput: printOutput)
    }
    
	class func extractMainFiles() {
		XGFolders.setUpFolderFormat()
		
		printg("extracting required files...")
		let requiredFiles : [XGFiles] = region == .JP ?
			[.fsys("common"), .fsys("deck")] :
			[.fsys("common"), .fsys("mes_common"), .fsys("deck")]
		var fileMissing = false
		for file in requiredFiles {
			if !file.exists {
				printg("Error: required file '\(file.path)' doesn't exist")
				fileMissing = true
			}
		}
		if fileMissing {
            printg("At least one required file was missing, try unpacking the ISO first.")
            return
        }
		
		let fsys = XGFiles.fsys("deck").fsysData
		
		var tid = 0
		var pid = 0
		for i in 0 ..< fsys.numberOfEntries {
			if !XGFiles.dckt(i).exists {
				let data = fsys.decompressedDataForFileWithIndex(index: i)!
				
				if let type = XGDeckTypes(rawValue: data.getWordAtOffset(0)) {
					switch type {
						case .DCKA: data.file = .dcka
						case .DCKP: data.file = .dckp(pid); pid += 1
						case .DCKT: data.file = .dckt(tid); tid += 1
						case .none: data.file = .nameAndFolder("deck_\(i)", .Decks)
					}
					
				} else {
					data.file = .nameAndFolder("deck_\(i)", .Decks)
				}
				data.save()
			}
		}
		
		let common = XGFiles.fsys("common").fsysData
		let numberOfCommonBinaries = region == .JP ? 32 : 33
		for i in 0 ..< numberOfCommonBinaries {
			if !XGFiles.common(i).exists, let data = common.decompressedDataForFileWithIndex(index: i) {
				data.file = .common(i)
				data.save()
			}
		}

		for filename in
			["mes_common", "menu_btutorial",
			(region == .JP ? "menu_fight_s" : "mes_fight_e"),
			(region == .JP ? "menu_name2" : "mes_name_e")] {
				if XGFiles.fsys(filename).exists {
					if let msg = XGFiles.fsys(filename).fsysData.decompressedDataForFileWithIndex(index: 1) {
						msg.file = .msg(filename)
						msg.save()
					}
				}
		}

		if region == .JP {
			let filename = "common"
			if XGFiles.fsys(filename).exists {
				if let msg = XGFiles.fsys(filename).fsysData.decompressedDataForFileWithIndex(index: 35) {
					msg.file = .msg(filename)
					msg.save()
				}
			}
		}

		printg("extraction complete!")
		
	}
	
	class func extractAllFiles() {
		XGFolders.setUpFolderFormat()
        extractMainFiles()
        printg("extracting fsys files...\nThis may take a while")
        for file in XGFolders.FSYS.files where file.fileType == .fsys {
            printg("extracting:", file.path)
            let fsys = file.fsysData
            if let msg = fsys.decompressedDataForFileWithFiletype(type: .msg) {
                msg.file = .msg(msg.file.fileName.removeFileExtensions())
                if !msg.file.exists {
                    msg.save()
                }
            }
            let folder = XGFolders.ISOExport(fsys.fileName.removeFileExtensions())
            folder.createDirectory()
            fsys.extractFilesToFolder(folder: folder, decode: true)
        }
        printg("extraction complete!")
    }
    
    class func compileMainFiles() {
        XGFolders.setUpFolderFormat()
        printg("compiling main files...")
        compileDecks()
        compileCommon()
        compileMSG()
    }

	class func exportFileFromISO(_ file: XGFiles, decode: Bool = true) -> Bool {
		XGFolders.ISOExport("").createDirectory()

		if let data = ISO.dataForFile(filename: file.fileName) {
			if data.length > 0 {
				data.file = file
				if file.fileType == .fsys {
					let fsysData = data.fsysData
					fsysData.extractFilesToFolder(folder: file.folder, decode: decode)
				}
				data.save()
				return true
			}
		}
		return false
	}

	class func importFileToISO(_ fileToImport: XGFiles, encode: Bool = true) -> Bool {
		if fileToImport.exists {
			if fileToImport.fileType == .fsys {

				if encode {
					XGColour.colourThreshold = 0
					for file in fileToImport.folder.files {

						// encode string tables before compiling scripts
						if file.fileType == .msg {
							for json in fileToImport.folder.files where json.fileType == .json {
								if json.fileName.removeFileExtensions() == file.fileName.removeFileExtensions() {
									let table = try? XGStringTable.fromJSONFile(file: json)
									if let table = table {
										table.file = file
										table.save()
									} else {
										printg("Failed to decode string table from: ", json.path)
									}
								}
							}
						}


						if file.fileType == .gtx || file.fileType == .atx {
							for imageFile in fileToImport.folder.files where XGFileTypes.imageFormats.contains(imageFile.fileType) {
								if imageFile.fileName.removeFileExtensions() == file.fileName.removeFileExtensions() {
									if settings.verbose {
										printg("importing \(imageFile.path) into \(file.path)")
									}
									if let image = XGImage.loadImageData(fromFile: imageFile) {
										let texture: GoDTexture
										if file.fileName.contains(".sdr.")
										|| file.fileName.contains(".odr.")
										|| file.fileName.contains(".mdr.")
										|| file.fileName.contains(".mnr.")
										{
											// preserves the image format so can easily be imported into model
											let oldTexture = file.texture
											let importer = GoDTextureImporter(oldTextureData: oldTexture, newImage: image)
											importer.replaceTextureData()
											texture = importer.texture

										} else {
											// automatically chooses a good format for the new image
											texture = image.texture
										}

										texture.file = file
										texture.save()
									}
								}
							}
						}
					}

					// import model textures after all gtxs have been encoded
					for file in fileToImport.folder.files {
						if XGFileTypes.textureContainingFormats.contains(file.fileType) {
							if let dataFormat = PBRTextureContaining.fromFile(file) {
								var expectedFiles = dataFormat.textures
								var foundReplacement = false
								for i in 0 ..< expectedFiles.count {
									let textureFile = expectedFiles.map { $0.data.file }[i]
									if textureFile.exists {
										expectedFiles[i] = textureFile.texture
										foundReplacement = true
									}
								}
								if foundReplacement {
									dataFormat.importTextures(expectedFiles)
									dataFormat.data?.save()
								}
							}
						}

						// strings in the xds scripts will override those particular strings in the msg's json
						if file.fileType == .xds && game != .PBR {
							XDSScriptCompiler.setFlags(disassemble: true, decompile: false, updateStrings: true, increaseMSG: true)
							XDSScriptCompiler.baseStringID = 1000
							if !XDSScriptCompiler.compile(textFile: file, toFile: .nameAndFolder(file.fileName.removeFileExtensions() + XGFileTypes.scd.fileExtension, file.folder)) {
								printg("XDS Compilation Error:\n" + XDSScriptCompiler.error)
								return false
							}
						}
					}
				}

				let fsysData = fileToImport.fsysData
				for i in 0 ..< fsysData.numberOfEntries {
					var filename = ""
					if fsysData.usesFileExtensions {
						filename = fsysData.fullFileNames[i]
					} else {
						filename = fsysData.fileNames[i].removeFileExtensions() + fsysData.fileTypeForFile(index: i).fileExtension
					}
					if !fsysData.usesFileExtensions || filename.removeFileExtensions() == filename {
						filename = filename.removeFileExtensions()
						filename += fsysData.fileTypeForFile(index: i).fileExtension
					}
					for file in fileToImport.folder.files {
						if file.fileName == filename {
							if fsysData.isFileCompressed(index: i){
								fsysData.shiftAndReplaceFileWithIndexEfficiently(i, withFile: file.compress(), save: false)
							} else {
								fsysData.shiftAndReplaceFileWithIndexEfficiently(i, withFile: file, save: false)
							}
						}
					}
				}
				fsysData.save()
			}
			ISO.importFiles([fileToImport])
			return true
		} else {
			printg("The file: \(fileToImport.path) doesn't exit")
			return false
		}
	}

	class func disableAntiModChecks() {
		// Modifies a function in main.dol to prevent the game from softlocking when the ISO has been modified.
		printg("Disabling anti modification code.")
		guard let dol = XGFiles.dol.data else {
			printg("File doesn't exist: \(XGFiles.dol.path)")
			return
		}
		// offset 0x8022965c in RAM (0x8021de60 JP)
		let offset: Int
		switch region {
		case .EU: offset = 0x2252bc
		case .JP: offset = 0x219Ac0
		case .US: offset = 0x229E44
		}

		dol.replace4BytesAtOffset(offset, withBytes: 0x48000100)
		dol.save()
	}

	@discardableResult
	class func compileISO(printOutput: Bool = true) -> String? {
		disableAntiModChecks()

        printg("compiling ISO...\nThis will overwrite the existing ISO")
        let verbose = settings.verbose ? "-v " : ""
        let overwrite = "-o"
        let args = "copy \(overwrite) \(verbose) \(XGFolders.ISODump.path) \(XGFiles.iso.path)"
        return GoDShellManager.run(.wit, args: args, printOutput: printOutput)
    }
	
	class func getFSYSForIdentifier(id: UInt32) -> XGFsys? {
		for file in XGFolders.FSYS.files where file.fileName.contains(".fsys") {
			let fsys = file.data!
			let entries = fsys.get4BytesAtOffset(kNumberOfEntriesOffset)
			
			for i in 0 ..< entries {
				let details = fsys.get4BytesAtOffset(0x60)
				let identifier = fsys.getWordAtOffset(details + (i * kSizeOfArchiveEntry))
				if identifier == id {
					return file.fsysData
				}
			}
			
		}
		return nil
	}
	
	class func compileDecks() {
		printg("Compiling decks...")
		var pid = 0
		var tid = 0
		
		var deckDict = [Int : XGFiles]()
		for i in 0 ... 25 {
			deckDict[i] = .dckt(tid)
			tid += 1
		}
		for i in 0 ... 7 {
			deckDict[i + 26] = .dckp(pid)
			pid += 1
		}
		deckDict[34] = .dckt(tid)
		tid += 1
		for i in 0 ... 5 {
			deckDict[35 + i] = .dckp(pid)
			pid += 1
		}
		for i in 0 ... 1 {
			deckDict[41 + i] = .dckt(tid)
			tid += 1
		}
		for i in 0 ... 1 {
			deckDict[43 + i] = .dckp(pid)
			pid += 1
		}
		deckDict[45] = .dcka
		
		let file = XGFiles.fsys("deck")
		if file.exists {
			let fsys = XGFiles.fsys("deck").fsysData
			
			for (index, file) in deckDict {
				if file.exists {
					if settings.verbose {
						printg("Compiling deck:", file.path)
					}
					fsys.shiftAndReplaceFileWithIndexEfficiently(index, withFile: file.compress(), save: false)
				}
			}
			
			fsys.save()
			printg("Finished compiling decks.")
		} else {
			printg("Couldn't compile decks as \(file.path) doesn't exist")
		}
		
	}
    
    class func compileCommon() {
        printg("Compiling common...")
        let file = XGFiles.fsys("common")
        if file.exists {
            let fsys = file.fsysData

			let numberOfCommonBinaries = region == .JP ? 32 : 33
            for cid in 0 ..< numberOfCommonBinaries {
                let cFile = XGFiles.common(cid)
                if cFile.exists {
                    if settings.verbose {
                        printg("Compiling common:", cFile.path)
                    }
                    fsys.shiftAndReplaceFileWithIndexEfficiently(cid, withFile: cFile.compress(), save: false)
                }
            }
            
            fsys.save()
            printg("Finished compiling common.")
        } else {
            printg("Couldn't compile common as \(file.path) doesn't exist")
        }
        
    }
    
    class func compileMSG() {
        printg("Compiling msgs...")

		if region == .JP {
			let filename = "common"
			let fsys = XGFiles.fsys(filename)
            let msg = XGFiles.msg(filename)
            if fsys.exists && msg.exists {
                if settings.verbose {
                    printg("Compiling msg:", msg.path)
                }
                let fsysData = fsys.fsysData
                fsysData.shiftAndReplaceFileWithIndexEfficiently(35, withFile: msg.compress(), save: true)
            }
		}
        
        for filename in
			["mes_common", "menu_btutorial",
			(region == .JP ? "menu_fight_s" : "mes_fight_e"),
			(region == .JP ? "menu_name2" : "mes_name_e")] {
            let fsys = XGFiles.fsys(filename)
            let msg = XGFiles.msg(filename)
            if fsys.exists && msg.exists {
                if settings.verbose {
                    printg("Compiling msg:", msg.path)
                }
                let fsysData = fsys.fsysData
                fsysData.shiftAndReplaceFileWithIndexEfficiently(1, withFile: msg.compress(), save: true)
            }
        }

		let mes_bpass_e = XGFiles.fsys(region == .JP ? "menu_bpass2" : "mes_bpass_e")
		let mes_fight_e = XGFiles.msg("mes_fight_e")
		let mes_name_e = XGFiles.msg("mes_name_e")
		if mes_bpass_e.exists {
			let fsys = mes_bpass_e.fsysData

			if mes_fight_e.exists {
				let index = region == .JP ? 3 : 2
				fsys.shiftAndReplaceFileWithIndexEfficiently(index, withFile: mes_fight_e.compress(), save: true)
			}
			if mes_name_e.exists {
				let index = region == .JP ? 2 : 3
				fsys.shiftAndReplaceFileWithIndexEfficiently(index, withFile: mes_name_e.compress(), save: true)
			}
		}

        printg("Finished compiling msgs.")
    }

	// for gc compatibility
	class func exportDatFromPKX(pkx: XGMutableData) -> XGMutableData {
		return XGMutableData()
	}

	class func importDatToPKX(dat: XGMutableData, pkx: XGMutableData) -> XGMutableData {
		return XGMutableData()
	}
	
}


var allStringTables = [XGStringTable]()
var stringsLoaded = false

func loadAllStrings() {
	
	if !stringsLoaded {
		
		// very specific order based on the id at index 0xb in the .msg file
		// files with the same id are identical but may be loaded at different times
		// the first stringid in the next file is one greater than the last stringid of the previous file
		allStringTables = [XGStringTable]()

		for filename in
			[region == .JP ? "common" : "mes_common",
			(region == .JP ? "menu_fight_s" : "mes_fight_e"),
			(region == .JP ? "menu_name2" : "mes_name_e")]
			+ (region == .JP ? [] : ["menu_btutorial"])
		{

				let file = XGFiles.msg(filename)
				if file.exists {
					allStringTables.append(file.stringTable)
				} else {
					XGUtility.extractMainFiles()
					if !file.exists {
						printg("Error loading strings. File doesn't exist:", file.path)
					} else {
						allStringTables.append(file.stringTable)
					}

				}

				stringsLoaded = true
		}
		allStringTables.sort { (s1, s2) -> Bool in
			s1.tableID < s2.tableID
		}
	}
}

func getStringWithID(id: Int) -> XGString? {
	loadAllStrings()
	
	if id == 0 {
		return nil
	}
	
	var currentID = id
	for table in allStringTables {
		if table.containsStringWithId(currentID) {
			if let s = table.stringWithID(currentID) {
				return s
			}
		} else {
			currentID -= table.numberOfEntries
		}
	}
	return nil
}

func getStringSafelyWithID(id: Int) -> XGString {
	loadAllStrings()
	
	return getStringWithID(id: id) ?? XGString(string: "-", file: nil, sid: nil)
}

func getStringsContaining(substring: String) -> [XGString] {
	loadAllStrings()
	
	var found = [XGString]()
	for table in allStringTables {
		for str in table.allStrings() where str.containsSubstring(substring) {
			found.append(str)
		}
	}
	
	return found
}


extension XGUtility {
	//MARK: - Documentation
	class func documentXDS() { }
	class func documentMacrosXDS() { }
	class func documentXDSClasses() { }
	class func documentXDSAutoCompletions(toFile file: XGFiles) { }
	
	private static var isDocumentingISO = false
	private static var shouldCancelDocumentation = false
	static func cancelDocumentation() {
		shouldCancelDocumentation = true
	}
	class func documentISO() {

		guard !isDocumentingISO else {
			printg("Already Documenting ISO!")
			return
		}

		isDocumentingISO = true
		shouldCancelDocumentation = false
		printg("Documenting ISO.\nThis may take a while...")
		XGThreadManager.manager.runInBackgroundAsync {
			printg("Documenting Enumerations...")
			// Enumerations
			if !shouldCancelDocumentation {
				printg("Enumerating Abilities...")
				XGAbilities.documentEnumerationData()
			}
			if !shouldCancelDocumentation {
				printg("Enumerating B-G Enumerations...")
				XGContestAppeals.documentEnumerationData()
				XGDecks.documentEnumerationData()
				XGDeoxysFormes.documentEnumerationData()
				XGEffectivenessValues.documentEnumerationData()
				XGEvolutionMethods.documentEnumerationData()
				XGExpRate.documentEnumerationData()
				XGGenderRatios.documentEnumerationData()
				XGGenders.documentEnumerationData()
			}
			if !shouldCancelDocumentation {
				printg("Enumerating Items...")
				XGItems.documentEnumerationData()
				XGItem.documentData()
			}
			if !shouldCancelDocumentation {
				printg("Enumerating Moves...")
				XGMoves.documentEnumerationData()
				XGMove.documentData()
			}
			if !shouldCancelDocumentation {
				printg("Enumerating M-N Enumerations...")
				XGMoveCategories.documentEnumerationData()
				XGMoveEffectTypes.documentEnumerationData()
				XGMoveTargets.documentEnumerationData()
				XGMoveTypes.documentEnumerationData()
				XGNatures.documentEnumerationData()
			}
			if !shouldCancelDocumentation {
				printg("Enumerating Pokemon...")
				XGPokemon.documentEnumerationData()
				XGPokemonStats.documentData()
			}
			if !shouldCancelDocumentation {
				printg("Enumerating TMs...")
				XGTMs.documentEnumerationData()
			}

			if !shouldCancelDocumentation {
				printg("Finished Documenting ISO.")
			} else {
				printg("Cancelled Documenting ISO.")
			}
			isDocumentingISO = false
		}

	}
}












