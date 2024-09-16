// StringMetric.swift by `autozimu`
// https://github.com/autozimu/StringMetric.swift

import Foundation

extension String {
	
	var length: Int {
		return count
	}
	
	/// Get Jaro-Winkler distance.
	///
	/// (Score is normalized such that 0 equates to no similarity and 1 is an exact match).
	///
	/// Reference <https://en.wikipedia.org/wiki/Jaro%E2%80%93Winkler_distance>
	/// - Parameter target: The target `String`.
	/// - Returns: The Jaro-Winkler distance between the receiver and `target`.
	public func jaroWinkler(_ target: String) -> Double {
		var stringOne = self
		var stringTwo = target
		if stringOne.count > stringTwo.count {
			stringTwo = self
			stringOne = target
		}
		
		let stringOneCount = stringOne.count
		let stringTwoCount = stringTwo.count
		
		if stringOneCount == 0 && stringTwoCount == 0 {
			return 1.0
		}
		
		let matchingDistance = stringTwoCount / 2
		var matchingCharactersCount: Double = 0
		var transpositionsCount: Double = 0
		var previousPosition = -1
		
		// Count matching characters and transpositions.
		for (i, stringOneChar) in stringOne.enumerated() {
			for (j, stringTwoChar) in stringTwo.enumerated() {
				if max(0, i - matchingDistance)..<min(stringTwoCount, i + matchingDistance) ~= j {
					if stringOneChar == stringTwoChar {
						matchingCharactersCount += 1
						if previousPosition != -1 && j < previousPosition {
							transpositionsCount += 1
						}
						previousPosition = j
						break
					}
				}
			}
		}
		
		if matchingCharactersCount == 0.0 {
			return 0.0
		}
		
		// Count common prefix (up to a maximum of 4 characters)
		let commonPrefixCount = min(max(Double(self.commonPrefix(with: target).count), 0), 4)
		
		let jaroSimilarity = (matchingCharactersCount / Double(stringOneCount) + matchingCharactersCount / Double(stringTwoCount) + (matchingCharactersCount - transpositionsCount) / matchingCharactersCount) / 3
		
		// Default is 0.1, should never exceed 0.25 (otherwise similarity score could exceed 1.0)
		let commonPrefixScalingFactor = 0.1
		
		return jaroSimilarity + commonPrefixCount * commonPrefixScalingFactor * (1 - jaroSimilarity)
	}
	
}
