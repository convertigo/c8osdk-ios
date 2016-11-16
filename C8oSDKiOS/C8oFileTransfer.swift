//
//  C8oFileTransfer.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 17/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import SwiftyJSON

public class C8oFileTransfer: C8oFileTransferBase {
	
	private var tasksDbCreated: Bool = false
	private var alive: Bool = true
	private var chunkSize = 1000 * 1024
	private var __maxRunning: Int = 4
	private var __maxRunning__: NSCondition = NSCondition()
	private var c8oTask: C8o
	private var tasks: Dictionary<String, C8oFileTransferStatus>? = nil
    private var canceledTasks: NSMutableSet = NSMutableSet()
	public var raiseTransferStatus: ((C8oFileTransfer, C8oFileTransferStatus) -> ())?
	public var raiseDebug: ((C8oFileTransfer, String) -> ())?
	public var raiseException: ((C8oFileTransfer, NSError) -> ())?
	private let condition: NSCondition = NSCondition()
	private var streamToUpload: Dictionary<String, NSInputStream>
	
	public convenience init(c8o: C8o) throws {
		try self.init(c8o: c8o, c8oFileTransferSettings: C8oFileTransferSettings())
	}
	
	public init(c8o: C8o, c8oFileTransferSettings: C8oFileTransferSettings) throws {
		c8oTask = try C8o(endpoint: c8o.endpointConvertigo + "/projects/" + c8oFileTransferSettings.projectName, c8oSettings: C8oSettings(c8oSettings: c8o).setDefaultDatabaseName(c8oFileTransferSettings.taskDb))
		__maxRunning = c8oFileTransferSettings.maxRunning
		streamToUpload = Dictionary<String, NSInputStream>()
		super.init()
		copy(c8oFileTransferSettings)
	}
	
	public func raiseTransferStatus(handler: (C8oFileTransfer, C8oFileTransferStatus) -> ()) -> C8oFileTransfer {
		self.raiseTransferStatus = handler
		return self
	}
	
	public func raiseDebug(handler: (C8oFileTransfer, String) -> ()) -> C8oFileTransfer {
		self.raiseDebug = handler
		return self
	}
	
	public func raiseException(handler: (C8oFileTransfer, NSError) -> ()) -> C8oFileTransfer {
		self.raiseException = handler
		return self
	}
	
	public func start() -> Void {
		if (tasks == nil) {
			tasks = Dictionary<String, C8oFileTransferStatus>()
			
			let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
			dispatch_async(dispatch_get_global_queue(priority, 0)) {
				do {
					try self.checkTaskDb()
				}
				catch let e as NSError {
					print(e.description)
				}
				var skip: Int = 0
				
				var param: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
				param["limit"] = 1
				param["include_docs"] = true
				
				while (self.alive) {
					do {
						param["skip"] = skip
						var res: JSON = try self.c8oTask.callJson("fs://.all", parameters: param).sync()!
						
						let rows: JSON = res["rows"]
						if (rows.count > 0) {
							let row: JSON = rows[0]
							var task: JSON = row["doc"]
							if (task == nil) {
								task = try self.c8oTask.callJson("fs://.get",
									parameters: "docid", row["id"].stringValue
								).sync()!
							}
							let uuid: String = task["_id"].stringValue
							var bUuid: Bool = false
							var Bdown: Bool = false
							var Bup: Bool = false
							if let _ = self.tasks!["uuid"] {
								bUuid = true
							}
							if let _ = task["download"].int {
								Bdown = true
							}
							if let _ = task["upload"].int {
								Bup = true
							}
							if (!bUuid && (Bdown || Bup)) {
								let filePath: String = task["filePath"].stringValue
								let transferStatus: C8oFileTransferStatus = C8oFileTransferStatus(uuid: uuid, filepath: filePath)
								self.tasks![uuid] = transferStatus
                                transferStatus.state = C8oFileTransferStatus.StateQueued
								self.notify(transferStatus)
                                
								if (Bdown) {
									transferStatus.download = true
									self.downloadFile(transferStatus, task: &task)
								}
								else if (Bup) {
									transferStatus.download = false
									self.uploadFile(transferStatus, task: &task)
								}
								skip = 0
							}
							else {
								skip = skip + 1
							}
						} else {
							self.condition.lock()
							self.condition.wait()
							skip = 0
							self.condition.unlock()
						}
					}
					catch _ as NSError {
						
					}
				}
			}
		}
	}
	
