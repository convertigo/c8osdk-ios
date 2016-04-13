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

@objc public class C8oFullSyncDatabase : NSObject {
    
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
            c8oFullSyncDatabaseUrl = NSURL(string: fullSyncDatabases + databaseNameMutable + "/")!
        }
        /*catch{
            
        }*/
        databaseNameMutable = databaseNameMutable + localSuffix
        self.databaseName = databaseNameMutable
        
        do{
            database = try manager.databaseNamed(databaseNameMutable)
        }
        catch{
            
        }
    }
    //TODO...
    private func getReplication(fsReplication : FullSyncReplication?)-> CBLReplication{
    
        if(fsReplication?.replication != nil){
            fsReplication!.replication!.stop()
            if(fsReplication?.changeListener != nil){
                //fsReplication?.replication.removeObserver(NSObject, forKeyPath: String)
            }
        }
        fsReplication!.pull ? database?.createPullReplication(c8oFullSyncDatabaseUrl) : database?.createPushReplication(c8oFullSyncDatabaseUrl)
        let replication : CBLReplication = (fsReplication?.replication)!
        
        /*for cookie in c8o.CookieStore.cookies!{
            replication.setCookieNamed(cookie.name, withValue: cookie.value, path: cookie.path, expirationDate: cookie.expiresDate, secure: cookie.secure)
        }*/
        
        return replication
        
    }
    
    public func startAllReplications(parameters : Dictionary<String, NSObject>, c8oResponseListener : C8oResponseListener)throws{
        try! startPullReplication(parameters, c8oResponseListener: c8oResponseListener)
        try! startPushReplication(parameters, c8oResponseListener: c8oResponseListener)
    }
    
    public func startPullReplication(parameters : Dictionary<String, NSObject>, c8oResponseListener : C8oResponseListener)throws{
        try! startReplication(pullFullSyncReplication!, parameters: parameters, c8oResponseListener: c8oResponseListener)
    }
    
    public func startPushReplication(parameters : Dictionary<String, NSObject>, c8oResponseListener : C8oResponseListener)throws{
        try! startReplication(pullFullSyncReplication!, parameters: parameters, c8oResponseListener: c8oResponseListener)
    }
    
    private func startReplication(fullSyncReplication : FullSyncReplication, parameters : Dictionary<String, NSObject>, c8oResponseListener : C8oResponseListener) throws {
        fatalError("must be finished")
       /* var continious : Bool = false
        var cancel : Bool = false
        
        if let _ = parameters["continious"]{
            if(String(parameters["continious"]).caseInsensitiveCompare("true") == NSComparisonResult.OrderedSame){
               continious = true
            }
        }
        
        if let _ = parameters["cancel"]{
            if(String(parameters["cancel"]).caseInsensitiveCompare("true") == NSComparisonResult.OrderedSame){
                cancel = true
            }
        }
        
        let rep : CBLReplication? = getReplication(fullSyncReplication)
        
        if(cancel){
            if(rep != nil)
            {
                rep!.stop()
            }
            return
        }
        
        let param : Dictionary<String, NSObject> = parameters
        var progress : C8oProgress = C8oProgress()
        let _progress : [C8oProgress] = [progress]
        progress.raw = rep!
        progress.pull = rep!.pull
        
        let condition : NSCondition = NSCondition()
        
        //TODO....
        
        //push
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "replicationChanged", name: kCBLDatabaseChangeNotification, object: pushFullSyncReplication?.replication)
        //pull
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "replicationChanged", name: kCBLDatabaseChangeNotification, object: pullFullSyncReplication?.replication)*/
        
        
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