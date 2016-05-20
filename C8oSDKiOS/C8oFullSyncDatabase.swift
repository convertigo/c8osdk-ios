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

public class C8oFullSyncDatabase : NSObject {
    
    private static let AUTHENTICATION_COOKIE_NAME : String = "SyncGatewaySession"
    
    private var c8o : C8o
    
    private var databaseName : String
    
    private var c8oFullSyncDatabaseUrl : NSURL
    
    private var database : CBLDatabase? = nil
    
    private var pullFullSyncReplication : FullSyncReplication? = FullSyncReplication(pull: true)
    
    private var pushFullSyncReplication : FullSyncReplication? = FullSyncReplication(pull: false)
    
    public init (c8o : C8o, manager : CBLManager, databaseName : String, fullSyncDatabases : String, localSuffix : String)throws{
        var databaseNameMutable = databaseName
        self.c8o = c8o
        do{
            c8oFullSyncDatabaseUrl = try NSURL(string: fullSyncDatabases + databaseNameMutable)!
        }
        catch let e as NSError{
            throw C8oException(message: C8oExceptionMessage.illegalArgumentInvalidFullSyncDatabaseUrl(fullSyncDatabases + databaseName + "/"), exception: e)
        }
        
        databaseNameMutable = databaseNameMutable + localSuffix
        self.databaseName = databaseNameMutable
        super.init()
        var blockerror : C8oException? = nil
        
        
        do{
            var er : NSError? = nil
            (c8o.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
                do{
                    self.database = try manager.databaseNamed(databaseNameMutable)
                }
                catch let e as NSError{
                    er = e
                }
                
            }
            if(er != nil){
                throw er!
            }
            
            
        }
        catch let e as NSError{
            blockerror =  C8oException(message: C8oExceptionMessage.unableToGetFullSyncDatabase(self.databaseName) , exception: e)
        }
        
        if(blockerror != nil){
            throw blockerror!
        }
        
    }
    
    private func getReplication(fsReplication : FullSyncReplication?)-> CBLReplication{
        
        if(fsReplication?.replication != nil){
            fsReplication!.replication!.stop()
            if(fsReplication?.changeListener != nil){
                
                fsReplication?.replication?.removeObserver(self, forKeyPath: c8oFullSyncDatabaseUrl.absoluteString)//(c8oFullSyncDatabaseUrl)
            }
        }
        var replication : CBLReplication? =  nil
        
        fsReplication!.replication = fsReplication!.pull ? self.database?.createPullReplication(self.c8oFullSyncDatabaseUrl) : self.database?.createPushReplication(self.c8oFullSyncDatabaseUrl)
        replication  = fsReplication!.replication!
        
        
        
        for cookie in c8o.cookieStore.cookies!{
            replication!.setCookieNamed(cookie.name, withValue: cookie.value, path: cookie.path, expirationDate: cookie.expiresDate, secure: cookie.secure)
        }
        
        return replication!
        
    }
    
    public func startAllReplications(parameters : Dictionary<String, AnyObject>, c8oResponseListener : C8oResponseListener)throws{
        try! startPullReplication(parameters, c8oResponseListener: c8oResponseListener)
        try! startPushReplication(parameters, c8oResponseListener: c8oResponseListener)
    }
    
    public func startPullReplication(parameters : Dictionary<String, AnyObject>, c8oResponseListener : C8oResponseListener)throws{
        try! startReplication(pullFullSyncReplication!, parameters: parameters, c8oResponseListener: c8oResponseListener)
    }
    
    public func startPushReplication(parameters : Dictionary<String, AnyObject>, c8oResponseListener : C8oResponseListener)throws{
        try! startReplication(pushFullSyncReplication!, parameters: parameters, c8oResponseListener: c8oResponseListener)
    }
    
