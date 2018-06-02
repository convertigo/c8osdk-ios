//
//  C8oFileTransferStatus.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 17/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

open class C8oFileTransferStatus {
    open static let StateNotQueued: DownloadState = DownloadState.NotQueued
	open static let StateQueued: DownloadState = DownloadState.Queued
	open static let StateAuthenticated: DownloadState = DownloadState.Authenticated
	open static let StateSplitting: DownloadState = DownloadState.Splitting
	open static let StateReplicate: DownloadState = DownloadState.Replicate
	open static let StateAssembling: DownloadState = DownloadState.Assembling
	open static let StateCleaning: DownloadState = DownloadState.Cleaning
    open static let StateFinished: DownloadState = DownloadState.Finished
    open static let StateCanceled: DownloadState = DownloadState.Canceled
	
	public enum DownloadState: String {
        case NotQueued
		case Queued
		case Authenticated
		case Splitting
		case Replicate
		case Assembling
		case Cleaning
		case Finished
        case Canceled
	}
	
	fileprivate var _state: DownloadState? = nil
	fileprivate var _uuid: String? = ""
	fileprivate var _filepath: String? = ""
	fileprivate var _current: Int? = 0
	fileprivate var _total: Int? = 0
	fileprivate var _serverFilepath: String = ""
	fileprivate var _download: Bool? = nil
	
	open var state: DownloadState {
		get {
			return self._state!
		}
		set(value) {
			self._state = value
		}
	}
	
	open var download: Bool {
		get {
			return self._download!
		}
		set(value) {
			self._download = value
			if (value == true) {
				tot()
			}
		}
	}
	
	open fileprivate(set) var uuid: String {
		get {
			return self._uuid!
		}
		set(value) {
			self._uuid = value
		}
	}
	
	open var serverFilepath: String {
		get {
			return self._serverFilepath
		}
		set(value) {
			self._serverFilepath = value
		}
	}
	
	open fileprivate(set) var filepath: String {
		get {
			return self._filepath!
		}
		set(value) {
			self._filepath = value
		}
	}
	
	open var current: Int {
		get {
			return self._current!
		}
		
		set(value) {
			self._current = value
		}
	}
	
	open var total: Int {
		get {
			return self._total!
		}
		set(value) {
			self._total = value
		}
	}
	
	open var progress: Double {
		get {
			return total > 0 ? (Double(current) * 1.0 / Double(total)) : 0
		}
	}
	
	internal init (uuid: String, filepath: String) {
		self.state = C8oFileTransferStatus.StateNotQueued
		self.uuid = uuid
		
		self.filepath = filepath
		self.total = 0
	}
	func tot() {
		let range2: Range<String.Index> = uuid.range(of: "-", options: .backwards)!
		var start_index: Int = uuid.distance(from: uuid.startIndex, to: range2.lowerBound)
		start_index += 1
        self.total = Int(String(uuid[uuid.index(uuid.startIndex, offsetBy: start_index)..<uuid.endIndex]))!
	}
	
}
