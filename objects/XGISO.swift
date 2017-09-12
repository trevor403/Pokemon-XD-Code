//
//  XGISO.swift
//  XGCommandLineTools
//
//  Created by StarsMmd on 15/04/2016.
//  Copyright © 2016 StarsMmd. All rights reserved.
//

import Foundation

//let fileLocations = [
//	"Start.dol"				: 0x20258,
//	"common.fsys"			: 0x16A8C0A0,
//	"common_dvdeth.fsys"	: 0x16AEE5E0,
//	"deck_archive.fsys"		: 0x1BFA28DC,
//	"field_common.fsys"		: 0x1D9D183C,
//	"fight_common.fsys"		: 0x1DBC50BC,
//	"title.fsys"			: 0x4FE18C00,
//	"M3_cave_1F_2.fsys"		: 0x2087323C,
//	"M2_guild_1F_2.fsys"	: 0x1FE3A8DC,
//]

let kTOCFirstStringOffset = 0x783C

class XGISO: NSObject {
	
	fileprivate let toc = XGFiles.toc.data
	
	fileprivate var fileLocations = ["Start.dol" : 131840]
//	fileprivate var fileLocations = ["Start.dol" : 0x1EC00] colosseum
	
	fileprivate var fileSizes = ["Start.dol" : 0x421E00]
//	fileprivate var fileSizes = ["Start.dol" : 0x39AD00] colosseum
	
	var allFileNames = ["Start.dol"]
	
	override init() {
		super.init()
		
		var i = 0x0
		
		while (i < kTOCFirstStringOffset) {
			
			let folder = toc.getByteAtOffset(i) == 1
			
			if !folder {
				
				let nameOffset = Int(toc.get4BytesAtOffset(i))
				let fileOffset = Int(toc.get4BytesAtOffset(i + 4))
				let fileSize   = Int(toc.get4BytesAtOffset(i + 8))
				
				let fileName = getStringAtOffset(nameOffset).string
				
				allFileNames.append(fileName)
				fileLocations[fileName] = fileOffset
				fileSizes[fileName]     = fileSize
				
			}
			
			i += 0xC
		}
	}
	
	func updateISO() {
		
		var files = XGFolders.FSYS.files ?? [XGFiles]()
		files.append(.dol)
		importFiles(files)
		
	}
	
	func importRandomiserFiles() {
		var files = XGFolders.FSYS.files ?? [XGFiles]()
		files.append(.dol)
		importFiles(files)
	}
	
	func importAllFiles() {
		var files = XGFolders.FSYS.files ?? [XGFiles]()
		files += XGFolders.AutoFSYS.files ?? [XGFiles]()
		files += XGFolders.MenuFSYS.files ?? [XGFiles]()
		files.append(.dol)
		importFiles(files)
	}
	
	func importDol() {
		importFiles([.dol])
	}

	func importFiles(_ fileList: [XGFiles]) {
		
		let isodata = XGFiles.iso.data
		
		for file in fileList {
			
			let filename = file.fileName
			let data = file.data
			
			print("importing file to ISO: " + filename)
			
			let start = self.locationForFile(filename)
			let oldsize  = self.sizeForFile(filename)
			let newsize = data.length
			
			if (start == nil) || (oldsize == nil) {
				print("file not found in ISO's .toc: " + filename)
				continue
			}
			
			if oldsize! < newsize {
				print("file too large: " + filename)
				continue
			}
			
			var byteStream = data.byteStream
			if newsize < oldsize! {
				byteStream += [Int](repeatElement(0, count: oldsize! - newsize))
			}
			
			isodata.replaceBytesFromOffset(start!, withByteStream: byteStream)
		}
		
		isodata.save()
	}
	
	fileprivate func getStringAtOffset(_ offset: Int) -> XGString {
		
		var currentOffset = offset + kTOCFirstStringOffset
		
		var currChar = 0x0
		var nextChar = 0x1
		
		let string = XGString(string: "", file: nil, sid: nil)
		
		while (nextChar != 0x00) {
			
			currChar = toc.getByteAtOffset(currentOffset)
			currentOffset += 1
			
			string.append(.unicode(currChar))
			
			
			nextChar = toc.getByteAtOffset(currentOffset)
			
		}
		
		return string
		
	}
	
