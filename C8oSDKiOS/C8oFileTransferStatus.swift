//
//  C8oFileTransferStatus.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 17/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

public class C8oFileTransferStatus {
	public static var stateQueued: DownloadState = DownloadState(description: "queued")
	public static var stateAuthenticated: DownloadState = DownloadState(description: "authenticated")
    public static var stateSplitting : DownloadState = DownloadState(description: "splitting")
	public static var stateReplicate: DownloadState = DownloadState(description: "replicating")
	public static var stateAssembling: DownloadState = DownloadState(description: "assembling")
	public static var stateCleaning: DownloadState = DownloadState(description: "cleaning")
	public static var stateFinished: DownloadState = DownloadState(description: "finished")
	
	public class DownloadState {
		public var description: String
		
		internal init (description: String) {
			self.description = description
			
		}
		
	}
    
    private var _state : DownloadState? = nil
    private var _uuid : String? = ""
    private var _filepath : String? = ""
    private var _current : Int? = 0
    private var _total : Int? = 0
    private var _serverFilepath : String = ""
    private var _download : Bool? = nil
    
	public var state: DownloadState {
		get {
			return self._state!
		}
		set(value) {
			self._state = value
		}
	}
	
    public var download : Bool{
        get{
            return self._download!
        }
        set(value){
            self._download = value
            if(value == true){
                tot()
            }
        }
    }
	public private(set) var uuid: String {
		get {
			return self._uuid!
		}
		set(value) {
			self._uuid = value
		}
	}
    public var serverFilepath : String{
        get{
            return self._serverFilepath
        }
        set(value){
            self._serverFilepath = value
        }
    }
	public private(set) var filepath: String {
		get {
			return self._filepath!
		}
		set(value) {
			self._filepath = value
		}
	}
	
	public var current: Int {
		get {
			return self._current!
		}
		
		set(value) {
			self._current = value
		}
	}
	
	public var total: Int {
		get {
			return self._total!
		}
		set(value) {
			self._total = value
		}
	}
	
	public var progress: Double {
		get {
			return total > 0 ? (Double(current) * 1.0 / Double(total)) : 0
		}
	}
	
	internal init (uuid: String, filepath: String) {
        self.state = C8oFileTransferStatus.stateQueued
        self.uuid = uuid
				
		self.filepath = filepath
        self.total = 0
    }
    func tot(){
        let range2 : Range<String.Index> = uuid.rangeOfString("-", options: .BackwardsSearch)!
        var start_index : Int = uuid.startIndex.distanceTo(range2.startIndex)
        start_index += 1
        self.total = Int(uuid.substringWithRange(Range<String.Index>(uuid.startIndex.advancedBy(start_index)..<uuid.endIndex)))!
    }
	
}
