//
//  C8OTranslator.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 19/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import AEXML

internal class C8oTranslator {
	private static var XML_KEY_ITEM: String = "item";
	private static var XML_KEY_OBJECT: String = "object";
	private static var XML_KEY__ATTACHMENTS: String = "_attachments";
	private static var XML_KEY_ATTACHMENT: String = "attachment";
	private static var XML_KEY_NAME: String = "name";
	
	internal static func jsonToXml(json: JSON, parentElement: AEXMLElement) -> Void {
		
		// Translates the JSON object depending to its type
		
		if (json.type == .Dictionary) {
			var jsonObject = json;
			// Gets all the elements of the JSON object and sorts them
			var keys = [String]()
			for jsonChild in jsonObject {
                keys.append(jsonChild.0)
			}
			keys.sortInPlace()
			
			// Translates each elements of the JSON object
			for key in keys {
				let keyValue = jsonObject[key]
				jsonKeyToXml(key, jsonValue: keyValue, parentElement: parentElement);
			}
		} else if (json.type == .Array) {
			let jsonArray = json
			// Translates each items of the JSON array
			for jsonItem in jsonArray {
				// Create the XML element
				let item = AEXMLElement(XML_KEY_ITEM);
				parentElement.addChild(item)
				parentElement.value = String(jsonItem.1)
				// JsonToXml(jsonItem, parentElement: item);
			}
		} else {
            parentElement.value = json.description;
        }
	}
	
	internal static func jsonKeyToXml(jsonKey: String, jsonValue: JSON/*JToken*/, parentElement: AEXMLElement/*XElement*/) -> Void {
		var jsonKeyMutable = jsonKey
		// Replaces the key if it is not specified
		if (String.IsNullOrEmpty(jsonKeyMutable)) {
			jsonKeyMutable = XML_KEY_OBJECT;
		}
		
		// If the parent node contains attachments (Specific to Couch)
		// TODO why ???
		if (C8oTranslator.XML_KEY__ATTACHMENTS == parentElement.name) {
			// Creates the attachment element and its child elements containing the attachment name
			let attachmentElement: AEXMLElement = AEXMLElement(XML_KEY_ATTACHMENT);
			let attachmentNameElement: AEXMLElement = AEXMLElement(XML_KEY_NAME);
			attachmentNameElement.value = jsonKeyMutable;
			attachmentElement.addChild(attachmentNameElement);
			parentElement.addChild(attachmentElement);
			
			// Translates the attachment value (it won't override attachment name element because the attachment value is normally a JSON object)
			jsonToXml(jsonValue, parentElement: attachmentElement);
		} else {
			// Creates the XML child element with its normalized name
			let normalizedKey: String = jsonKeyMutable
			let childElement = AEXMLElement(normalizedKey);
			parentElement.addChild(childElement);
			
			// Translates the JSON value
			jsonToXml(jsonValue, parentElement: childElement);
		}
	}
	
	// *** XML / JSON / Stream to string ***//
	
	internal static func xmlToString(xmlDocument: AEXMLDocument) -> String? {
		return String(xmlDocument)
		
	}
	
	internal static func jsonToString(jsonObject: JSON) -> String? {
		return String(jsonObject)
	}
	
	internal static func streamToString(stream: NSStream) -> String? {
		fatalError("Function \"StreamToString\" must be defined")
		
	}
	
	// *** Stream to XML / JSON ***//
	
	internal static func streamToJson(stream: NSStream) -> JSON? {
		fatalError("Function \"StreamToJson\" must be defined")
	}
	internal static func dataToJson(data: NSData) -> JSON? {
		let json = JSON(data: data)
		return json
	}
	
	internal static func streamToXml(stream: NSStream) -> NSObject? {
		fatalError("Function \"StreamToXml\" must be defined")
	}
	internal static func dataToXml(data: NSData) -> AEXMLDocument? {
		do {
			let doc = try AEXMLDocument(xmlData: data)
			return doc
		}
		catch {
			return nil
		}
	}
	
	// *** string to XML / JSON / object ***//
	
	internal static func stringToXml(xmlString: String) throws -> AEXMLElement {
		return try AEXMLDocument(xmlData: xmlString.dataUsingEncoding(NSUTF8StringEncoding)!)
	}
	
	internal static func stringToJson(jsonValueString: String) -> JSON {
		return JSON(data: jsonValueString.dataUsingEncoding(NSUTF8StringEncoding)!)
	}
	
	internal static func stringToObject(objectValue: String, type: Type) -> NSObject? {
		fatalError("Function \"StringToObject\" must be defined")
		
	}
	
	// *** Others ***//
	
	internal static func byteArrayToHexString(ba: UInt64) -> String? {
		let hex: String = String(format: "%2X", ba)
		return hex.stringByReplacingOccurrencesOfString("-", withString: "")
		
	}
	
	internal static func doubleToHexString(d: Double) -> String? {
		let bytes: UInt64 = UInt64(d)
		return C8oTranslator.byteArrayToHexString(bytes);
	}
	
	// *** Unused ***//
	
	// TODO
	internal static func stringToByteArray(str: String) -> [UInt8]? {
		fatalError("Function \"StringToByteArray\" must be defined")
		
	}
	
	// TODO
	internal static func byteArrayToString(bytes: [UInt8]) -> String? {
		fatalError("Function \"ByteArrayToString\" must be defined")
		
	}
	
	// TODO
	internal static func hexStringToByteArray(hex: String) -> [UInt8]? {
		fatalError("Function \"HexStringToByteArray\" must be defined")
		
	}
	
	// TODO
	internal static func dictionaryToJson(dict: Dictionary<String, NSObject>) -> JSON? {
		fatalError("Function \"DictionaryToJson\" must be defined")
		
	}
}