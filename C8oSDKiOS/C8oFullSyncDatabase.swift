//
//  C8oFullSyncDatabase.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 23/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import CouchbaseLite.All

open class C8oFullSyncDatabase: NSObject {
	
	fileprivate static let AUTHENTICATION_COOKIE_NAME: String = "SyncGatewaySession"
	
	fileprivate var c8o: C8o
	
	fileprivate var databaseName: String
	
	fileprivate var c8oFullSyncDatabaseUrl: URL
	
	fileprivate var database: CBLDatabase? = nil
	
	fileprivate var pullFullSyncReplication: FullSyncReplication? = FullSyncReplication(pull: true)
	
	fileprivate var pushFullSyncReplication: FullSyncReplication? = FullSyncReplication(pull: false)
	
	public init (c8o: C8o, manager: CBLManager, databaseName: String, fullSyncDatabases: String, localSuffix: String) throws {
		var databaseNameMutable = databaseName
		self.c8o = c8o
		c8oFullSyncDatabaseUrl = NSURL(string: fullSyncDatabases + databaseNameMutable)! as URL
		
		databaseNameMutable = databaseNameMutable + localSuffix
		self.databaseName = databaseNameMutable
		super.init()
		var blockerror: C8oException? = nil
		
		do {
			var er: NSError? = nil
			(c8o.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
				do {
                    
                    let options = CBLDatabaseOptions()
                    options.create = true
                    if (c8o.fullSyncEncryptionKey != nil) {
                        options.encryptionKey = c8o.fullSyncEncryptionKey!
                    }
                    if (C8o.FS_STORAGE_SQL == c8o.fullSyncStorageEngine) {
                        options.storageType = kCBLSQLiteStorage
                    } else {
                        options.storageType = kCBLForestDBStorage
                    }
                    self.database = try manager.openDatabaseNamed(databaseNameMutable, with: options)
				}
				catch let e as NSError {
					er = e
				}
				
			}
			if (er != nil) {
				throw er!
			}
			
		}
		catch let e as NSError {
			blockerror = C8oException(message: C8oExceptionMessage.unableToGetFullSyncDatabase(self.databaseName), exception: e)
		}
		
		if (blockerror != nil) {
			throw blockerror!
		}
		
	}
	
    func deleteDb() {
        if (database != nil) {
            do {
                try database!.delete()
            } catch let e as NSError {
                c8o.log._debug("Failed to close DB: " + e.description)
            }
            database = nil
        }
    }
    
    fileprivate func createReplication(_ fsReplication: FullSyncReplication?) -> CBLReplication {
        var replication: CBLReplication? = nil
        
        fsReplication!.replication = fsReplication!.pull ? self.database?.createPullReplication(self.c8oFullSyncDatabaseUrl) : self.database?.createPushReplication(self.c8oFullSyncDatabaseUrl)
        replication = fsReplication!.replication!
        
        for cookie in c8o.cookieStore.cookies! {
            let date = Date(timeInterval: 3600, since: Date())
            replication!.setCookieNamed(cookie.name, withValue: cookie.value, path: cookie.path, expirationDate: date, secure: cookie.isSecure)
        }
        
        return replication!
    }
    
    fileprivate func stopReplication(_ fsReplication: FullSyncReplication?) {
        if (fsReplication?.replication != nil) {
            fsReplication!.replication!.stop()
            if (fsReplication?.changeListener != nil) {
                fsReplication?.replication?.removeObserver(self, forKeyPath: c8oFullSyncDatabaseUrl.absoluteString) // (c8oFullSyncDatabaseUrl)
                fsReplication?.changeListener = nil
            }
            fsReplication?.replication = nil
        }
    }
    
	fileprivate func getReplication(_ fsReplication: FullSyncReplication?) -> CBLReplication {
		stopReplication(fsReplication)
		let replication: CBLReplication? = createReplication(fsReplication)
		return replication!
		
	}
	
	open func startAllReplications(_ parameters: Dictionary<String, Any>, c8oResponseListener: C8oResponseListener) throws {
		try! startPullReplication(parameters, c8oResponseListener: c8oResponseListener)
		try! startPushReplication(parameters, c8oResponseListener: c8oResponseListener)
	}
	
	open func startPullReplication(_ parameters: Dictionary<String, Any>, c8oResponseListener: C8oResponseListener) throws {
		try! startReplication(pullFullSyncReplication!, parameters: parameters, c8oResponseListener: c8oResponseListener)
	}
	
