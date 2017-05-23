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

extension String {
	static func IsNullOrEmpty(_ value: String?) -> Bool {
		return value == nil || value!.isEmpty
	}
}

extension String {
	static func IsNullOrWhiteSpace(_ value: String?) -> Bool {
		return IsNullOrEmpty(value) ||
		(value!.trimmingCharacters(in: CharacterSet.whitespaces)).length == 0
	}
}

extension String {
	var length: Int {
		return characters.count
	}
}

class _QueueItem<T> {
	let value: T!
	var next: _QueueItem?
	
	init(_ newvalue: T?) {
		self.value = newvalue
	}
}

/**
    A standard queue (FIFO - First In First Out). Supports simultaneous adding and removing, but only one item can be added at a time, and only one item can be removed at a time.
*/
open class Queue<T> {
	
	public typealias Element = T
	
	var _front: _QueueItem<Element>
	var _back: _QueueItem<Element>
	var count: Int
	
	public init () {
		// Insert dummy item. Will disappear when the first item is added.
		_back = _QueueItem(nil)
		_front = _back
		count = 0
	}
	
	// Add a new item to the back of the queue.
	open func enqueue (_ value: Element) {
		_back.next = _QueueItem(value)
        _back = _back.next!
        
		
		count += 1
	}
	
	// Return and remove the item at the front of the queue.
	open func dequeue () -> Element? {
		if let newhead = _front.next {
			_front = newhead
			count -= 1
			return newhead.value
		} else {
			return nil
		}
	}
	
	open func isEmpty() -> Bool {
		return _front === _back
	}
	open func Count() -> Int {
		return count
	}
}

extension String {
	
	func indexOf(_ target: String) -> Int? {
		if let range = self.range(of: target) {
			return characters.distance(from: startIndex, to: range.lowerBound)
		} else {
			return nil
		}
	}
	
	func lastIndexOf(_ target: String) -> Int? {
		if let range = self.range(of: target, options: .backwards) {
			return characters.distance(from: startIndex, to: range.lowerBound)
		} else {
			return nil
		}
	}
}

