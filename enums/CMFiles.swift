//
//  CMFiles.swift
//  Colosseum Tool
//
//  Created by The Steez on 07/06/2018.
//

import Foundation

func ==(lhs: XGFiles, rhs: XGFiles) -> Bool {
	return lhs.path == rhs.path
}
func !=(lhs: XGFiles, rhs: XGFiles) -> Bool {
	return lhs.path != rhs.path
}

var loadedFiles = [String : XGMutableData]()
var loadedStringTables = [String : XGStringTable]()

let loadableFiles = [XGFiles.common_rel.path,XGFiles.dol.path, XGFiles.iso.path,XGFiles.toc.path, XGFiles.fsys("people_archive").path, XGFiles.pocket_menu.path]
let loadableStringTables = [XGFiles.tableres2.path,XGFiles.msg("pocket_menu").path,XGFiles.common_rel.path,XGFiles.dol.path]

let compressionFolders = [XGFolders.Common, XGFolders.Textures, XGFolders.StringTables, XGFolders.Scripts, XGFolders.Rels]

let NullFSYS = XGMutableData(byteStream: [0x46, 0x53, 0x59, 0x53, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
										  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
										  0x00, 0x00, 0x00, 0x60, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
										  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
										  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
										  0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x4E, 0x55, 0x4C, 0x4C, 0x46, 0x53, 0x59, 0x53],
							 file: .fsys("Null"))

