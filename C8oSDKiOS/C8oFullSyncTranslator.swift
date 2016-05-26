//
//  C8oFullSyncTranslator.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 17/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import AEXML

internal class C8oFullSyncTranslator
{
    internal static var FULL_SYNC_RESPONSE_KEY_COUNT  : String = "count"
    internal static var FULL_SYNC_RESPONSE_KEY_ROWS : String = "rows"
    internal static var FULL_SYNC_RESPONSE_KEY_CURRENT : String = "current"
    internal static var FULL_SYNC_RESPONSE_KEY_DIRECTION : String = "direction"
    internal static var FULL_SYNC_RESPONSE_KEY_TOTAL : String = "total"
    internal static var FULL_SYNC_RESPONSE_KEY_OK : String = "ok"
    internal static var FULL_SYNC_RESPONSE_KEY_STATUS : String = "status"
    
    internal static var FULL_SYNC_RESPONSE_VALUE_DIRECTION_PUSH : String = "push"
    internal static var FULL_SYNC_RESPONSE_VALUE_DIRECTION_PULL : String = "pull"
    
    internal static var XML_KEY_DOCUMENT : String = "document"
    internal static var XML_KEY_COUCHDB_OUTPUT : String = "couchdb_output"
    
    internal static func fullSyncJsonToXml(json : JSON)throws->AEXMLDocument?
    {
        
        let xmlDocument : AEXMLDocument = AEXMLDocument()
        // Create the root element node
        let rootElement : AEXMLElement = AEXMLElement(C8oFullSyncTranslator.XML_KEY_DOCUMENT)//try! XMLDocument(string: C8oFullSyncTranslator.XML_KEY_DOCUMENT)
        xmlDocument.addChild(rootElement)
        let couchdb_output : AEXMLElement =  AEXMLElement(C8oFullSyncTranslator.XML_KEY_COUCHDB_OUTPUT)
        
        // Translates the JSON document
        do{
            C8oTranslator.jsonToXml(json, parentElement: couchdb_output)
        }
        
        rootElement.addChild(couchdb_output)
        return xmlDocument
    }
    
    internal static func dictionaryToJson(dictionary : Dictionary<String, NSObject>)->JSON?
    {
        let json : JSON = JSON(dictionary)
        return json
    }
    
    internal static func documentToJson(document : CBLDocument)->JSON{
        return JSON(document.properties!)
    }
    
    internal static func documentToXml(document : CBLDocument)->AnyObject{
        let json : JSON = documentToJson(document)
        return try! fullSyncJsonToXml(json)!
    }
    
    internal static func queryRowToDic(queryRow :CBLQueryRow)->Dictionary<String, AnyObject>{
        var result : Dictionary<String, AnyObject> = Dictionary<String, AnyObject>()
        if(queryRow.value == nil && queryRow.sourceDocumentID == nil){
            result["key"] = queryRow.key
            result["error"] = "not_found"
        }
        else{
            result["key"] = queryRow.key
            if(queryRow.value != nil){
                result["value"] = queryRow.value
            }
            
            result["id"] = queryRow.sourceDocumentID
            if(queryRow.documentProperties != nil){
                result["doc"] = queryRow.documentProperties
            }
        }
        return result
    }
    
    internal static func queryEnumeratorToJson(queryEnumerator : CBLQueryEnumerator)->JSON{
        
        var array : [Dictionary<String, AnyObject>] = [Dictionary<String, AnyObject>]()
        let countQ = queryEnumerator.count
        for _ in 1...queryEnumerator.count{
            array.append(C8oFullSyncTranslator.queryRowToDic(queryEnumerator.nextRow()!))
        }
        let json : JSON = [FULL_SYNC_RESPONSE_KEY_COUNT : countQ, FULL_SYNC_RESPONSE_KEY_ROWS : array]
        
        
        return json
    }
    
    internal static func queryEnumeratorToXml(queryEnumerator : CBLQueryEnumerator) throws->AEXMLDocument{
        let json : JSON
        do{
            json = try queryEnumeratorToJson(queryEnumerator)
        }
        catch let e as NSError{
            throw C8oException(message: C8oExceptionMessage.queryEnumeratorToJSON(), exception: e)
        }
        return try fullSyncJsonToXml(json)!
    }
    internal static func fullSyncDefaultResponseToJson(fullSyncDefaultResponse : FullSyncDefaultResponse) ->JSON{
        let json : JSON = JSON(fullSyncDefaultResponse.getProperties())
        return json
    }
    internal static func fullSyncDefaultResponseToXml(fullSyncDefaultResponse : FullSyncDefaultResponse)throws ->AEXMLDocument{
        do{
            return try fullSyncJsonToXml(fullSyncDefaultResponseToJson(fullSyncDefaultResponse))!
        }
        catch let e as C8oException{
           throw C8oException(message: C8oExceptionMessage.fullSyncJsonToXML(), exception: e)
        }
    }
    
    internal static func dictionaryToString(dict : Dictionary<String, NSObject>)-> String
    {
        //Becarefull here this function may not work propely
        var str : String = "{ ";
        
        for item in dict
        {
            var valueStr : String = ""
            
           valueStr = dictionaryToString(Dictionary<String, NSObject>(dictionaryLiteral: item));

            str += item.0 + " : " + valueStr + ", ";
        }
        
        if(dict.count > 0)
        {
            
            let desiredLength = str.startIndex.advancedBy(((str.characters.count)-2))
            str = str.substringToIndex(desiredLength)
        }
        
        str += " }"
        
        return str
    }
    
    internal static func listToString(list : Array<NSObject>)->String
    {
        var str : String = "["
        for item in list
        {
            str = str + String(item) + ", "
        }
        
        if(list.count > 0)
        {
            let desiredLength = str.startIndex.advancedBy(((str.characters.count)-2))
            str = str.substringToIndex(desiredLength)
        }
        
        str = str + "]"
        
        return str
    }
    
    internal static func fullSyncDocumentOperationResponseToJson(fullSyncDocumentOperationResponse : FullSyncAbstractResponse) ->JSON{
        let json : JSON = JSON(fullSyncDocumentOperationResponse.getProperties())
        return json
    }
    
    internal static func fullSyncDocumentOperationResponseToXml(fullSyncDocumentOperationResponse : FullSyncAbstractResponse) ->AEXMLDocument{
        return try! fullSyncJsonToXml(fullSyncDocumentOperationResponseToJson(fullSyncDocumentOperationResponse))!
    }
    
}
