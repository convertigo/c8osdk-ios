//
//  Queue.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 05/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import SwiftyJSON

internal class C8oJSON: Any {
	internal init() {
		myJSON = nil
	}
	internal var myJSON: JSON?
}

open class Pair<K , V>: NSObject {
	
	var key: K
	var value: V
	public init(key: K, value: V) {
		
		self.key = key
		self.value = value
		super.init()
	}
	
}

public struct Queue<T> {
    fileprivate var array = [T]()
    
    public var isEmpty: Bool {
        return array.isEmpty
    }
    
    public var count: Int {
        return array.count
    }
    
    public mutating func enqueue(_ element: T) {
        array.append(element)
    }
    
    public mutating func dequeue() -> T? {
        if isEmpty {
            return nil
        } else {
            return array.removeFirst()
        }
    }
    
    public var front: T? {
        return array.first
    }
}

extension String {
    
    static func IsNullOrWhiteSpace(_ value: String?) -> Bool {
        return IsNullOrEmpty(value) ||
            (value!.trimmingCharacters(in: CharacterSet.whitespaces)).length == 0
    }
	
    static func IsNullOrEmpty(_ value: String?) -> Bool {
        return value == nil || value!.isEmpty
    }
    
	func indexOf(_ target: String) -> Int? {
		if let range = self.range(of: target) {
			return distance(from: startIndex, to: range.lowerBound)
		} else {
			return nil
		}
	}
	
	func lastIndexOf(_ target: String) -> Int? {
		if let range = self.range(of: target, options: .backwards) {
			return distance(from: startIndex, to: range.lowerBound)
		} else {
			return nil
		}
	}
    
    var length: Int {
        return count
    }
}