indirect enum XGFiles {
	
	case dol
	case common_rel
	case tableres2
	case pocket_menu
	case deck(XGDecks)
	case pokeFace(Int)
	case pokeBody(Int)
	case typeImage(Int)
	case trainerFace(Int)
	case msg(String)
	case fsys(String)
	case lzss(String)
	case scd(String)
	case xds(String)
	case texture(String)
	case rel(String)
	case ccd(String)
	case json(String)
	case iso
	case toc
	case log(Date)
	case wit
	case wimgt
	case tool(String)
	case nameAndFolder(String, XGFolders)
	
	var path : String {
		return folder.path + ("/" + self.fileName)
	}
	
	var fileName : String {
		switch self {

		case .dol					: return "Start" + XGFileTypes.dol.fileExtension
		case .common_rel			: return "common" + XGFileTypes.rel.fileExtension
		case .tableres2				: return "tableres2" + XGFileTypes.rel.fileExtension
		case .pocket_menu			: return "pocket_menu" + XGFileTypes.rel.fileExtension
		case .deck(let deck)		: return deck.fileName
		case .pokeFace(let id)		: return "face_" + String(format: "%03d", id) + XGFileTypes.png.fileExtension
		case .pokeBody(let id)		: return "body_" + String(format: "%03d", id) + XGFileTypes.png.fileExtension
		case .typeImage(let id)		: return "type_" + String(id) + XGFileTypes.png.fileExtension
		case .trainerFace(let id)	: return "trainer_" + String(id) + XGFileTypes.png.fileExtension
		case .msg(let s)			: return s + XGFileTypes.msg.fileExtension
		case .fsys(let s)			: return s + XGFileTypes.fsys.fileExtension
		case .lzss(let s)			: return s + XGFileTypes.lzss.fileExtension
		case .scd(let s)			: return s + XGFileTypes.scd.fileExtension
		case .xds(let s)			: return s + XGFileTypes.xds.fileExtension
		case .texture(let s)		: return s
		case .toc					: return "Game" + XGFileTypes.toc.fileExtension
		// windows doesn't support colons in file names
		case .log(let d)			: return d.description.replacingOccurrences(of: ":", with: ".") + XGFileTypes.txt.fileExtension
		case .rel(let s)			: return s + XGFileTypes.rel.fileExtension
		case .ccd(let s)			: return s + XGFileTypes.ccd.fileExtension
		case .json(let s)			: return s + XGFileTypes.json.fileExtension
		case .wit                 	: return environment == .Windows ? "wit.exe" :  "wit"
		case .wimgt					: return environment == .Windows ? "wimgt.exe" : "wimgt"
		case .tool(let s)			: return s + (environment == .Windows ? ".exe" : "")
		case .nameAndFolder(let name, _) : return name
		case .iso					: return (game == .Colosseum ? "Colosseum" : "XD") + XGFileTypes.iso.fileExtension
		}
	}
	
	var folder : XGFolders {
		get {
			var folder = XGFolders.Documents
			
			switch self {
				
			case .dol				: folder = .DOL
			case .common_rel		: folder = .Common
			case .tableres2			: folder = .Common
			case .pocket_menu		: folder = .Common
			case .deck				: folder = .Documents
			case .pokeFace			: folder = .PokeFace
			case .pokeBody			: folder = .PokeBody
			case .typeImage			: folder = .Types
			case .trainerFace		: folder = .Trainers
			case .msg		: folder = .StringTables
			case .lzss				: folder = .LZSS
			case .scd				: folder = .Scripts
			case .xds				: folder = .Documents
			case .texture			: folder = .Textures
			case .iso				: folder = .ISO
			case .toc				: folder = .Documents
			case .log				: folder = .Logs
			case .rel				: folder = .Rels
			case .ccd				: folder = .Col
			case .json				: folder = .JSON
            case .fsys              : if XGFolders.FSYS.filenames.contains(self.fileName) { folder = .FSYS}
                                      else if XGFolders.MenuFSYS.filenames.contains(self.fileName) { folder = .MenuFSYS}
                                      else {folder = .AutoFSYS}
			case .wit      		    : folder = .Wiimm
			case .wimgt      		: folder = .Wiimm
			case .tool				: folder = .Resources
			case .nameAndFolder( _, let aFolder) : folder = aFolder
				
			}
			
			return folder
		}
	}
	
	var text : String {
		return data!.string
	}
	
	var data : XGMutableData? {
		
		switch self {
		case .fsys("Null"): return NullFSYS
		default: break
		}

		if self != XGFiles.iso {
			let requiredFiles : [XGFiles] = [.common_rel, .dol, .pocket_menu, .msg("pocket_menu"), .fsys("people_archive")]
			if requiredFiles.contains(where: { (f) -> Bool in
				f == self
			}) {
				if !self.exists {
					XGISO.extractMainFiles()
				}
			}
		}
		
		if !self.exists && self != .toc {
			printg("file doesn't exist and couldn't be extracted:", self.path)
			return nil
		}
		
		
		var data : XGMutableData?
		if loadableFiles.contains(self.path) {
			
			if let data = loadedFiles[self.path] {
				return data
			}
		}
		
		if self == .toc {
			data = tocData
		} else {
			data = XGMutableData(contentsOfXGFile: self)
		}
		
		
		if loadableFiles.contains(self.path) {
			if let d = data {
				loadedFiles[self.path] = d
			}
		}
		
		return data
		
	}
	
	var exists : Bool {
		get {
			let fm = FileManager.default
			return fm.fileExists(atPath: self.path)
		}
	}
	
	var json : AnyObject {
		get {
			if self.exists,  let data = self.data?.data {
				return try! JSONSerialization.jsonObject(with: data as Data, options: JSONSerialization.ReadingOptions.mutableContainers) as AnyObject
			} else {
				printg("File doesn't exist: \(self.path)")
				return [String : String]() as AnyObject
			}
		}
	}
	
	var texture : GoDTexture {
		get {
			return GoDTexture(file: self)
		}
	}
	
	var fsysData : XGFsys {
		get {
			return XGFsys(file: self)
		}
	}
	
	var mapData : XGMapRel {
		get {
			return XGMapRel(file: self)
		}
	}
	
	func writeScriptData() { }
	
	var stringTable : XGStringTable {
		get {
			
			if loadableStringTables.contains(self.path) {
				if loadedStringTables[self.path] != nil {
					return loadedStringTables[self.path]!
				}
			}
			
			var table : XGStringTable!
			
			switch self {
			case .common_rel : table = XGStringTable.common_rel()
			case .tableres2  : table = XGStringTable.tableres2()!
			case .dol		 : table = XGStringTable.dol()
				
			default			 : table = XGStringTable(file: self, startOffset: 0, fileSize: self.fileSize)
			}
			
			if loadableStringTables.contains(self.path) {
				loadedStringTables[self.path] = table
			}
			
			return table
		}
	}

	var collisionData : XGCollisionData {
		return XGCollisionData(file: self)
	}

	var textures: [GoDTexture] {
		if XGFileTypes.textureFormats.contains(fileType) {
			return [texture]
		}
		if fileType == .gsw {
			return XGGSWTextures(file: self).extractTextureData().map { GoDTexture(data: $0) }
		}
		if XGFileTypes.modelFormats.contains(fileType) {
			#warning("extract textures from models colo/xd")
			return []
		}
		return []
	}
	
	var fileSize : Int {
		get {
			return self.data!.length
		}
	}
	
	func rename(_ name: String) {
		let fm = FileManager.default
		
		let newPath = self.folder.path + ("/" + name)
		do {
			try fm.moveItem(atPath: self.path, toPath: newPath)
		} catch _ {
		}
	}
	
	func delete() {
		let fm = FileManager.default
		
		var error : NSError?
		var isDirectory : ObjCBool = false
		let pathExists = fm.fileExists(atPath: self.path, isDirectory: &isDirectory)
		
		if pathExists {
			do {
				try fm.removeItem(atPath: self.path)
			} catch let error1 as NSError {
				error = error1
				printg(error!)
			}
		}
	}
	
	@discardableResult func compress() -> XGFiles {
		let outputFile = XGFiles.lzss(self.fileName)
		if self.exists, let data = self.data {
			let compressedData = XGLZSS.encode(data: data)
			compressedData.file = outputFile
			compressedData.save()
		}
		return outputFile
	}
	
	func compileMapFsys() {
		
		let baseName = self.fileName.removeFileExtensions()
		let fsysFile = XGFiles.nameAndFolder(baseName + XGFileTypes.fsys.fileExtension, .AutoFSYS)
		let rel = XGFiles.rel(baseName)
		let col = XGFiles.ccd(baseName)
		let scd = XGFiles.scd(baseName)
		let msg = XGFiles.msg(baseName)
		
		if fsysFile.exists {
			let fsys = fsysFile.fsysData
			printg("compiling \(baseName).fsys...")
			if rel.exists {
				fsys.shiftAndReplaceFile(rel.compress(), save: false)
			}
			if scd.exists {
				fsys.shiftAndReplaceFile(scd.compress(), save: false)
			}
			if msg.exists {
				fsys.shiftAndReplaceFile(msg.compress(), save: false)
			}
			if col.exists {
				fsys.shiftAndReplaceFile(col.compress(), save: true)
			}
			ISO.importFiles([fsysFile])
		}
		
	}
	
	func compileMenuFsys() {
		
		let baseName = self.fileName.removeFileExtensions()
		let fsysFile = XGFiles.nameAndFolder(baseName + XGFileTypes.fsys.fileExtension, .MenuFSYS)
		let rel = XGFiles.rel(baseName)
		let col = XGFiles.ccd(baseName)
		let scd = XGFiles.scd(baseName)
		
		if fsysFile.exists {
			let fsys = fsysFile.fsysData
			printg("compiling \(baseName).fsys...")
			if rel.exists {
				fsys.shiftAndReplaceFile(rel.compress(), save: false)
			}
			if scd.exists {
				fsys.shiftAndReplaceFile(scd.compress(), save: false)
			}
			if col.exists {
				fsys.shiftAndReplaceFile(col.compress(), save: true)
			}
			ISO.importFiles([fsysFile])
		}
		
	}
	
	var fileExtension : String {
		var ext = self.fileName.fileExtensions
		if ext.length > 0 {
			ext = ext.substring(from: 1, to: ext.length)
		}
		while ext.range(of: ".") != nil {
			if ext.length > 0 {
				ext = ext.fileExtensions
				if ext.length > 0 {
					ext = ext.substring(from: 1, to: ext.length)
				}
			} else {
				return ext
			}
		}
		return ext
	}
	
	var fileType : XGFileTypes {
		for i in 2 ..< 255 {
			if let type = XGFileTypes(rawValue: i) {
				if type.fileExtension == "." + self.fileExtension {
					return type
				}
			}
		}
		return .unknown
	}

	static var commonStringTableFile: XGFiles {
		.common_rel
	}
}