	open func startPushReplication(_ parameters: Dictionary<String, Any>, c8oResponseListener: C8oResponseListener) throws {
		try! startReplication(pushFullSyncReplication!, parameters: parameters, c8oResponseListener: c8oResponseListener)
	}
	
	fileprivate func startReplication(_ fullSyncReplication: FullSyncReplication, parameters: Dictionary<String, Any>, c8oResponseListener: C8oResponseListener?) throws {
		var continuous: Bool = false
		var cancel: Bool = false
		
		if let _ = parameters["continuous"] {
			if (parameters["continuous"] as! Bool == true) {
				continuous = true
			} else {
				continuous = false
			}
		}
		
		if let _ = parameters["cancel"] {
			if (parameters["cancel"] as! Bool == true) {
				cancel = true
			} else {
				cancel = false
			}
		}
        
        let rep = self.getReplication(fullSyncReplication)
        let progress: C8oProgress = C8oProgress()
        progress.raw = rep
        progress.pull = rep.pull
		
		if (cancel) {
            stopReplication(fullSyncReplication)
            progress.finished = true;
            
            if let _ = c8oResponseListener as? C8oResponseProgressListener, c8oResponseListener != nil {
                (c8oResponseListener as! C8oResponseProgressListener).onProgressResponse(progress, parameters)
            }
			return
		}
		
		var param = parameters
		var _progress: [C8oProgress] = [progress]
		
		var count = false
		NotificationCenter.default.addObserver(forName: NSNotification.Name.cblReplicationChange, object: rep, queue: nil, using: { _ in
            if (count) {
				progress.total = rep.changesCount.hashValue
				progress.current = rep.completedChangesCount.hashValue
				progress.taskInfo = ("n/a")
                switch (rep.status) {
                case .active:
                    progress.status = "Active"
                    break
                case .idle:
                    progress.status = "Idle"
                    break
                case .offline:
                    progress.status = "Offline"
                    break
                case .stopped:
                    progress.status = "Stopped"
                    break
                }
				progress.finished = !(rep.status == CBLReplicationStatus.active)
				
				if (progress.changed) {
					_progress[0] = C8oProgress(progress: progress)
					if let _ = c8oResponseListener as? C8oResponseProgressListener, c8oResponseListener != nil {
						param[C8o.ENGINE_PARAMETER_PROGRESS] = progress
						(c8oResponseListener as! C8oResponseProgressListener).onProgressResponse(progress, param)
					}
					
				}
				
				if (progress.finished) {
					self.stopReplication(fullSyncReplication)
					if (continuous) {
						let replication: CBLReplication = self.getReplication(fullSyncReplication)
						_progress[0].raw = replication
						_progress[0].continuous = true
						replication.continuous = true
						NotificationCenter.default.addObserver(forName: NSNotification.Name.cblReplicationChange, object: replication, queue: nil, using: { _ in
							let progress: C8oProgress = _progress[0]
							progress.total = replication.changesCount.hashValue
							progress.current = replication.completedChangesCount.hashValue
							progress.taskInfo = "n/a"
							progress.status = String(describing: replication.status)
							if (progress.changed) {
								_progress[0] = C8oProgress(progress: progress)
								if let _ = c8oResponseListener as? C8oResponseProgressListener, c8oResponseListener != nil {
									param[C8o.ENGINE_PARAMETER_PROGRESS] = progress
									(c8oResponseListener as! C8oResponseProgressListener).onProgressResponse(progress, param)
								}
							}
							
						})
						
						replication.start()
						
					}
				}
			}
			count = true
		})
		(c8o.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
			rep.start()
		}
	}
	
	func replicationProgress(_ n: Notification) {
		
		// fullSyncReplication.changeListener
		// let active = pullFullSyncReplication?.replication?.status == CBLReplicationStatus.Active || pushFullSyncReplication?.replication?.status == CBLReplicationStatus.Active
	}
		
	open func getDatabaseName() -> String { return self.databaseName }
	
	open func getDatabase() -> CBLDatabase? { return self.database }
	
	fileprivate class FullSyncReplication {
		var replication: CBLReplication?
		var changeListener: NSObject?
		var pull: Bool
		
		fileprivate init(pull: Bool) {
			self.pull = pull
		}
	}
}
