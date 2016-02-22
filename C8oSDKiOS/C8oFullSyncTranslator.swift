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

internal class C8oFullSyncTranslator
{
    public static var FULL_SYNC_RESPONSE_KEY_COUNT  : String = "count";
    public static var FULL_SYNC_RESPONSE_KEY_ROWS : String = "rows";
    public static var FULL_SYNC_RESPONSE_KEY_CURRENT : String = "current";
    public static var FULL_SYNC_RESPONSE_KEY_DIRECTION : String = "direction";
    public static var FULL_SYNC_RESPONSE_KEY_TOTAL : String = "total";
    public static var FULL_SYNC_RESPONSE_KEY_OK : String = "ok";
    
    public static var FULL_SYNC_RESPONSE_VALUE_DIRECTION_PUSH : String = "push";
    public static var FULL_SYNC_RESPONSE_VALUE_DIRECTION_PULL : String = "pull";
    
    public static var XML_KEY_DOCUMENT : String = "document";
    public static var XML_KEY_COUCHDB_OUTPUT : String = "couchdb_output";
    
    public static func FullSyncJsonToXml(json : NSObject /*JSON*/)->NSObject?//XDocument
    {
        /*
        var xmlDocument : XDocument = XDocument();
        // Create the root element node
        var rootElement : XElement = XElement(XML_KEY_DOCUMENT);
        xmlDocument.Add(rootElement);
        var couchdb_output : XElement =  XElement(XML_KEY_COUCHDB_OUTPUT);
    
        // Translates the JSON document
        C8oTranslator.JsonToXml(json, couchdb_output);
        rootElement.Add(couchdb_output);
        return xmlDocument;*/
        return nil;
    }
    
    public static func DictionaryToJson(dictionary : Dictionary<String, NSObject>)->JSON?
    {
    /*
        var jsonStr : String = JsonConvert.SerializeObject(dictionary);
        //var json  = JObject.Parse(jsonStr);
        return json;
*/
        return nil
    }
    
    public static func  DictionaryToString(dict : Dictionary<String, NSObject>)-> String
    {
        
        var str : String = "{ ";
    
        for item in dict
        {
            var valueStr : String;
            
            if (item is Dictionary<NSString, NSObject>)
            {
                valueStr = DictionaryToString(Dictionary<String, NSObject>(dictionaryLiteral: item));
            }
            else if (item is Array<NSObject>)
            {
                //valueStr = ListToString(Array<NSObject>(item));
            }
            else
            {
                valueStr = String(item)
            }
    
    
            str += item.0 + " : " //+ valueStr + ", ";
        }
    
        if(dict.count > 0)
        {
            
            let desiredLength = str.startIndex.advancedBy(((str.characters.count)-2))
            str = str.substringToIndex(desiredLength)
        }
    
    str += " }";
    
    return str;
    }
    
    public static func ListToString(list : Array<NSObject>)->String
    {
        var str : String = "[";
        for item in list
        {
            str = str + String(item) + ", ";
        }
    
        if(list.count > 0)
        {
            let desiredLength = str.startIndex.advancedBy(((str.characters.count)-2))
            str = str.substringToIndex(desiredLength)
        }
    
        str = str + "]";
    
        return str;
    }
    
}