indirect enum XGFolders {
	
	case Documents
	case Common
	case DOL
	case JSON
	case StringTables
	case TextureImporter
	case Import
	case Export
	case Textures
	case Images
	case PokeFace
	case PokeBody
	case Trainers
	case Types
	case FSYS
	case LZSS
	case Scripts
	case Reference
	case Resources
	case Wiimm
	case ISO
	case AutoFSYS
	case MenuFSYS
	case Logs
	case Rels
	case Col
	case ISOExport(String)
	case path(String)
	case nameAndPath(String, String)
	case nameAndFolder(String, XGFolders)
	
	
	var name : String {
		get {
			switch self {
			case .Documents			: return "Documents"
			case .Common			: return "Common"
			case .DOL				: return "DOL"
			case .JSON				: return "JSON"
			case .StringTables		: return "String Tables"
			case .TextureImporter	: return "Texture Importer"
			case .Import			: return "Import"
			case .Export			: return "Export"
			case .Textures			: return "Textures"
			case .Images			: return "Images"
			case .PokeFace			: return "PokeFace"
			case .PokeBody			: return "PokeBody"
			case .Trainers			: return "Trainers"
			case .Types				: return "Types"
			case .FSYS				: return "FSYS"
			case .LZSS				: return "LZSS"
			case .Scripts			: return "Scripts"
			case .Reference			: return "Reference"
			case .Resources			: return "Resources"
			case .Wiimm				: return "Wiimm"
			case .ISO				: return "ISO"
			case .AutoFSYS			: return "AutoFSYS"
			case .MenuFSYS			: return "MenuFSYS"
			case .Logs				: return "Logs"
			case .Rels				: return "Relocatable Objects"
			case .Col				: return "Collision Data"
			case .ISOExport     	: return "ISO Export"
			case .path(let s) 		: return s
			case .nameAndPath(let s, _): return s
			case .nameAndFolder(let s, _): return s
				
			}
		}
	}
	
	var path : String {
		get {
			
			var path = documentsPath
			
			switch self {
				
			case .Documents	: return path
			case .nameAndPath(let name, let path): return path + "/\(name)"
			case .ISOExport(let folder): return path + "/" + self.name +
			(folder == "" ? "" : "/" + folder)
			case .Import	: path = XGFolders.TextureImporter.path
			case .Export	: path = XGFolders.TextureImporter.path
			case .Textures	: path = XGFolders.TextureImporter.path
			case .PokeFace	: path = XGFolders.Images.path
			case .PokeBody	: path = XGFolders.Images.path
			case .Trainers	: path = XGFolders.Images.path
			case .Types		: path = XGFolders.Images.path
			case .Wiimm		: path = XGFolders.Resources.path
			case .nameAndFolder(_, let f): path = f.path
			case .path(let s): return s
			default: break
				
			}
			
			return path + ("/" + self.name)
		}
	}
	
	var projectPath: String {
		return path.replacingOccurrences(of: documentsPath, with: "")
	}
	
	var filenames : [String] {
		get {
            let names = (try? FileManager.default.contentsOfDirectory(atPath: self.path))
            return names?.filter { $0.substring(from: 0, to: 1) != "." } ?? []
		}
	}
	
	var files : [XGFiles] {
		get {
			let fileNames = self.filenames
			var xgfs = [XGFiles]()
			
			for file in fileNames {
				let xgf = XGFiles.nameAndFolder(file, self)
				xgfs.append(xgf)
			}
			return xgfs
		}
	}
	
	var exists : Bool {
		get {
			let fm = FileManager.default
			return fm.fileExists(atPath: self.path)
		}
	}
	
	func createDirectory() {
		
		let fm = FileManager.default
		
		var error : NSError?
		var isDirectory : ObjCBool = false
		let path = self.path
		let pathExists = fm.fileExists(atPath: path, isDirectory: &isDirectory)
		
		if !pathExists {
			
			do {
				try fm.createDirectory(atPath: self.path, withIntermediateDirectories: true, attributes: nil)
			} catch let error1 as NSError {
				error = error1
			}
			
			let fileURL = URL(fileURLWithPath: self.path)
			do {
				try (fileURL as NSURL).setResourceValue(false, forKey: URLResourceKey.isExcludedFromBackupKey)
			} catch let error1 as NSError {
				error = error1
			}
            
            if let error = error {
                printg(error)
            }
			
		}
		
	}
	
	
	func map(_ function: ((_ file: XGFiles) -> Void) ) {
		
		let files = self.files
		
		for file in files {
			function(file)
		}
	}
	
	func empty() {
		self.map{ (file: XGFiles) -> Void in
			file.delete()
		}
	}
	
	static func setUpFolderFormat() {
		
		let folders : [XGFolders] = [
			.Documents,
			.Common,
			.DOL,
			.JSON,
			.StringTables,
			.TextureImporter,
			.Import,
			.Export,
			.Textures,
			.Images,
			.PokeFace,
			.PokeBody,
			.Trainers,
			.Types,
			.FSYS,
			.LZSS,
			.Scripts,
			.Reference,
			.Resources,
			.ISO,
			.AutoFSYS,
			.MenuFSYS,
			.Logs,
			.Rels,
			.Col,
			]
		
		for folder in folders {
			folder.createDirectory()
		}
		
		var images = [XGFiles]()
		for i in 0 ... 17 {
			images.append(.typeImage(i))
		}
		for i in 0 ... 414 {
			images.append(.pokeBody(i))
			images.append(.pokeFace(i))
		}
		for i in 0 ... 75 {
			images.append(.trainerFace(i))
		}
		images.append(.nameAndFolder("type_fairy.png", .Types))
		images.append(.nameAndFolder("type_shadow.png", .Types))
		
		for image in images {
			if !image.exists {
				var filename = ""
				switch image {
				case .trainerFace:
					filename = "colo_" + image.fileName
				default:
					filename = image.fileName
				}
				
				let resource = XGResources.png(filename.replacingOccurrences(of: ".png", with: ""))
                resource.copy(to: image)
			}
		}
		
		let jsons = ["Move Effects", "Original Pokemon", "Original Moves", "Move Categories", "Room IDs"]
		
		for j in jsons {
			let file = XGFiles.nameAndFolder(j + ".json", .JSON)
			if !file.exists {
                XGResources.JSON(j).copy(to: file)
			}
		}

		let wiimm = XGFolders.Wiimm
        if !wiimm.exists {
			XGResources.folder("wiimm").copy(to: XGFolders.Wiimm)
        }

		let gcitool = XGFiles.tool("gcitool")
		if !gcitool.exists {
			XGResources.tool("gcitool").copy(to: gcitool)
		}
	}
}


extension XGFolders: Codable {
	enum CodingKeys: String, CodingKey {
		case path
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let url = try container.decode(String.self, forKey: .path)
		self = .path(documentsPath + url)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		let path = self.path.replacingOccurrences(of: documentsPath, with: "")
		try container.encode(path, forKey: .path)
	}
}

extension XGFiles: Codable {
	enum CodingKeys: String, CodingKey {
		case name, folder
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		let name = try container.decode(String.self, forKey: .name)
		let folder = try container.decode(XGFolders.self, forKey: .folder)
		self = .nameAndFolder(name, folder)
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(fileName, forKey: .name)
		try container.encode(folder, forKey: .folder)
	}
}









