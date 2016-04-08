//
//  FullSyncEnum.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 06/04/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import CouchbaseLite

class FullSyncEnum{
    enum FullSyncRequestable {
        case GET(String), DELETE(String), POST(String), ALL(String), VIEW(String), SYNC(String), REPLICATE_PULL(String), REPLICATE_PUSH(String), RESET(String), CREATE(String), DESTROY(String)

        func get(enu : FullSyncRequestable){
            switch(enu){
            case .GET("get"):
                break
            case .POST("post"):
                break
            case .ALL("all"):
                break
            case .VIEW("view"):
                break
            case .SYNC("sync"):
                break
            case .REPLICATE_PULL("replicate_pull"):
                break
            case .REPLICATE_PUSH("replicate_push"):
                break
            case .RESET("reset"):
                break
            case .CREATE("create"):
                break
            case .DESTROY("destroy"):
                break
            default:
                break
            }
        }
        
        //var value : String
        /*init(value : String){
            //self.value = value
            
        }*/
        
        
        //TODO...
        func handleFullSyncRequest(c8oFullSync : C8oFullSync, databaseName : String , parameters : Dictionary<String, NSObject>, c8oResponseListener : C8oResponseListener) throws -> NSObject
        {
            fatalError("must be abstract and implemented")
        }
        
        static func getFullSyncRequestable(value : String)->FullSyncRequestable{
            fatalError("must be implemented")
            /*let fullSyncRequestableValues : [FullSyncRequestable] = FullSyncRequestable.values
            for fullSyncRequestable in fullSyncRequestableValues{
                if (fullSyncRequestable.value == value){
                    return fullSyncRequestable
                }
            }*/
        }
    }
    
    enum FullSyncRequestParameter{
        case DESCENDING(String, Bool), ENDKEY(String, Bool), ENDKEY_DOCID(String, Bool), GROUP_LEVEL(String), INCLUDE_DELETED(String, Bool), INDEX_UPDATE_MODE(String), KEYS(String, Bool), LIMIT(String, Bool), INCLUDE_DOCS(String, Bool), REDUCE(String, Bool), GROUP(String, Bool), SKIP(String, Bool), STARTKEY(String, Bool), STARTKEY_DOCID(String)
        
        func get(enu: FullSyncRequestParameter){
            switch(enu){
            case .DESCENDING("descending", true):
                break
            case .ENDKEY("endkey", true):
                break
            case .ENDKEY_DOCID("endkey_docid", true):
                break
            case .GROUP("group", true):
                break
            case .GROUP_LEVEL("group_level"):
                break
            case .INCLUDE_DELETED("include_deleted", true):
                break
            case .INCLUDE_DOCS("include_docs", true):
                break
            case .INDEX_UPDATE_MODE("index_update_mode"):
                break
            case .KEYS("keys", true):
                break
            case .LIMIT("limit", true):
                break
            case .REDUCE("reduce", true):
                break
            case .SKIP("skip", true):
                break
            case .STARTKEY("startkey", true):
                break
            case .STARTKEY_DOCID("startkey_docid"):
                break
            default:
                break
            }
        }
        //var name : String
        // var isJson : Bool
        
        /*init(name : String, isJson : Bool){
            //self.name = name
            //self.isJson = isJson
        }
        init(name : String){
            //self.name = name
        }*/
       
        
        //abstract void addToQuery(Query query, Object parameter);
        
    }
    
    enum FullSyncGetViewParameter {
        case VIEW(String), DDOC(String)
        
        func get(enu : FullSyncGetViewParameter){
            switch(enu){
            case .VIEW("view"):
                break
            case .DDOC("ddoc"):
                break
            default:
                break
            }
        }
        //public let name : String
        /*init(name : String){
            //self.name = name
        }*/
    }
    
    enum FullSyncGetDocumentParameter {
        case DOCID(String)
        
        func get(enu : FullSyncGetDocumentParameter){
            switch(enu){
            case .DOCID("ddoc"):
                break
            default:
                break
            }
        }
        //public let name : String
        /*init(name : String){
            //self.name = name
        }*/
    }
    
    enum FullSyncDeleteDocumentParameter {
        case DOCID(String), REV(String)
        
        func get(enu : FullSyncDeleteDocumentParameter){
            switch(enu){
            case .DOCID("ddoc"):
                break
            case .REV("rev"):
                break
            default:
                break
            }
        }
        
        public func name()->String{
            fatalError("must be implemented")
            return "TODO"
        }
        //public let name : String
        /*init(name : String){
            //self.name = name
        }*/
    }
    
    enum FullSyncReplicateDatabaseParameter {
        case CANCEL(String), LIVE(String), DOCIDS(String)
        
        func get(enu : FullSyncReplicateDatabaseParameter){
            switch(enu){
            case .CANCEL("cancel"):
                break
            case .LIVE("live"):
                break
            case .DOCIDS("docids"):
                break
            default:
                break
            }
        }
        //public let name : String
        /*init(name : String){
            //self.name = name
        }*/
        
        //abstract void setReplication(Replication replication, Object parameterValue);
    }
    
    enum FullSyncPolicy {
        case NONE(String), CREATE(String), OVERRIDE(String), MERGE(String)
        
        func get(enu : FullSyncPolicy){
            switch(enu){
            case .NONE(C8o.FS_POLICY_NONE):
                break
            case .CREATE(C8o.FS_POLICY_CREATE):
                break
            case .OVERRIDE(C8o.FS_POLICY_OVERRIDE):
                break
            case .MERGE(C8o.FS_POLICY_MERGE):
                break
            default:
                break
            }
        }
        //public var value : String
        
        /*init(value : String){
            //self.value = value
        }*/
        
        static func getFullSyncPolicy(name : String)-> FullSyncPolicy?{
            /*do{
                return name.uppercaseString
            }catch{
                return NONE
            }*/
            let e : FullSyncPolicy? = nil
            return e
        }
        
        func postDocument(database :CBLDatabase , newProperties : Dictionary<String, AnyObject>) throws ->CBLDocument{
            fatalError("must be abstract and overrwiten")
            let cbl : CBLDocument? = nil
            return cbl!
        }
    }
}