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

internal class C8oFullSyncTranslator {
	internal static var FULL_SYNC_RESPONSE_KEY_COUNT: String = "count"
	internal static var FULL_SYNC_RESPONSE_KEY_ROWS: String = "rows"
	internal static var FULL_SYNC_RESPONSE_KEY_CURRENT: String = "current"
	internal static var FULL_SYNC_RESPONSE_KEY_DIRECTION: String = "direction"
	internal static var FULL_SYNC_RESPONSE_KEY_TOTAL: String = "total"
	internal static var FULL_SYNC_RESPONSE_KEY_OK: String = "ok"
	internal static var FULL_SYNC_RESPONSE_KEY_STATUS: String = "status"
	
	internal static var FULL_SYNC_RESPONSE_VALUE_DIRECTION_PUSH: String = "push"
	internal static var FULL_SYNC_RESPONSE_VALUE_DIRECTION_PULL: String = "pull"
	
	internal static var XML_KEY_DOCUMENT: String = "document"
	internal static var XML_KEY_COUCHDB_OUTPUT: String = "couchdb_output"
	
	internal static func fullSyncJsonToXml(_ json: JSON) throws -> AEXMLDocument? {
		
		let xmlDocument: AEXMLDocument = AEXMLDocument()
		// Create the root element node
		let rootElement: AEXMLElement = AEXMLElement(name: C8oFullSyncTranslator.XML_KEY_DOCUMENT) // try! XMLDocument(string: C8oFullSyncTranslator.XML_KEY_DOCUMENT)
		xmlDocument.addChild(rootElement)
		let couchdb_output: AEXMLElement = AEXMLElement(name: C8oFullSyncTranslator.XML_KEY_COUCHDB_OUTPUT)
		
		// Translates the JSON document
		do {
			C8oTranslator.jsonToXml(json, parentElement: couchdb_output)
		}
		
		rootElement.addChild(couchdb_output)
		return xmlDocument
	}
	
	internal static func dictionaryToJson(_ dictionary: Dictionary<String, Any>) -> JSON? {
		let json: JSON = JSON(dictionary)
		return json
	}
	
	internal static func documentToJson(_ document: CBLDocument) -> JSON {
		return JSON(document.properties!)
	}
	
	internal static func documentToXml(_ document: CBLDocument) -> Any {
		let json: JSON = documentToJson(document)
		return try! fullSyncJsonToXml(json)!
	}
	
	internal static func queryRowToDic(_ queryRow: CBLQueryRow) -> Dictionary<String, Any> {
		var result: Dictionary<String, Any> = Dictionary<String, Any>()
		if (queryRow.value == nil && queryRow.sourceDocumentID == nil) {
			result["key"] = queryRow.key as Any
			result["error"] = "not_found" as Any
		} else {
			result["key"] = queryRow.key as Any
			if (queryRow.value != nil) {
				result["value"] = queryRow.value as Any
			}
			
			result["id"] = queryRow.sourceDocumentID as Any
			if (queryRow.documentProperties != nil) {
				result["doc"] = queryRow.documentProperties as Any
			}
		}
		return result
	}
	
	internal static func queryEnumeratorToJson(_ queryEnumerator: CBLQueryEnumerator) -> JSON {
		
		var array: [Dictionary<String, Any>] = [Dictionary<String, Any>]()
		let countQ = queryEnumerator.count
		for _ in 0..<queryEnumerator.count {
			array.append(C8oFullSyncTranslator.queryRowToDic(queryEnumerator.nextRow()!))
		}
		let json: JSON = [FULL_SYNC_RESPONSE_KEY_COUNT: countQ, FULL_SYNC_RESPONSE_KEY_ROWS: array]
		
		return json
	}
    
	
	internal static func queryEnumeratorToXml(_ queryEnumerator: CBLQueryEnumerator) throws -> AEXMLDocument {
		let json: JSON

			json = queryEnumeratorToJson(queryEnumerator)

		return try fullSyncJsonToXml(json)!
	}
	internal static func fullSyncDefaultResponseToJson(_ fullSyncDefaultResponse: FullSyncDefaultResponse) -> JSON {
		let json: JSON = JSON(fullSyncDefaultResponse.getProperties())
		return json
	}
	internal static func fullSyncDefaultResponseToXml(_ fullSyncDefaultResponse: FullSyncDefaultResponse) throws -> AEXMLDocument {
		do {
			return try fullSyncJsonToXml(fullSyncDefaultResponseToJson(fullSyncDefaultResponse))!
		}
		catch let e as C8oException {
			throw C8oException(message: C8oExceptionMessage.fullSyncJsonToXML(), exception: e)
		}
	}
	
