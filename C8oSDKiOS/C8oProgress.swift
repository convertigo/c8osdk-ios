//
//  C8oProgress.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

@objc open class C8oProgress: NSObject {
    fileprivate var _changed: Bool? = false
    fileprivate var _continuous: Bool? = false
    fileprivate var _finished: Bool? = false
    fileprivate var _pull: Bool? = true
    fileprivate var _current: Int? = -1
    fileprivate var _total: Int? = -1
    fileprivate var _status: String? = ""
    fileprivate var _taskInfo: String? = ""
    fileprivate var _raw: NSObject?
    
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
    
    @objc open override var description: String {
        var ch: String = direction + ": " + String(current) + "/" + String(total) + " ("
        ch += (finished ? (continuous ? "live" : "done") : "running") + ")"
        return ch
    }
    
    @objc open var dictionary: NSDictionary {
        let di = ["continuous": continuous, "finished": finished, "pull": pull, "current": current, "total": total, "status": status, "taskInfo": taskInfo, "raw": raw, "description": description] as [String : Any];
        let nsDi = di as NSDictionary
        return nsDi
    }
    
    open var continuous: Bool {
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
    
    open var finished: Bool {
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
    
    open var pull: Bool {
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
    
    open var push: Bool {
        get {
            return !_pull!
        }
    }
    
    open var current: Int {
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
    
    open var total: Int {
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
    
    open var direction: String {
        get {
            return _pull! ?
                C8oFullSyncTranslator.FULL_SYNC_RESPONSE_VALUE_DIRECTION_PULL :
                C8oFullSyncTranslator.FULL_SYNC_RESPONSE_VALUE_DIRECTION_PUSH
        }
    }
    
    open var status: String {
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
    
    open var taskInfo: String {
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
    
    open var raw: NSObject {
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