	func locationForFile(_ fileName: String) -> Int? {
		return fileLocations[fileName]
	}
	
	func printFileLocations() {
		for k in fileLocations.keys.sorted() {
			print(k,"\t:\t\(fileLocations[k]!)")
		}
	}
	
	func sizeForFile(_ fileName: String) -> Int? {
		return fileSizes[fileName]
	}
	
	func dataForFile(filename: String) -> XGMutableData? {
		
		let start = self.locationForFile(filename)
		let size  = self.sizeForFile(filename)
		
		if (start == nil) || (size == nil) {
			return nil
		}
		
		let data = XGFiles.iso.data
		let bytes = data.getCharStreamFromOffset(start!, length: size!)
		
		return XGMutableData(byteStream: bytes, file: XGFiles.nameAndFolder(filename, .Documents))
		
	}
	
	func replaceDataForFile(filename: String, withData data: XGMutableData) {
		
		let start = self.locationForFile(filename)
		let oldsize  = self.sizeForFile(filename)
		let newsize = data.length
		
		if (start == nil) || (oldsize == nil) {
			return
		}
		
		if oldsize != newsize {
			return
		}
		
		let isodata = XGFiles.iso.data
		isodata.replaceBytesFromOffset(start!, withByteStream: data.byteStream)
		isodata.save()
		
	}
	
	class func extractTOC() {
		let iso = XGFiles.iso.data
		
		let TOCStart = 0x442100
		let TOCLength = 0x15958
		
		let bytes = iso.getCharStreamFromOffset(TOCStart, length: TOCLength)
		
		let toc = XGMutableData(byteStream: bytes, file: .toc)
		toc.save()
		
	}
	
