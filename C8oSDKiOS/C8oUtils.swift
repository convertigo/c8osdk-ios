//
//  C8oUtils.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 19/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

import SwiftyJSON

internal class C8oUtils {
	
	fileprivate static var USE_PARAMETER_IDENTIFIER: String = "_use_";
	
	internal static func getObjectClassName(_ obj: Any?) -> String {
		
		var className = "nil";
		if (obj != nil) {
			className = String(describing: type(of: obj))
			
		}
		return className;
		
	}
	
	internal static func getParameter(_ parameters: Dictionary<String, Any>, name: String, useName: Bool = false) -> Pair<String?, Any?> {
		print(parameters.description)
		for parameter in parameters {
			let parameterName: String = parameter.0;
            print(parameterName)
			if ((name == parameterName) || (useName && name == (C8oUtils.USE_PARAMETER_IDENTIFIER + parameterName))) {
                print(parameter.value)
				return Pair<String?, Any?>(key: parameter.0, value: parameter.1) // (key: parameter.0, value: parameter.1 as Any);
			}
		}
		let stringNil: String? = nil
		let nsobjectnil: String? = nil
		return Pair<String?, Any?>(key: stringNil, value: nsobjectnil);
		
	}
	
	internal static func getParameterObjectValue(_ parameters: Dictionary<String, Any>, name: String, useName: Bool = false) -> Any? {
		let parameter: Pair<String?, Any?> = getParameter(parameters, name: name, useName: useName);
		if (parameter.key != nil) {
			return parameter.value as Any
		}
		return nil;
	}
	
	internal static func getParameterStringValue(_ parameters: Dictionary<String, Any>, name: String, useName: Bool = false) -> String? {
		let parameter = getParameter(parameters, name: name, useName: useName);
		if (parameter.key != nil) {
			if (parameter.value == nil) {
				return nil
			} else if (parameter.value is C8oJSON) {
				
				return String(describing: (parameter.value as! C8oJSON).myJSON)
			} else {
                print(String(describing: parameter.value!).description)
				return String(describing: parameter.value!);
			}
			
		}
		return nil;
	}
	
	internal static func peekParameterStringValue(_ parameters: Dictionary<String, Any>, name: String, exceptionIfMissing: Bool = false) throws -> String? {
		var parameters = parameters
		let value: String? = getParameterStringValue(parameters, name: name, useName: false);
		if (value == nil) {
			if (exceptionIfMissing) {
				throw C8oException(message: C8oExceptionMessage.MissParameter(name));
			}
		} else {
			parameters.removeValue(forKey: name);
		}
		return value;
	}
	
	internal static func getParameterJsonValue(_ parameters: Dictionary<String, Any>, name: Bool, useName: Bool = false) -> NSObject? {
		/*
		 var parameter = GetParameter(parameters, name, useName);
		 if (parameter.Key != null)
		 {
		 return C8oUtils.GetParameterJsonValue(parameter);
		 }
		 return null;
		 */
		return nil;
	}
	
	internal static func getParameterJsonValue(_ parameter: Dictionary<String, NSObject>) -> NSObject? {
		/* if (parameter.Value is string)
		 {
		 return C8oTranslator.StringToJson(parameter.Value as string);
		 }
		 return parameter.Value;*/
		return nil;
	}
	
	internal static func tryGetParameterObjectValue<T>(_ parameters: Dictionary<String, Any>, name: String, value: T, useName: Bool = false, defaultValue: T) -> Bool? {
		/*KeyValuePair<string, object> parameter = GetParameter(parameters, name, useName);
		 if (parameter.Key != null && parameter.Value != null)
		 {
		 if (parameter.Value is string && typeof(T) != typeof(string))
		 {
		 value = (T) C8oTranslator.StringToObject(parameter.Value as string, typeof(T));
		 } else
		 {
		 value = (T) parameter.Value;
		 }
		 return true;
		 }
		 value = defaultValue;
		 return false;*/
		return nil;
	}
	
	/**
	 Checks if the specified string is an valid URL by checking for http or https prefix.

	 @param url String.

	 @return Bool value.
	 */
	internal static func isValidUrl(_ url: String) -> Bool {
		let uriResult: URL? = URL(string: url)
		
		if (uriResult?.scheme == "http" || uriResult?.scheme == "https") {
			return true
		} else {
			return false;
		}
		
	}
	
	internal static func getUnixEpochTime() -> Double? {
		return Double(Date().timeIntervalSince1970 * 1000)
	}
	
	// public static T GetParameterAndCheckType<T>(IDictionary<string, object> parameters, String name, T defaultValue = default(T))
	// {
	// // KeyValuePair<SC8oUtils.GetParameter(parameters, name);
	
	// return defaultValue;
	// }
	
	// public static T GetValueAndCheckType<T>(Dictionary<string, object> jObject, String key, T defaultValue = default(T))
	// {
	// JToken value;
	// if (jObject.TryGetValue(key, out value))
	// {
	// if (value is T)
	// {
	// return value as T;
	// }
	// else if (value is JValue && (value as JValue).Value is T)
	// {
	// return (value as JValue).Value;
	// }
	// }
	// return defaultValue;
	// }
	
	internal static func tryGetValueAndCheckType<T>(_ jObject: JSON, key: String, value: T) -> Bool? {
		fatalError()
		/*
		 JToken foundValue;
		 if (jObject.TryGetValue(key, out foundValue))
		 {
		 if (foundValue is T)
		 {
		 value = (T)(object)foundValue;
		 return true;
		 } else if (foundValue is JValue && (foundValue as JValue).Value is T)
		 {
		 value = (T)(object)(foundValue as JValue).Value;
		 return true;
		 }
		 }
		 value = default(T);
		 return false;*/
	}
	
	internal static func identifyC8oCallRequest(_ parameters: Dictionary<String, Any>, responseType: String) -> String? {
		/*
		 let json : JSON
		 let dict = new Di
		 for parameter in parameters{


		 json.Add(parameter.Key, value);
		 }*/
		let json: JSON = JSON(parameters)
		return responseType + json.dictionaryObject!.description
	}
	
	internal static func UrlDecode(_ str: String) -> String {
		fatalError()
		// return Uri.UnescapeDataString(str)
	}
	
}
