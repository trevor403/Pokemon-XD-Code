//
//  CMTrainerModels.swift
//  Colosseum Tool
//
//  Created by The Steez on 04/06/2018.
//

import Cocoa

let kNumberOfTrainerModels = 0x44

let kFirstTrainerPKXIdentifierOffset = region == .JP ? 0x359FA8 : 0x36d840 // in start.dol

enum XGTrainerModels : Int {
	
	case none	= 0x00
	
	case wes
	case ruby
	case sapphire
	case cipherPeonF
	case cipherPeonM1
	case verde
	case rosso
	case bluno
	case skrub
	case green
	case red
	case funOldLady
	case dakim
	case gonzap
	case mirorB
	case venus
	case nascour
	case newsCaster
	case stPerformer
	case eagun
	case vander
	case superTrainerM2
	case arth
	case superTrainerF1
	case ferma
	case reath
	case hunterM
	case folly
	case ladyInSuit
	case glassesMan
	case funOldMan
	case bodyBuilderF
	case bodyBuilderM
	case richBoy1
	case guy
	case lady1
	case riderF
	case willie
	case riderM
	case teacher
	case evice
	case snagem1
	case athleteF
	case athleteM
	case ein
	case chaserF1
	case chaserM1
	case rollerBoy
	case worker
	case rui
	case richBoy2
	case lady2
	case coolTrainerM
	case coolTrainerF
	case justy
	case bandanaGuy
	case researcher
	case hunterF
	case battlus
	case bodyBuilderM2
	case deepKing
	case chaserM2
	case eagun2
	case eagun3
	case superTrainerF2
	case fein
	case snagem2
	case snagem3
	case mirakleB
	case superTrainerM1
	case trinch
	case athey
	case trudly
	case cail
	case chaserF2
	
	var name : String {
		if self.rawValue == 0 {
			return "-"
		}
		return pkxFSYS!.fileName.removeFileExtensions()
	}
	
	var pkxModelIdentifier : UInt32 {
		let dol = XGFiles.dol.data
		return dol.get4BytesAtOffset(kFirstTrainerPKXIdentifierOffset + (self.rawValue * 12) + kModelDictionaryModelOffset)
	}
	
	var pkxFSYS : XGFsys? {
		return XGISO().getPKXModelWithIdentifier(id: self.pkxModelIdentifier)
	}
	
	var pkxData : XGMutableData? {
		let fsys = self.pkxFSYS
		
		if fsys != nil {
			return fsys!.decompressedDataForFileWithIndex(index: 0)
		}
		
		return nil
	}
	
	var getImage : NSImage {
		return XGFiles.trainerFace(self.rawValue).image
	}
	
	var dictionaryRepresentation: [String : AnyObject] {
		get {
			return ["Value" : self.rawValue as AnyObject]
		}
	}
	
	var readableDictionaryRepresentation: [String : AnyObject] {
		get {
			return ["Value" : self.name as AnyObject]
		}
	}
	
	
}