//
//  C8oProgress.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

public class C8oProgress: NSObject {
	private var _changed: Bool? = false
	private var _continuous: Bool? = false
	private var _finished: Bool? = false
	private var _pull: Bool? = true
	private var _current: Int? = -1
	private var _total: Int? = -1
	private var _status: String? = ""
	private var _taskInfo: String? = ""
	private var _raw: NSObject?
	
	internal override init() {
		super.init()
		self._raw = nil
		
	}
	
	internal init(progress: C8oProgress) {
		super.init()
		_continuous = progress._continuous
		_finished = progress._finished
		_pull = progress._pull
		_current = progress._current
		_total = progress._total
		_status = progress._status
		_taskInfo = progress._taskInfo
		_raw = progress._raw
	}
	
	internal var changed: Bool {
		get {
			return _changed!
		}
		
		set(value) {
			_changed = value
		}
	}
	
	public override var description: String {
		var ch: String = direction + ": " + String(current) + "/" + String(total) + " ("
		ch += (finished ? (continuous ? "live" : "done") : "running") + ")"
		return ch
	}
	
	public var continuous: Bool {
		get {
			return _continuous!
		}
		
		set(value) {
			if (value != _continuous) {
				_changed = true
				_continuous = value
			}
		}
	}
	
	public var finished: Bool {
		get {
			return _finished!
		}
		
		set(value) {
			if (value != _finished) {
				_changed = true
				_finished = value
			}
		}
	}
	
	public var pull: Bool {
		get {
			return _pull!
		}
		
		set(value) {
			if (value != _pull) {
				_changed = true
				_pull = value
			}
		}
	}
	
	public var push: Bool {
		get {
			return !_pull!
		}
	}
	
	public var current: Int {
		get {
			return _current!
		}
		
		set(value) {
			if (value != _current) {
				_changed = true
				_current = value
			}
		}
	}
	
	public var total: Int {
		get {
			return _total!
		}
		
		set(value) {
			if (value != _total) {
				_changed = true
				_total = value
			}
		}
	}
	
	public var direction: String {
		get {
			return _pull! ?
			C8oFullSyncTranslator.FULL_SYNC_RESPONSE_VALUE_DIRECTION_PULL :
				C8oFullSyncTranslator.FULL_SYNC_RESPONSE_VALUE_DIRECTION_PUSH
		}
	}
	
	public var status: String {
		get {
			return _status!
		}
		
		set (value) {
			if (value != _status) {
				_changed = true
				_status = value
			}
		}
	}
	
	public var taskInfo: String {
		get {
			return _taskInfo!
		}
		
		set(value) {
			if (value != _taskInfo) {
				_changed = true
				_taskInfo = value
			}
		}
	}
	
	public var raw: NSObject {
		get {
			return _raw!
		}
		
		set(value) {
			if (value != _raw) {
				_changed = true
				_raw = value
			}
		}
	}
}