	internal static func dictionaryToString(_ dict: Dictionary<String, NSObject>) -> String {
		// Becarefull here this function may not work propely
		var str: String = "{ ";
		
		for item in dict {
			var valueStr: String = ""
			
			valueStr = dictionaryToString(Dictionary<String, NSObject>(dictionaryLiteral: item));
			
			str += item.0 + " : " + valueStr + ", ";
		}
		
		if (dict.count > 0) {
			
			let desiredLength = str.characters.index(str.startIndex, offsetBy: ((str.characters.count) - 2))
			str = str.substring(to: desiredLength)
		}
		
		str += " }"
		
		return str
	}
	
	internal static func listToString(_ list: Array<NSObject>) -> String {
		var str: String = "["
		for item in list {
			str = str + String(describing: item) + ", "
		}
		
		if (list.count > 0) {
			let desiredLength = str.characters.index(str.startIndex, offsetBy: ((str.characters.count) - 2))
			str = str.substring(to: desiredLength)
		}
		
		str = str + "]"
		
		return str
	}
	
	internal static func fullSyncDocumentOperationResponseToJson(_ fullSyncDocumentOperationResponse: FullSyncAbstractResponse) -> JSON {
		let json: JSON = JSON(fullSyncDocumentOperationResponse.getProperties())
		return json
	}
	
	internal static func fullSyncDocumentOperationResponseToXml(_ fullSyncDocumentOperationResponse: FullSyncAbstractResponse) -> AEXMLDocument {
		return try! fullSyncJsonToXml(fullSyncDocumentOperationResponseToJson(fullSyncDocumentOperationResponse))!
	}
    
    internal static func toAnyObject(obj: AnyObject) -> AnyObject {
        if let nsSet = obj as? NSSet {
            let array = NSMutableArray()
            for item in nsSet {
                array.add(toAnyObject(obj: item))
            }
            return array
        }
        if let nsArray = obj as? NSArray {
            let array = NSMutableArray()
            for item in nsArray {
                array.add(toAnyObject(obj: item))
            }
            return array
        }
        if let nsDict = obj as? NSDictionary {
            let dict = NSMutableDictionary()
            for item in nsDict {
                if let k = item.key as? NSCopying {
                    dict[k] = toAnyObject(obj: item.value)
                }
            }
            return dict
        }
        let mirror = Mirror(reflecting: obj)
        if (mirror.children.count > 0) {
            let dict = NSMutableDictionary()
            for child in mirror.children {
                let prop = child.label!
                dict[prop] = toAnyObject(obj: child.value)
            }
            return dict
        } else {
            return obj
        }
    }
    
    internal static func toAnyObject(obj: Any) -> AnyObject {
        if(obj is String){
            return obj as AnyObject
        }
        if let nsValue = obj as? NSObject {
            return toAnyObject(obj: nsValue)
        }
        if (obj is AnyObject) {
            return toAnyObject(obj: obj as! AnyObject)
        }
        let mirror = Mirror(reflecting: obj)
        if (mirror.children.count > 0) {
            for child in mirror.children {
                return toAnyObject(obj: child.value)
            }
        }
        return NSNull()
    }
}
