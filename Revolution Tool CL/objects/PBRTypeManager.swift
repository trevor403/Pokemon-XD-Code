//
//  PBRTypeManager.swift
//  Revolution Tool CL
//
//  Created by Stars Momodu on 11/07/2020.
//

import Foundation

class PBRTypeManager {

	private struct PBRTypeMatchup {
		let offensiveType: XGMoveTypes
		let defensiveType: XGMoveTypes
		let multiplier: Int
		let ignoredByForesight: Bool

		var data: [Int] {
			return [offensiveType.index, defensiveType.index, multiplier]
		}
	}

	static var typeMatchupDataDolOffset: Int? {
		guard let dol = XGFiles.dol.data else {
			printg("Dol file not found")
			return nil
		}

		let dataTableOffsetInstructionsStartOffset = 0x3be7c4 - kDolToRAMOffsetDifference
		let instruction1 = dol.getWordAtOffset(dataTableOffsetInstructionsStartOffset)
		let instruction2 = dol.getWordAtOffset(dataTableOffsetInstructionsStartOffset + 4)

		// use 0xFFF for first mask to remove the leading 8 in the offset.
		let dataTableRAMOffset = ((instruction1 & 0xFFF) << 16) + (instruction2 & 0xFFFF)

		let isInDataSection = dataTableRAMOffset >= 0x3e1e60
		let offsetDifference = isInDataSection ? kDolTableToRAMOffsetDifference : kDolToRAMOffsetDifference
		return Int(dataTableRAMOffset) - offsetDifference
	}

	private static var currentMatchupTable: [PBRTypeMatchup]? {
		guard let dol = XGFiles.dol.data, let startOffset = typeMatchupDataDolOffset else {
			printg("unable to get type matchups from dol")
			return nil
		}

		var matchups = [PBRTypeMatchup]()
		var currentOffset = startOffset
		var foresightFound = false

		while true {
			let byte0 = dol.getByteAtOffset(currentOffset)
			let byte1 = dol.getByteAtOffset(currentOffset + 1)
			let byte2 = dol.getByteAtOffset(currentOffset + 2)
			currentOffset += 3

			if byte0 == 0xFE {
				foresightFound = true
				continue
			}

			if byte0 == 0xFF {
				break
			}

			let offsensiveType = XGMoveTypes.type(byte0)
			let defensiveType  = XGMoveTypes.type(byte1)
			let multiplier = byte2
			let matchup = PBRTypeMatchup(offensiveType: offsensiveType, defensiveType: defensiveType, multiplier: multiplier, ignoredByForesight: foresightFound)
			matchups.append(matchup)
		}

		return matchups
	}

	@discardableResult
	static func updateTypeMatchupDolData(allowSizeIncrease: Bool) -> Bool {
		guard let dol = XGFiles.dol.data, let startOffset = typeMatchupDataDolOffset, let currentTable = currentMatchupTable else {
			return false
		}

		var newTable = [PBRTypeMatchup]()
		for offensiveType in XGMoveTypes.allValues {
			let data = PBRDataTableEntry.typeMatchups(index: offensiveType.index)

			for defensiveType in XGMoveTypes.allValues {
				let effectiveness = data.getByte(defensiveType.index)
				let effectivenessValue = XGEffectivenessValues(rawValue: effectiveness) ?? .neutral
				let ignoredByForesight = defensiveType == XGMoveTypes.ghost && (offensiveType == XGMoveTypes.normal || offensiveType == XGMoveTypes.fighting)

				if effectivenessValue.multiplier != XGEffectivenessValues.neutral.multiplier {
					let matchup = PBRTypeMatchup(offensiveType: offensiveType, defensiveType: defensiveType, multiplier: effectivenessValue.multiplier, ignoredByForesight: ignoredByForesight)
					newTable.append(matchup)
				}
			}
		}

		let oldSize = currentTable.count
		let newSize = newTable.count
		let sizeDifference = oldSize - newSize
		guard sizeDifference >= 0 || allowSizeIncrease else {
			printg("Error: New type matchup table is too large.\nTry setting more matchups to neutral.")
			return false
		}

		var currentOffset = startOffset
		for matchup in newTable.filter({ (matchup) -> Bool in !matchup.ignoredByForesight }) {
			dol.replaceBytesFromOffset(currentOffset, withByteStream: matchup.data)
			currentOffset += 3
		}

		// everything after this is ignored when foresight/odor sleuth are active
		dol.replaceBytesFromOffset(currentOffset, withByteStream: [0xFE, 0xFE, 0x00])
		currentOffset += 3

		for matchup in newTable.filter({ (matchup) -> Bool in matchup.ignoredByForesight }) {
			dol.replaceBytesFromOffset(currentOffset, withByteStream: matchup.data)
			currentOffset += 3
		}

		if sizeDifference > 0 {
			for _ in 0 ..< sizeDifference {
				// add extra dummy matchups so the size of the table doesn't decrease
				// prevents the size too large error if the table size decreases then increases again later
				let matchup = PBRTypeMatchup(offensiveType: .type(0xfd), defensiveType: .type(0xfd), multiplier: 0, ignoredByForesight: true)
				dol.replaceBytesFromOffset(currentOffset, withByteStream: matchup.data)
				currentOffset += 3
			}
		}

		// marks end of table
		dol.replaceBytesFromOffset(currentOffset, withByteStream: [0xFF, 0xFF, 0x00])

		dol.save()
		return true
	}