	var autoFsysList : [String] {
		return [
			"D1_garage_1F.fsys",
			"D1_garage_B1.fsys",
			"D1_garage_B2_1.fsys",
			"D1_garage_B2_2.fsys",
			"D1_labo_1F.fsys",
			"D1_labo_B1.fsys",
			"D1_labo_B2.fsys",
			"D1_labo_B3.fsys",
			"D1_out.fsys",
			"D2_cloud_1.fsys",
			"D2_cloud_2.fsys",
			"D2_cloud_3.fsys",
			"D2_cloud_4.fsys",
			"D2_crater_colo.fsys",
			"D2_magma_1.fsys",
			"D2_magma_2.fsys",
			"D2_magma_3.fsys",
			"D2_out.fsys",
			"D2_pc_1F.fsys",
			"D2_rest_1.fsys",
			"D2_rest_2.fsys",
			"D2_rest_3.fsys",
			"D2_rest_4.fsys",
			"D2_rest_5.fsys",
			"D2_rest_6.fsys",
			"D2_rest_7.fsys",
			"D2_rest_8.fsys",
			"D2_rest_9.fsys",
			"D2_valley_1.fsys",
			"D2_valley_2.fsys",
			"D2_valley_3.fsys",
			"D3_out.fsys",
			"D3_ship_B1_1.fsys",
			"D3_ship_B1_2.fsys",
			"D3_ship_B1_3.fsys",
			"D3_ship_B2_1.fsys",
			"D3_ship_B2_2.fsys",
			"D3_ship_B2_3.fsys",
			"D3_ship_bridge.fsys",
			"D3_ship_cabine.fsys",
			"D3_ship_deck.fsys",
			"D4_casino_colo.fsys",
			"D4_dome_1.fsys",
			"D4_dome_2.fsys",
			"D4_dome_3.fsys",
			"D4_dome_4.fsys",
			"D4_out.fsys",
			"D4_out_2.fsys",
			"D4_tower_1F_1.fsys",
			"D4_tower_1F_2.fsys",
			"D4_tower_1F_3.fsys",
			"D5_factory_1F.fsys",
			"D5_factory_2F.fsys",
			"D5_factory_3F.fsys",
			"D5_factory_4F.fsys",
			"D5_factory_B1.fsys",
			"D5_factory_hat.fsys",
			"D5_factory_top.fsys",
			"D5_out.fsys",
			"D6_cruiser.fsys",
			"D6_dome_1F.fsys",
			"D6_dome_2F.fsys",
			"D6_dome_B1.fsys",
			"D6_fort_1F.fsys",
			"D6_fort_2F_1.fsys",
			"D6_fort_2F_2.fsys",
			"D6_fort_2F_3.fsys",
			"D6_fort_3F_1.fsys",
			"D6_fort_3F_2.fsys",
			"D6_fort_4F.fsys",
			"D6_fort_5F.fsys",
			"D6_fort_6F.fsys",
			"D6_fort_B1.fsys",
			"D6_out_all.fsys",
			"D6_out_dome.fsys",
			"D6_out_foot.fsys",
			"D7_out.fsys",
			"esaba_A.fsys",
			"esaba_B.fsys",
			"esaba_C.fsys",
			"M1_carde_1.fsys",
			"M1_gym_1F.fsys",
			"M1_gym_B1.fsys",
			"M1_houseA_1F.fsys",
			"M1_houseA_2F.fsys",
			"M1_houseB_1F.fsys",
			"M1_houseC_1F.fsys",
			"M1_out.fsys",
			"M1_pc_1F.fsys",
			"M1_pc_B1.fsys",
			"M1_shop_1F.fsys",
			"M1_shop_2F.fsys",
			"M1_stadium_1F.fsys",
			"M1_water_colo.fsys",
			"M1_water_colo_field.fsys",
			"M2_building_1F.fsys",
			"M2_building_2F.fsys",
			"M2_building_3F.fsys",
			"M2_building_4F.fsys",
			"M2_cave_1F_1.fsys",
			"M2_cave_1F_2.fsys",
			"M2_cave_2F_1.fsys",
			"M2_cave_2F_2.fsys",
			"M2_cave_3F_1.fsys",
			"M2_cave_3F_2.fsys",
			"M2_enter_1F.fsys",
			"M2_enter_1F_2.fsys",
			"M2_guild_1F_1.fsys",
			"M2_guild_1F_2.fsys",
			"M2_hotel_1F.fsys",
			"M2_houseA_1F.fsys",
			"M2_out.fsys",
			"M2_police_1F.fsys",
			"M2_shop_1F.fsys",
			"M2_uranai_1F.fsys",
			"M2_windmill_1F.fsys",
			"M3_cave_1F_1.fsys",
			"M3_cave_1F_2.fsys",
			"M3_houseA_1F.fsys",
			"M3_houseB_1F.fsys",
			"M3_houseC_1F.fsys",
			"M3_houseC_2F.fsys",
			"M3_houseD_1F.fsys",
			"M3_out.fsys",
			"M3_pc_1F.fsys",
			"M3_shop_1F.fsys",
			"M3_shrine_1F.fsys",
			"M5_apart_1F.fsys",
			"M5_apart_2F.fsys",
			"M5_labo_1F.fsys",
			"M5_labo_2F.fsys",
			"M5_labo_B1.fsys",
			"M5_out.fsys",
			"M6_crab_1F.fsys",
			"M6_crab_2F.fsys",
			"M6_crab_B1.fsys",
			"M6_houseA.fsys",
			"M6_houseB.fsys",
			"M6_houseC.fsys",
			"M6_houseD.fsys",
			"M6_junk_1F.fsys",
			"M6_junk_2F.fsys",
			"M6_out.fsys",
			"M6_pc_1F.fsys",
			"M6_pc_2F.fsys",
			"M6_shop_1F.fsys",
			"M6_shop_2F.fsys",
			"M6_tower_1F.fsys",
			"M6_tower_2F.fsys",
			"M6_tower_3F.fsys",
			"M6_tower_4F.fsys",
			"M6_tower_top.fsys",
			"S1_out.fsys",
			"S1_shop_1F.fsys",
			"S2_bossroom_1.fsys",
			"S2_building_1F_2.fsys",
			"S2_building_2F_2.fsys",
			"S2_building_3F_2.fsys",
			"S2_hallway_1.fsys",
			"S2_out_1.fsys",
			"S2_out_2.fsys",
			"S2_out_3.fsys",
			"S2_snatchroom_1.fsys",
			"S3_labo_1F.fsys",
			"S3_labo_B1low.fsys",
			"S3_labo_B1up.fsys",
			"S3_out.fsys"
		]
	}
	
