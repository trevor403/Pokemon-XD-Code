//
//  XGScriptClass.swift
//  XGCommandLineTools
//
//  Created by StarsMmd on 21/05/2016.
//  Copyright © 2016 StarsMmd. All rights reserved.
//

import Foundation

enum XGScriptFunctionInfo {
	
	case operators(String,Int,Int)
	case unknownOperator(Int)
	case known(String,Int,Int,[XDSMacroTypes?]?, XDSMacroTypes?)
	case unknown(Int)
	
	var name : String {
		switch self {
			case .operators(let name,_,_)	: return name
			case .unknownOperator(let val)  : return "operator\(val)"
			case .known(let name,_,_,_,_)	: return name
			case .unknown(let val)			: return "function\(val)"
		}
	}
	
	var index : Int {
		switch self {
			case .operators(_,let val,_)	: return val
			case .unknownOperator(let val)	: return val
			case .known(_,let val,_,_,_)	: return val
			case .unknown(let val)			: return val
		}
	}
	
	var parameters : Int {
		switch self {
			case .operators(_,_,let val)	: return val
			case .unknownOperator(let val)  : return 0
			case .known(_,_,let val,_,_)	: return val
			case .unknown					: return 0
		}
	}
	
	var macros : [XDSMacroTypes?]? {
		switch self {
			case .operators				: return nil
			case .unknownOperator		: return nil
			case .known(_,_,_,let val,_): return val
			case .unknown				: return nil
		}
	}
	
	var returnMacro : XDSMacroTypes? {
		switch self {
			case .operators				: return nil
			case .unknownOperator		: return nil
			case .known(_,_,_,_,let val): return val
			case .unknown				: return nil
		}
	}
}

enum XGScriptClassesInfo {
	case operators
	case classes(Int)
	
	var name : String {
		switch self {
			case .operators			: return "Operator"
			case .classes(let val)	: return ScriptClassNames[val]?.capitalized ?? "Class\(val)"
		}
	}
	
	var index : Int {
		switch self {
			case .operators			: return -1
			case .classes(let val)	: return val
		}
	}
	
	subscript(id: Int) -> XGScriptFunctionInfo {
		
		switch self {
			case .operators			: return operatorWithID(id)
			case .classes			: return functionWithID(id)
		}
		
	}
	
	func operatorWithID(_ id: Int) -> XGScriptFunctionInfo {
		
		for (name,index,parameters) in ScriptOperators {
			if index == id {
				return .operators(name, index, parameters)
			}
			
		}
		
		// Hopefully shouldn't hit this case
		// All operators should be documented
		printg("Error: encountered unknown operator \(id)")
		return .unknownOperator(id)
	}
	
	func functionWithID(_ id: Int) -> XGScriptFunctionInfo {
		let info = ScriptClassFunctions[self.index]
		
		if info == nil {
			return .unknown(id)
		}
		
		for (name,index,parameters,macros, macro) in info! {
			if index == id {
				return .known(name, index, parameters, macros, macro)
			}
		}
		
		return .unknown(id)
	}
	
	func classDotFunction(_ id: Int) -> String {
		return self.name + "." + self[id].name
	}
	
	func functionWithName(_ name: String) -> XGScriptFunctionInfo? {
		
		let kMaxNumberOfXDSClassFunctions = 200 // theoretical limit is 0xffff but 200 is probably safe
		for i in 0 ..< kMaxNumberOfXDSClassFunctions {
			let info = self[i]
			if info.name.lowercased() == name.lowercased() {
				return info
			}
			
			// so old scripts can still refer to renamed functions by "function" + number
			if XGScriptFunctionInfo.unknown(i).name.lowercased() == name.lowercased() {
				return self[i]
			}
			
		}
		
		return nil
	}
	
	static func getClassNamed(_ name: String) -> XGScriptClassesInfo? {
		
		// so old scripts can still refer to renamed classes by "Class" + number
		if name.length > 5 {
			if name.substring(from: 0, to: 5) == "Class" {
				if let val = name.substring(from: 5, to: name.length).integerValue {
					if val < 127 {
						return XGScriptClassesInfo.classes(val)
					}
				}
			}
		}
		
		let kNumberOfXDSClasses = 127 // don't know the number but script variables allow up to 127
		for i in 0 ..< kNumberOfXDSClasses {
			let info = XGScriptClassesInfo.classes(i)
			if info.name.lowercased() == name.lowercased() {
				return info
			}
		}
		return nil
	}
	
}

























