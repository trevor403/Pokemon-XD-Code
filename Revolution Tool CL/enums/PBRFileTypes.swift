//
//  XGFileTypes.swift
//  GoD Tool
//
//  Created by The Steez on 18/11/2017.
//
//

import Foundation

enum XGFileTypes : Int {
	case none = 0x00
	
	case bin = 0x02 // binary data
	case sdr  = 0x04 // 3d model. PBR model format is documented in online forums and tool to convert to .obj exists
	case odr  = 0x06 // contains multiple textures
	case mdr  = 0x08 // contains multiple textures

	case gpd  = 0x0a // particle effects?
	case gtx  = 0x0c // texture
	
//	case gpd  = 0x10 // some kind of gfx
	case scd  = 0x12 // script data

	case fnt  = 0x16 // sometimes .fnt, sometimes .f3d (3d font)
	case msg  = 0x18 // string table
	case mnr = 0x1a // menu textures
	case esq  = 0x20 // effect sequence. gfx format

	case gfl = 0x24 // lighting effects?

	case dckp = 0x28 // pokemon deck
	case dckt = 0x2a // trainer deck
	case dcka = 0x2e // ai deck
	
	// all arbitrary values
	case fsys = 0xf0
	
	case json = 0xf4
	case txt  = 0xf5
	case lzss = 0xf6
	case bmp  = 0xf7
	case jpeg = 0xf8
	case png  = 0xf9
	case tex0 = 0xfa
	case xds  = 0xfb
	case toc  = 0xfc
	case dol  = 0xfd
	case iso  = 0xfe
	
	case unknown = 0xff

	// for gamecube compatibility
	case gsw = -2
	case atx = -4
	case rdat = -6
	case ccd = -8
	case dats = -10
	case gpt1 = -12
	case cam = -14
	case f3d = -16
	case pkx = -18
	case dat = -20

	
	var index : Int {
		return self.rawValue / 2
	}
	
	var fileExtension : String {
		switch self {
		case .none: return ".bin"
		case .bin: return ".bin"
		case .sdr : return ".sdr"
		case .odr : return ".odr"
		case .mdr : return ".mdr"
		case .gfl : return ".gfl"
		case .dckp: return ".pbin"
		case .dckt: return ".tbin"
		case .dcka: return ".abin"
		case .ccd : return ".ccd"
		case .msg : return ".msg"
		case .mnr: return ".mnr"
		case .fnt : return ".fnt"
		case .f3d : return ".f3d"
		case .scd : return ".scd"
		case .dats: return ".dats"
		case .gtx : return ".gtx"
		case .gpt1: return ".gpt1"
		case .cam : return ".cam"
		case .gpd : return ".gpd"
		case .esq : return ".esq"
		case .fsys: return ".fsys"
		case .iso : return ".iso"
		case .xds : return ".xds"
		case .dol : return ".dol"
		case .toc : return ".toc"
		case .png : return ".png"
		case .bmp : return ".bmp"
		case .jpeg: return ".jpeg"
		case .tex0: return ".tex0"
		case .lzss: return ".lzss"
		case .txt : return ".txt"
		case .json: return ".json"
		case .rdat: return ".rdat"
		case .gsw : return ".gsw"
		case .atx : return ".atx"
		case .pkx : return ".pkx"
		case .dat : return ".dat"
		case .unknown: return ".bin"
		}
	}

	#if canImport(Cocoa)
	static let imageFormats: [XGFileTypes] = [.png, .jpeg, .bmp]
	#else
	static let imageFormats: [XGFileTypes] = [.png]
	#endif

	static let textureFormats: [XGFileTypes] = [.gtx]
	static let modelFormats: [XGFileTypes] = [.sdr, .odr, .mdr]
	static let textureContainingFormats: [XGFileTypes] = [.sdr, .odr, .mdr, .mnr, .gpd, .gfl]
}


















