//
//  XGPokemart.swift
//  GoD Tool
//
//  Created by The Steez on 01/11/2017.
//
//

import Cocoa

class XGPokemart: NSObject {
	
	var index = 0
	
	var items = [XGItems]()
	var firstItemIndex = 0
	var itemsStartOffset : Int {
		get {
			return PocketIndexes.MartItems.startOffset + (firstItemIndex * 2)
		}
	}
	
	init(index: Int) {
		super.init()
		
		let data = pocket.data!
		
		self.index = index
		self.firstItemIndex = data.get2BytesAtOffset(PocketIndexes.MartStartIndexes.startOffset + (index * 4) + 2)
		
		var nextItemOffset = itemsStartOffset
		var nextItem = data.get2BytesAtOffset(nextItemOffset)
		while nextItem != 0 {
			self.items.append(.item(nextItem))
			nextItemOffset += 2
			nextItem = data.get2BytesAtOffset(nextItemOffset)
		}
	}
	
	func save() {
		let data = pocket.data!
		data.replace2BytesAtOffset(PocketIndexes.MartStartIndexes.startOffset + (index * 4) + 2, withBytes: self.firstItemIndex)
		
		var nextItemOffset = itemsStartOffset
		for item in self.items {
			data.replace2BytesAtOffset(nextItemOffset, withBytes: item.index)
			nextItemOffset += 2
		}
		data.replace2BytesAtOffset(nextItemOffset, withBytes: 0)
		
		data.save()
	}

}