	private func checkTaskDb() throws {
		if (!tasksDbCreated) {
			try c8oTask.callJson("fs://.create").sync()
			tasksDbCreated = true
		}
	}
	
	public func downloadFile(uuid: String, filePath: String) throws {
		try checkTaskDb()
		c8oTask.callJson("fs://.post",
			parameters:
				"_id", uuid,
			"filePath", filePath,
			"replicated", false,
			"assembled", false,
			"remoteDeleted", false,
			"download", 0
		).then({ (response, parameters) -> (C8oPromise<JSON>?) in
			self.condition.lock()
			self.condition.signal()
			self.condition.unlock()
			return nil
		})
		
	}
	
	public func downloadFile(transferStatus: C8oFileTransferStatus, inout task: JSON) {
        let uuid = transferStatus.uuid
		var needRemoveSession: Bool = false
		var c8o: C8o? = nil
		
		do {
			__maxRunning__.lock()
			if (__maxRunning <= 0) {
				__maxRunning__.wait()
			}
			__maxRunning = __maxRunning - 1
			__maxRunning__.unlock()
			
			c8o = try C8o(endpoint: c8oTask.endpoint, c8oSettings: C8oSettings(c8oSettings: c8oTask).setFullSyncLocalSuffix("_" + uuid))
			var fsConnector: String? = nil
			
			//
			// 0 : Authenticates the user on the Convertigo server in order to replicate wanted documents
			//
			if (!task["replicated"].boolValue || !task["remoteDeleted"].boolValue) {
				needRemoveSession = true
				var json: JSON = try c8o!.callJson(".SelectUuid", parameters: "uuid", uuid).sync()!
				
				self.debug("SelectUuid:\n" + json["document"].description)
				if (json["document"]["selected"].stringValue != "true") {
					if (!task["replicated"].boolValue) {
						throw C8oException(message: "uuid not selected")
					}
				} else {
					fsConnector = json["document"]["connector"].stringValue
					transferStatus.state = C8oFileTransferStatus.StateAuthenticated
					self.notify(transferStatus)
				}
			}
			
			//
			// 1 : Replicate the document discribing the chunks ids list
			//
			
			if (!task["replicated"].boolValue && fsConnector != nil) {
				var locker: Bool
                let expireTransfer = NSDate(timeIntervalSinceNow: maxDurationForTransferAttempt)
				locker = false
				try c8o!.callJson("fs://" + fsConnector! + ".create").sync()!
				needRemoveSession = true
				let condition: NSCondition = NSCondition()
				
				c8o!.callJson("fs://" + fsConnector! + ".replicate_pull").then({ (response, parameters) -> (C8oPromise<JSON>?) in
					condition.lock()
					locker = true
					condition.signal()
					condition.unlock()
					return nil
				})
				
				transferStatus.state = C8oFileTransferStatus.StateReplicate
				notify(transferStatus)
				
				var allOptions: Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
				allOptions["startkey"] = uuid + "_"
				allOptions["endkey"] = uuid + "__"
				
				// Waits the end of the replication if it is not finished
				while (!locker && !canceledTasks.containsObject(uuid)) {
					do {
						condition.lock()
						
                        if (NSDate().compare(expireTransfer) == .OrderedDescending) {
                            locker = true
                            condition.unlock()
                            throw C8oException(message: "expireTransfer of " + maxDurationForTransferAttempt.description + " sec : retry soon")
                        } else {
                            condition.waitUntilDate(NSDate(timeIntervalSinceNow: 1))
                            condition.unlock()
                        }
												
						var all = try c8o?.callJson("fs://" + fsConnector! + ".all", parameters: allOptions).sync()
						let rows = all!["rows"]
						if (rows != nil) {
							let current: Int = rows.count
							if (current != transferStatus.current) {
								transferStatus.current = current
								self.notify(transferStatus)
							}
						}
					}
					catch let e as NSError {
                        notify(e)
						self.debug(e.description)
					}
				}
                
                try c8o?.callJson("fs://" + fsConnector! + ".replicate_pull", parameters: "cancel", true).sync()
                
                if (!canceledTasks.containsObject(uuid)) {
					if (transferStatus.current < transferStatus.total) {
						throw C8oException(message: "replication not completed")
					}
					
					task["replicated"] = true
					
					let res = try c8oTask.callJson("fs://.post",
						parameters:
							C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
						"_id", task["_id"].stringValue,
						"replicated", true
					).sync()!
					
					self.debug("replicated true:\n" + (res.description))
				}
			}
			
            let isCanceling = canceledTasks.containsObject(uuid)
            
			if (!task["assembled"].boolValue && fsConnector != nil && !isCanceling) {
				transferStatus.state = C8oFileTransferStatus.StateAssembling
				self.notify(transferStatus)
				//
				// 2 : Gets the document describing the chunks list
				//
				
				if let createdFileStream = NSOutputStream(toFileAtPath: transferStatus.filepath, append: false) { // (fileAtPath: transferStatus.filepath)
					createdFileStream.open()
					createdFileStream.scheduleInRunLoop(.mainRunLoop(), forMode: NSDefaultRunLoopMode)
					for i in 0..<transferStatus.total {
						let meta: JSON = try c8o!.callJson("fs://" + fsConnector! + ".get", parameters: "docid", uuid + "_" + String(i)).sync()!
						self.debug((meta.description))
						appendChunk(createdFileStream, contentPath: meta["_attachments"]["chunk"]["content_url"].stringValue)
					}
					createdFileStream.close()
				}
				
				task["assembled"] = true
				let res = try c8oTask.callJson("fs://.post",
					parameters: C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
					"_id", task["_id"].stringValue,
					"assembled", true
				).sync()!
				self.debug("assembled true:\n" + res.description)
			}
			
			if (!task["remoteDeleted"].boolValue && fsConnector != nil) {
				transferStatus.state = C8oFileTransferStatus.StateCleaning
				self.notify(transferStatus)
				
				var res = try c8o!.callJson("fs://" + fsConnector! + ".destroy").sync()
				self.debug("destroy local true:\n" + (res?.stringValue)!)
				
				needRemoveSession = true
				res = try c8o!.callJson(".DeleteUuid", parameters: "uuid", uuid).sync()!
				self.debug("deleteUuid:\n" + (res?.description)!)
				
				task["remoteDeleted"] = true
				
				res = try c8oTask.callJson("fs://.post",
					parameters:
						C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
					"_id", task["_id"].stringValue,
					"remoteDeleted", true
				).sync()!
				self.debug("remoteDeleted true:\n" + (res?.description)!)
			}
			
			if ((task["replicated"].boolValue && task["assembled"].boolValue && task["remoteDeleted"].boolValue) || isCanceling) {
				let res = try c8oTask.callJson("fs://.delete", parameters: "docid", uuid).sync()
				self.debug("local delete:\n" + (res?.description)!)
				
				transferStatus.state = C8oFileTransferStatus.StateFinished
				self.notify(transferStatus)
			}
            
            if (isCanceling) {
                transferStatus.state = C8oFileTransferStatus.StateCanceled
                notify(transferStatus)
                canceledTasks.removeObject(uuid)
            }
			finally(__maxRunning__)
		}
		catch let e as NSError {
			finally(__maxRunning__)
			self.notify(e)
		}
		
		if (needRemoveSession && c8o != nil) {
			c8o!.callJson(".RemoveSession")
		}
		
		tasks?.removeValueForKey(uuid)
		
		self.condition.lock()
		self.condition.signal()
		self.condition.unlock()
	}
	
