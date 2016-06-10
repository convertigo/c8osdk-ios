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
	public static var stateReplicate: DownloadState = DownloadState(description: "replicating")
	public static var stateAssembling: DownloadState = DownloadState(description: "assembling")
	public static var stateCleaning: DownloadState = DownloadState(description: "cleaning")
	public static var stateFinished: DownloadState = DownloadState(description: "finished")
	
	public class DownloadState {
		var description: String
		
		internal init (description: String) {
			self.description = description
			
		}
		
	}
	
	public var state: DownloadState {
		get {
			return self.state
		}
		set(value) {
			self.state = value
		}
	}
	
	public private(set) var uuid: String {
		get {
			return self.uuid
		}
		set(value) {
			self.uuid = value
		}
	}
	
	public private(set) var filepath: String {
		get {
			return self.filepath
		}
		set(value) {
			self.filepath = value
		}
	}
	
	public var current: Int {
		get {
			return self.current
		}
		
		set(value) {
			self.current = value
		}
	}
	
	public private(set) var total: Int {
		get {
			return self.total
		}
		set(value) {
			self.total = value
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
		
		let r = uuid.indexOf("-")
		
		let range: Range<String.Index> = uuid.rangeOfString("-")!
		
		total = Int(uuid.substringWithRange(range))!
	}
	
}