	var fsysList : [String] {
		return [
			"common.fsys",
			"common_dvdeth.fsys",
			"deck_archive.fsys",
			"field_common.fsys",
			"fight_common.fsys"
		]
	}
	
	var menuFsysList : [String] {
		return [
			"battle_disk.fsys",
			"bingo_menu.fsys",
			"carde_menu.fsys",
			"colosseumbattle_menu.fsys",
			"D2_present_room.fsys",
			"hologram_menu.fsys",
			"mailopen_menu.fsys",
			"mewwaza.fsys",
			"name_entry_menu.fsys",
			"orre_menu.fsys",
			"pcbox_menu.fsys",
			"pcbox_name_entry_menu.fsys",
			"pcbox_pocket_menu.fsys",
			"pda_menu.fsys",
			"pocket_menu.fsys",
			"pokemonchange_menu.fsys",
			"relivehall_menu.fsys",
			"title.fsys",
			"topmenu.fsys",
			"waza_menu.fsys",
			"worldmap.fsys"
		]
	}
	
	var deckList : [String] {
		return [
			"DeckData_DarkPokemon.bin",
			"DeckData_Story.bin",
			"DeckData_Bingo.bin",
			"DeckData_Colosseum.bin",
			"DeckData_Hundred.bin",
			"DeckData_Imasugu.bin",
			"DeckData_Sample.bin",
			"DeckData_Virtual.bin"
		]
	}
	
	func extractAutoFSYS() {
		for file in self.autoFsysList {
			let data = dataForFile(filename: file)!
			data.file = XGFiles.nameAndFolder(file, .AutoFSYS)
			data.save()
		}
	}
	
	func extractMenuFSYS() {
		for file in self.menuFsysList {
			let data = dataForFile(filename: file)!
			data.file = XGFiles.nameAndFolder(file, .MenuFSYS)
			data.save()
		}
	}
	
	func extractFSYS() {
		for file in self.fsysList {
			let data = dataForFile(filename: file)!
			data.file = XGFiles.nameAndFolder(file, .FSYS)
			data.save()
		}
	}
	
	func extractAllFSYS() {
		extractAutoFSYS()
		extractMenuFSYS()
		extractFSYS()
	}
	
	func extractCommon() {
		let rel = XGFiles.fsys("common.fsys").fsysData.decompressedDataForFileWithIndex(index: 0)!
		rel.file = .common_rel
		rel.save()
		let tableres2 = XGFiles.fsys("common_dvdeth.fsys").fsysData.decompressedDataForFileWithIndex(index: 0)!
		tableres2.file = .tableres2
		tableres2.save()
		let pocket = XGFiles.nameAndFolder("pocket_menu.fsys",.MenuFSYS).fsysData.decompressedDataForFileWithIndex(index: 0)!
		pocket.file = .nameAndFolder("pocket_menu.fdat", .Common)
		pocket.save()
		
	}
	
	func extractDecks() {
		let deck = XGFiles.fsys("deck_archive.fsys").fsysData
		let colosseum = deck.decompressedDataForFileWithIndex(index: 2)!
		let dark = deck.decompressedDataForFileWithIndex(index: 4)!
		let hundred = deck.decompressedDataForFileWithIndex(index: 6)!
		let story = deck.decompressedDataForFileWithIndex(index: 12)!
		let virtual = deck.decompressedDataForFileWithIndex(index: 14)!
		colosseum.file = .deck(.DeckColosseum)
		dark.file = .deck(.DeckDarkPokemon)
		hundred.file = .deck(.DeckHundred)
		story.file = .deck(.DeckStory)
		virtual.file = .deck(.DeckVirtual)
		colosseum.save()
		dark.save()
		hundred.save()
		story.save()
		virtual.save()
		
	}
	
	func extractAutoStringTables() {
		for file in XGFolders.AutoFSYS.filenames {
			let msg = file.replacingOccurrences(of: ".fsys", with: ".msg")
			let fsys = XGFiles.nameAndFolder(file, .AutoFSYS).fsysData
			let data = fsys.decompressedDataForFileWithIndex(index: 2)!
			data.file = .stringTable(msg)
			data.save()
		}
	}
	