    private func startReplication(fullSyncReplication : FullSyncReplication, parameters : Dictionary<String, AnyObject>, c8oResponseListener : C8oResponseListener?) throws {
        var continuous : Bool = false
        var cancel : Bool = false
        
        if let _ = parameters["continuous"]{
            //if(String(parameters["continuous"]).caseInsensitiveCompare("true") == NSComparisonResult.OrderedSame){
            if(parameters["continuous"] as! Bool == true){
                continuous = true
            }
            else{
                continuous = false
            }
        }
        
        if let _ = parameters["cancel"]{
            if(String(parameters["cancel"]).caseInsensitiveCompare("true") == NSComparisonResult.OrderedSame){
                cancel = true
            }
            else{
                cancel = false
            }
        }
        var rep : CBLReplication?
        
        
        rep = self.getReplication(fullSyncReplication)
        
        
        if(cancel){
            if(rep != nil)
            {
                
                rep!.stop()
                
                
            }
            return
        }
        
        var param : Dictionary<String, AnyObject> = parameters
        var progress : C8oProgress = C8oProgress()
        var _progress : [C8oProgress] = [progress]
        progress.raw = rep!
        progress.pull = rep!.pull
        
        let thread = NSThread.currentThread()
        var syncMutex : [Bool] = [Bool]()
        syncMutex.append(false)
        var count = false
        let condition : NSCondition = NSCondition()
        NSNotificationCenter.defaultCenter().addObserverForName(kCBLReplicationChangeNotification, object: rep!, queue : nil , usingBlock: { _ in
            if(count){
            progress.finished = !(rep!.status == CBLReplicationStatus.Active)
            progress.total = rep!.changesCount.hashValue
            progress.current = rep!.completedChangesCount.hashValue
            progress.taskInfo = ("n/a")
            progress.status = String(rep!.status)
                
            
            if(progress.finished){
                if(NSThread.currentThread() == thread){
                    syncMutex[0] = true
                }
                else{
                    //syncMutex[0] = true
                    condition.lock()
                    condition.signal()
                    condition.unlock()
                }
                
            }
            
            if(progress.changed){
                _progress[0] = C8oProgress(progress: progress)
                if let _ = c8oResponseListener as? C8oResponseProgressListener where c8oResponseListener != nil{
                    param[C8o.ENGINE_PARAMETER_PROGRESS] = progress
                    (c8oResponseListener as! C8oResponseProgressListener).onProgressResponse(progress, param)
                }
                
            }
            }
            count = true
            
        })
        
        
        
        condition.lock()
        (c8o.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            rep!.start()
        }
        
        
        if(!syncMutex[0]){
            condition.wait()
        }
        (c8o.c8oFullSync as! C8oFullSyncCbl).performOnCblThread {
            rep!.stop()
        }
        
        condition.unlock()
        
        
        if(continuous){
            progress = _progress[0]
            let lastCurrent : Int = progress.current
            var stat = [0]
            let replication : CBLReplication = getReplication(fullSyncReplication)
            progress.raw = replication
            progress.continuous =  true
            replication.continuous = true
            NSNotificationCenter.defaultCenter().addObserverForName(kCBLReplicationChangeNotification, object: pushFullSyncReplication?.replication, queue : nil, usingBlock: {_ in
                let total = rep?.changesCount
                if(stat[0] == 0){
                    if(lastCurrent == 0 || total>0){
                        stat[0] = 1
                    }
                }
                if(stat[0] == 1){
                    if(total == 0){
                        stat[0] = 2
                    }
                }
                if(stat[0] == 2 && total > 0 ){
                    let progress : C8oProgress = _progress[0]
                    progress.total = Int(total!)
                    progress.current = (Int((rep?.completedChangesCount)!))
                    progress.taskInfo = "n/a"
                    progress.status = String(rep?.status)
                    if(progress.changed){
                        _progress[0] = C8oProgress(progress: progress)
                        if let _ = c8oResponseListener as? C8oResponseProgressListener where c8oResponseListener != nil{
                            param[C8o.ENGINE_PARAMETER_PROGRESS] = progress
                            (c8oResponseListener as! C8oResponseProgressListener).onProgressResponse(progress, param)
                        }
                    }
                    
                }
                
            })
            replication.start()
            
        }
        
        
    }
    
    func replicationProgress(n : NSNotification) {
        
        //fullSyncReplication.changeListener
        //let active = pullFullSyncReplication?.replication?.status == CBLReplicationStatus.Active || pushFullSyncReplication?.replication?.status == CBLReplicationStatus.Active
    }
    
    public func destroyReplications(){
        if(pullFullSyncReplication?.replication != nil){
            pullFullSyncReplication!.replication!.stop()
            pullFullSyncReplication!.replication!.deleteCookieNamed(C8oFullSyncDatabase.AUTHENTICATION_COOKIE_NAME)
            pullFullSyncReplication!.replication = nil
        }
        pullFullSyncReplication = nil
        
        if(pushFullSyncReplication?.replication != nil){
            pushFullSyncReplication!.replication!.stop()
            pushFullSyncReplication!.replication!.deleteCookieNamed(C8oFullSyncDatabase.AUTHENTICATION_COOKIE_NAME)
            pushFullSyncReplication!.replication = nil
        }
        pushFullSyncReplication = nil
        
    }
    
    public func getDatabaseName()->String{return self.databaseName}
    
    public func getDatabase()->CBLDatabase?{return self.database}
    
    
    
    private class FullSyncReplication{
        var replication : CBLReplication?
        var changeListener : NSObject?
        var pull : Bool
        
        private init(pull : Bool){
            self.pull = pull
        }
        
        
    }
}