	private func finally(cond: NSCondition) {
		cond.lock()
		__maxRunning = __maxRunning + 1
		cond.signal()
		cond.unlock()
	}
	
	private func appendChunk(outputStream: NSOutputStream, contentPath: String) -> Void {
		var str = contentPath
		let regex = try! NSRegularExpression(pattern: "^file://", options: .CaseInsensitive)
		str = regex.stringByReplacingMatchesInString(contentPath, options: [], range: NSRange(0..<str.utf16.count), withTemplate: "")
		let chunkStream = NSInputStream(fileAtPath: str)
		var buffer = [UInt8](count: chunkSize, repeatedValue: 0)
		chunkStream!.open()
		while chunkStream!.hasBytesAvailable {
			let count = chunkStream!.read(&buffer, maxLength: buffer.count)
            if (count > 0) {
                outputStream.write(&buffer, maxLength: count)
            }
		}
		chunkStream?.close()
	}
	
	private func notify(transferStatus: C8oFileTransferStatus) -> Void {
		if (raiseTransferStatus != nil) {
			raiseTransferStatus!(self, transferStatus)
			
		}
	}
	
	private func notify(exception: NSError) -> Void {
		if (raiseException != nil) {
			raiseException!(self, exception)
		}
	}
	
	private func debug(debug: String) -> Void {
		if (raiseDebug != nil) {
			raiseDebug!(self, debug)
		}
	}
	