	func extractSpecificStringTables() {
		let fight = XGFiles.fsys("fight_common.fsys").fsysData.decompressedDataForFileWithIndex(index: 0)!
		fight.file = .stringTable("fight.msg")
		fight.save()
		
		
		let pocket_menu = XGFiles.stringTable("pocket_menu.msg")
		let nameentrymenu = XGFiles.stringTable("name_entry_menu.msg")
		let system_tool = XGFiles.stringTable("system_tool.msg")
		let m3shrine1frl = XGFiles.stringTable("M3_shrine_1F_rl.msg")
		let relivehall_menu = XGFiles.stringTable("relivehall_menu.msg")
		let pda_menu = XGFiles.stringTable("pda_menu.msg")
		let p_exchange = XGFiles.stringTable("p_exchange.msg")
		let world_map = XGFiles.stringTable("world_map.msg")
		
		
		let pm = XGFiles.nameAndFolder("pcbox_pocket_menu.fsys",.MenuFSYS).fsysData.decompressedDataForFileWithIndex(index: 0)!
		pm.file = pocket_menu
		pm.save()
		
		let nem = XGFiles.nameAndFolder("pcbox_name_entry_menu.fsys",.MenuFSYS).fsysData.decompressedDataForFileWithIndex(index: 0)!
		nem.file = nameentrymenu
		nem.save()
		
		let st = XGFiles.nameAndFolder("pcbox_menu.fsys",.MenuFSYS).fsysData.decompressedDataForFileWithIndex(index: 0)!
		st.file = system_tool
		st.save()
		
		let m3rl = XGFiles.nameAndFolder("hologram_menu.fsys",.MenuFSYS).fsysData.decompressedDataForFileWithIndex(index: 0)!
		m3rl.file = m3shrine1frl
		m3rl.save()
		
		let rh = XGFiles.nameAndFolder("relivehall_menu.fsys",.MenuFSYS).fsysData.decompressedDataForFileWithIndex(index: 0)!
		rh.file = relivehall_menu
		rh.save()
		
		let pda = XGFiles.nameAndFolder("pda_menu.fsys",.MenuFSYS).fsysData.decompressedDataForFileWithIndex(index: 2)!
		pda.file = pda_menu
		pda.save()
		
		let pex = XGFiles.nameAndFolder("pokemonchange_menu.fsys",.MenuFSYS).fsysData.decompressedDataForFileWithIndex(index: 2)!
		pex.file = p_exchange
		pex.save()
		
		let wm = XGFiles.nameAndFolder("worldmap.fsys",.MenuFSYS).fsysData.decompressedDataForFileWithIndex(index: 1)!
		wm.file = world_map
		wm.save()
	}
	
	func extractStringTables() {
		extractAutoStringTables()
		extractSpecificStringTables()
		
	}
	
	func extractScripts() {
		for file in XGFolders.AutoFSYS.files {
			let fsys = file.fsysData
			let data = fsys.decompressedDataForFileWithIndex(index: 1)!
			data.file = .script(file.fileName.replacingOccurrences(of: ".fsys", with: ".scd"))
			data.save()
		}
	}
	
	func extractDOL() {
		let dol = dataForFile(filename: "Start.dol")!
		dol.file = .dol
		dol.save()
	}
	
	class func extractRandomiserFiles() {
		extractTOC()
		let iso = XGISO()
		iso.extractDOL()
		iso.extractFSYS()
		iso.extractMenuFSYS()
		iso.extractCommon()
		iso.extractDecks()
		iso.extractSpecificStringTables()
		
		// for pokespots
		for file in ["M2_guild_1F_2.fsys"] {
			let data = iso.dataForFile(filename: file)!
			data.file = XGFiles.nameAndFolder(file, .AutoFSYS)
			data.save()
		}
		
		iso.extractScripts()
	}
	
	 class func extractAllFiles() {
		extractTOC()
		let iso = XGISO()
		iso.extractDOL()
		iso.extractAllFSYS()
		iso.extractCommon()
		iso.extractDecks()
		iso.extractStringTables()
		iso.extractScripts()
	}
	
}



























































