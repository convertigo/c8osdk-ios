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
	fileprivate static var XML_KEY_ITEM: String = "item";
	fileprivate static var XML_KEY_OBJECT: String = "object";
	fileprivate static var XML_KEY__ATTACHMENTS: String = "_attachments";
	fileprivate static var XML_KEY_ATTACHMENT: String = "attachment";
	fileprivate static var XML_KEY_NAME: String = "name";
	
	internal static func jsonToXml(_ json: JSON, parentElement: AEXMLElement) -> Void {
		
		// Translates the JSON object depending to its type
		
		if (json.type == .dictionary) {
			var jsonObject = json;
			// Gets all the elements of the JSON object and sorts them
			var keys = [String]()
			for jsonChild in jsonObject {
                keys.append(jsonChild.0)
			}
			keys.sort()
			
			// Translates each elements of the JSON object
			for key in keys {
				let keyValue = jsonObject[key]
				jsonKeyToXml(key, jsonValue: keyValue, parentElement: parentElement);
			}
		} else if (json.type == .array) {
			let jsonArray = json
			// Translates each items of the JSON array
			for jsonItem in jsonArray {
				// Create the XML element
				let item = AEXMLElement(name: XML_KEY_ITEM);
				parentElement.addChild(item)
				parentElement.value = String(describing: jsonItem.1)
				// JsonToXml(jsonItem, parentElement: item);
			}
		} else {
            parentElement.value = json.description;
        }
	}
	
	internal static func jsonKeyToXml(_ jsonKey: String, jsonValue: JSON/*JToken*/, parentElement: AEXMLElement/*XElement*/) -> Void {
		var jsonKeyMutable = jsonKey
		// Replaces the key if it is not specified
		if (String.IsNullOrEmpty(jsonKeyMutable)) {
			jsonKeyMutable = XML_KEY_OBJECT;
		}
		
		// If the parent node contains attachments (Specific to Couch)
		// TODO why ???
		if (C8oTranslator.XML_KEY__ATTACHMENTS == parentElement.name) {
			// Creates the attachment element and its child elements containing the attachment name
			let attachmentElement: AEXMLElement = AEXMLElement(name: XML_KEY_ATTACHMENT);
			let attachmentNameElement: AEXMLElement = AEXMLElement(name: XML_KEY_NAME);
			attachmentNameElement.value = jsonKeyMutable;
			attachmentElement.addChild(attachmentNameElement);
			parentElement.addChild(attachmentElement);
			
			// Translates the attachment value (it won't override attachment name element because the attachment value is normally a JSON object)
			jsonToXml(jsonValue, parentElement: attachmentElement);
		} else {
			// Creates the XML child element with its normalized name
			let normalizedKey: String = jsonKeyMutable
			let childElement = AEXMLElement(name: normalizedKey);
			parentElement.addChild(childElement);
			
			// Translates the JSON value
			jsonToXml(jsonValue, parentElement: childElement);
		}
	}
	
	// *** XML / JSON / Stream to string ***//
	
	internal static func xmlToString(_ xmlDocument: AEXMLDocument) -> String? {
		return String(describing: xmlDocument)
		
	}
	
	internal static func jsonToString(_ jsonObject: JSON) -> String? {
		return String(describing: jsonObject)
	}
	
	internal static func streamToString(_ stream: Stream) -> String? {
		fatalError("Function \"StreamToString\" must be defined")
		
	}
	
	// *** Stream to XML / JSON ***//
	
	internal static func streamToJson(_ stream: Stream) -> JSON? {
		fatalError("Function \"StreamToJson\" must be defined")
	}
	internal static func dataToJson(_ data: NSData) -> JSON? {
		let json = JSON(data: data as Data)
		return json
	}
	
	internal static func streamToXml(_ stream: Stream) -> NSObject? {
		fatalError("Function \"StreamToXml\" must be defined")
	}
	internal static func dataToXml(_ data: Data) -> AEXMLDocument? {
		do {
            let doc = try AEXMLDocument(xml: data)
			return doc
		}
		catch {
			return nil
		}
	}
	
	// *** string to XML / JSON / object ***//
	
	internal static func stringToXml(_ xmlString: String) throws -> AEXMLElement {
        return try AEXMLDocument(xml: xmlString.data(using: String.Encoding.utf8)!)
	}
	
	internal static func stringToJson(_ jsonValueString: String) -> JSON {
		return JSON(data: jsonValueString.data(using: String.Encoding.utf8)!)
	}
	
	internal static func stringToObject(_ objectValue: String, type: Type) -> NSObject? {
		fatalError("Function \"StringToObject\" must be defined")
		
	}
	
	// *** Others ***//
	
	internal static func byteArrayToHexString(_ ba: UInt64) -> String? {
		let hex: String = String(format: "%2X", ba)
		return hex.replacingOccurrences(of: "-", with: "")
		
	}
	
	internal static func doubleToHexString(_ d: Double) -> String? {
		let bytes: UInt64 = UInt64(d)
		return C8oTranslator.byteArrayToHexString(bytes);
	}
	
	// *** Unused ***//
	
	// TODO
	internal static func stringToByteArray(_ str: String) -> [UInt8]? {
		fatalError("Function \"StringToByteArray\" must be defined")
		
	}
	
	// TODO
	internal static func byteArrayToString(_ bytes: [UInt8]) -> String? {
		fatalError("Function \"ByteArrayToString\" must be defined")
		
	}
	
	// TODO
	internal static func hexStringToByteArray(_ hex: String) -> [UInt8]? {
		fatalError("Function \"HexStringToByteArray\" must be defined")
		
	}
	
	// TODO
	internal static func dictionaryToJson(_ dict: Dictionary<String, NSObject>) -> JSON? {
		fatalError("Function \"DictionaryToJson\" must be defined")
		
	}
}