	public func uploadFile(fileName: String, fileStream: NSInputStream) throws {
		
		// Creates the task database if it doesn't exist
		try self.checkTaskDb()
		
		// Initializes the uuid ending with the number of chunks
		
		let uuid: String = NSUUID().UUIDString.lowercaseString
		
		c8oTask.callJson("fs://.post", parameters:
				"_id", uuid,
			"filePath", fileName,
			"splitted", false,
			"replicated", false,
			"localDeleted", false,
			"assembled", false,
			"upload", 0
		).then { (response, parameters) -> (C8oPromise<JSON>?) in
			self.condition.lock()
			self.condition.signal()
			self.condition.unlock()
			return nil
		}
		streamToUpload[uuid] = fileStream
	}
	
    func uploadFile(transferStatus: C8oFileTransferStatus, inout task: JSON) {
        let uuid = transferStatus.uuid
		do {
			__maxRunning__.lock()
			if (__maxRunning <= 0) {
				__maxRunning__.wait()
			}
			__maxRunning = __maxRunning - 1
			__maxRunning__.unlock()
			
			var res: JSON = nil
            var locker: Bool = false
            let fileName: String = transferStatus.filepath
			
			// Creates a c8o instance with a specific fullsync local suffix in order to store chunks in a specific database
			let c8o: C8o = try C8o(endpoint: c8oTask.endpoint, c8oSettings: C8oSettings(c8oSettings: c8oTask).setFullSyncLocalSuffix("_" + uuid).setDefaultDatabaseName("c8ofiletransfer"))
			
			// Creates the local db
			try c8o.callJson("fs://.create").sync()
			
			// If the file is not already splitted and stored in the local database
			if (!task["splitted"].boolValue && !canceledTasks.containsObject(uuid)) {
				transferStatus.state = C8oFileTransferStatus.StateSplitting
				notify(transferStatus)
				
				// Checks if the stream is still stored
				if let _ = streamToUpload[uuid] {
					
				}
				else {
					// Removes the local database
					try c8o.callJson("fs://.reset").sync()
					// Removes the task doc
					try c8oTask.callJson("fs://.delete", parameters: "docid", uuid).sync()
					throw C8oException(message: "The file '" + task["filePath"].stringValue + "' can't be upload because it was stopped before the file content was handled")
					
				}
				var fileStream: NSInputStream? = nil
				//
				// 1 : Split the file and store it locally
				//
				fileStream = streamToUpload[uuid]
				// fileStream.reset
				var buffer = [UInt8](count: chunkSize, repeatedValue: 0)
				let uuid: String = uuid
				var countTot: Int = -1
				var read: Int = 1
				
				fileStream!.open()
				if fileStream!.hasBytesAvailable {
					while (read > 0) {
						countTot += 1
						read = fileStream!.read(&buffer, maxLength: buffer.count)
						let docid: String = uuid + "_" + countTot.description
						try c8o.callJson("fs://.post", parameters:
								"_id", docid,
							"fileName", fileName,
							"type", "chunk",
							"uuid", uuid
						).sync()
						
						let data = NSData(bytes: &buffer, length: read)
						try c8o.callJson("fs://.put_attachment", parameters:
								"docid", docid,
							"name", "chunk",
							"content_type", "application/octet-stream",
							"content", data
						).sync()
					}
				}
				
				transferStatus.total = countTot
				
				// Updates the state document in the c8oTask database
				task["splitted"] = true
				res = try c8oTask.callJson("fs://.post", parameters:
						C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
					"_id", task["_id"].stringValue,
					"splitted", task["splitted"].boolValue
				).sync()!
				debug("splitted true:\n" + res.description)
			}
			streamToUpload.removeValueForKey(uuid)
			
			// If the local database is not replecated to the server
			if (!task["replicated"].boolValue && !canceledTasks.containsObject(uuid)) {
				//
				// 2 : Authenticates
				//
				res = try c8o.callJson(".SetAuthenticatedUser", parameters: "userId", uuid).sync()!
				debug("SetAuthenticatedUser:\n" + res.description)
				
				transferStatus.state = C8oFileTransferStatus.StateAuthenticated
				notify(transferStatus)
				
				//
				// 3 : Replicates to server
				//
				
				transferStatus.state = C8oFileTransferStatus.StateReplicate
				notify(transferStatus)
				
				locker = false
				
				c8o.callJson("fs://.replicate_push")
					.then({ (response, parameters) -> (C8oPromise<JSON>?) in
						self.condition.lock()
						locker = true
						self.condition.signal()
						self.condition.unlock()
						return nil
				})
				
				// Waits the end of the replication if it is not finished
				
				while (!locker && !canceledTasks.containsObject(uuid)) {
					self.condition.lock()
					self.condition.wait()
					self.condition.unlock()
					
					// Asks how many documents are in the server database with this uuid
					let json: JSON = try c8o.callJson(".c8ofiletransfer.GetViewCountByUuid",
						parameters:
							"_use_key", uuid
					).sync()!
					
					let rows = json["document"]["couchdb_output"]["rows"]
					if (rows != nil) {
						let current: Int = rows[0]["value"].intValue
						if (current != transferStatus.current) {
							transferStatus.current = current
							notify(transferStatus)
						}
					}
				}
                
                try c8o.callJson("fs://.replicate_push", parameters: "cancel", true).sync()
                
                if (!canceledTasks.containsObject(uuid)) {
					// Updates the state document in the task database
					task["replicated"] = true
					res = try c8oTask.callJson("fs://.post", parameters:
							C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
						"_id", task["_id"].stringValue,
						"replicated", task["replicated"].boolValue
					).sync()!
					debug("replicated true:\n" + res.description)
				}
			}
			
			// If the local database containing chunks is not deleted
			locker = true
			if (!task["localdeleted"].boolValue) {
				transferStatus.state = C8oFileTransferStatus.StateCleaning
				notify(transferStatus)
				locker = false
				//
				// 4 : Delete the local database containing chunks
				//
				c8o.callJson("fs://.reset")
					.then({ (response, parameters) -> (C8oPromise<JSON>?) in
						task["localDeleted"] = true
						self.c8oTask.callJson("fs://.post", parameters:
								C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
							"_id", task["_id"].stringValue,
							"localDeleted", task["localDeleted"].boolValue
							
						).then({ (response, parameters) -> (C8oPromise<JSON>?) in
							self.debug("localDeleted true :\n" + response.description)
							return nil
						})
						self.condition.lock()
						locker = true
						self.condition.signal()
						self.condition.unlock()
						return nil
				})
				
			}
			
            let isCanceling = canceledTasks.containsObject(uuid)
            
			// If the file is not assembled in the server
			if (!task["assembled"].boolValue && !isCanceling) {
				transferStatus.state = C8oFileTransferStatus.StateAssembling
				notify(transferStatus)
				
				//
				// 5 : Request the server to assemble chunks to the initial file
				//
				res = try c8o.callJson(".StoreDatabaseFileToLocal", parameters:
						"uuid", uuid,
					"numberOfChunks", transferStatus.total
				).sync()!
				
				let document: JSON = res["document"]
				if (document["serverFilePath"] == nil) {
					throw C8oException(message: "Can't find the serverFilePath in JSON response : " + res.description)
				}
				let serverFilePath: String = document["serverFilePath"].stringValue
				task["assembled"] = true
				task["serverFilePath"] = JSON(serverFilePath)
				
				res = try c8oTask.callJson("fs://.post", parameters:
						C8o.FS_POLICY, C8o.FS_POLICY_MERGE,
					"_id", task["_id"].stringValue,
					"assembled", task["assembled"].boolValue,
					"serverFilePath", task["serverFilePath"].stringValue
				).sync()!
				
				debug("assembled true:\n" + res.description)
			}
            
            if (!isCanceling) {
			transferStatus.serverFilepath = task["serverFilePath"].stringValue
				
				// Waits the local database is deleted
				while (!locker) {
					self.condition.lock()
					self.condition.waitUntilDate(NSDate(timeIntervalSinceNow: 0.5))
					self.condition.unlock()
				}
            }
			
			//
			// 6 : Remove the task document
			//
			res = try c8oTask.callJson("fs://.delete", parameters:
					"docid", uuid
			).sync()!
			
			debug("local delete:\n" + res.description)
			
            if (isCanceling) {
                canceledTasks.removeObject(uuid)
                transferStatus.state = C8oFileTransferStatus.StateCanceled
            } else {
                transferStatus.state = C8oFileTransferStatus.StateFinished
            }
			notify(transferStatus)
			finally(__maxRunning__)
		}
		catch let e as NSError {
			finally(__maxRunning__)
            notify(e)
			print(e.description)
		}
	}
    
	public func getAllFiletransferStatus() -> Array<C8oFileTransferStatus> {
		var list = Array<C8oFileTransferStatus>()
		do {
			let res = try c8oTask.callJson("fs://.all", parameters: "include_docs", true).sync()
			let rows = res!["rows"]
			for (_, row) in rows {
				let task = row["doc"]
				let uuid = task["_id"].string!
				
				// If this document id is not already in the tasks list
				if (tasks![uuid] != nil) {
                    list.append(tasks![uuid]!)
				} else {
					let filePath = task["filePath"].string
					list.append(C8oFileTransferStatus(uuid: uuid, filepath: filePath!))
				}
			}
		} catch let e as NSError {
			print(e.description)
		}
		return list
	}
	
	public func cancelFiletransfer(filetransferStatus: C8oFileTransferStatus) -> Void {
		cancelFiletransfer(filetransferStatus.uuid)
	}
	
	public func cancelFiletransfer(uuid: String) -> Void {
		canceledTasks.addObject(uuid)
	}
	
	public func cancelFiletransfers() {
		for filetransferStatus in getAllFiletransferStatus() {
			cancelFiletransfer(filetransferStatus)
		}
	}
}