	static func moveTypeMatchupTableToDolOffset(_ offset: Int, increaseEntryNumberBy: Int? = nil) {

		guard let currentMatchups = currentMatchupTable else {
			printg("Couldn't move type matchups table because old table couldn't be found.")
			return
		}

		let dolSize = XGFiles.dol.fileSize
		guard offset < dolSize else {
			printg("Couldn't move type matchup table to offset \(offset.hexString()) as it's outside the dol file (\(dolSize.hexString()) bytes)")
			return
		}

		let isInDataSection = offset >= 0x3ddf60
		let offsetDifference = isInDataSection ? kDolTableToRAMOffsetDifference : kDolToRAMOffsetDifference
		let RAMOffset = UInt32(offset + offsetDifference) + 0x80000000

		let offsetUpperHalf = Int(RAMOffset >> 16)
		let offsetLowerHalf = Int(RAMOffset & 0xFFFF)

		let r4Offsets: [UInt32] = [0x803be7c4, 0x803be804, 0x803be830, 0x803be870] // in RAM
		for offset in r4Offsets {
			let adjustedOffset = Int(offset - 0x80000000) - kDolToRAMOffsetDifference
			XGAssembly.replaceASM(startOffset: adjustedOffset, newASM: [
				.lis(.r4, offsetUpperHalf),
				.addi(.r4, .r4, offsetLowerHalf)
			])
		}

		let r4OffsetsWithGap: [UInt32] = [0x803bf834] // in RAM
		for offset in r4OffsetsWithGap {
			let adjustedOffset = Int(offset - 0x80000000) - kDolToRAMOffsetDifference
			XGAssembly.replaceASM(startOffset: adjustedOffset, newASM: [
				.lis(.r4, offsetUpperHalf),
			])
			XGAssembly.replaceASM(startOffset: adjustedOffset + 8, newASM: [
				.addi(.r4, .r4, offsetLowerHalf)
			])
		}

		let r7OffsetsWithGap: [UInt32] = [0x803bf874] // in RAM
		for offset in r7OffsetsWithGap {
			let adjustedOffset = Int(offset - 0x80000000) - kDolToRAMOffsetDifference
			XGAssembly.replaceASM(startOffset: adjustedOffset, newASM: [
				.lis(.r7, offsetUpperHalf),
			])
			XGAssembly.replaceASM(startOffset: adjustedOffset + 8, newASM: [
				.addi(.r7, .r7, offsetLowerHalf)
			])
		}

		let r17OffsetsWithGap: [UInt32] = [0x803beaa4, 0x803bef28] // in RAM
		for offset in r17OffsetsWithGap {
			let adjustedOffset = Int(offset - 0x80000000) - kDolToRAMOffsetDifference
			XGAssembly.replaceASM(startOffset: adjustedOffset, newASM: [
				.lis(.r17, offsetUpperHalf),
			])
			XGAssembly.replaceASM(startOffset: adjustedOffset + 8, newASM: [
				.addi(.r17, .r17, offsetLowerHalf)
			])
		}

		// should have probably left a comment as to why this is commented out
		// guessing it isn't needed
//		let r30OffsetsWithJump: [UInt32] = [0x803c618c, 0x803c72f4] // in RAM
//		for offset in r30OffsetsWithJump {
//			let adjustedOffset = Int(offset - 0x80000000) - kDolToRAMOffsetDifference
//			XGAssembly.replaceASM(startOffset: adjustedOffset, newASM: [
//				.lis(.r30, offsetUpperHalf),
//			])
//			XGAssembly.replaceASM(startOffset: adjustedOffset + 0x2c, newASM: [
//				.addi(.r30, .r30, offsetLowerHalf)
//			])
//		}

		// copy old data to new location, possibly with extra space

		guard let dol = XGFiles.dol.data else {
			return
		}

		var currentOffset = offset
		for matchup in currentMatchups.filter({ (matchup) -> Bool in !matchup.ignoredByForesight }) {
			dol.replaceBytesFromOffset(currentOffset, withByteStream: matchup.data)
			currentOffset += 3
		}

		dol.replaceBytesFromOffset(currentOffset, withByteStream: [0xFE, 0xFE, 0x00])
		currentOffset += 3

		for matchup in currentMatchups.filter({ (matchup) -> Bool in matchup.ignoredByForesight }) {
			dol.replaceBytesFromOffset(currentOffset, withByteStream: matchup.data)
			currentOffset += 3
		}

		for _ in 0 ..< (increaseEntryNumberBy ?? 0) {
			// add extra dummy matchups to increase the size of the table
			let matchup = PBRTypeMatchup(offensiveType: .type(0xfd), defensiveType: .type(0xfd), multiplier: 0, ignoredByForesight: true)
			dol.replaceBytesFromOffset(currentOffset, withByteStream: matchup.data)
			currentOffset += 3
		}

		dol.replaceBytesFromOffset(currentOffset, withByteStream: [0xFF, 0xFF, 0x00])
		currentOffset += 3

		dol.save()
	}
}
