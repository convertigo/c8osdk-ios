//
//  C8oUtils.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 19/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

import Alamofire
import SwiftyJSON

import CouchbaseLite

internal class C8oUtils
{
    

    private static var USE_PARAMETER_IDENTIFIER : String = "_use_";
    
    

    
    internal static func GetObjectClassName(obj : NSObject)->String
    {
        
        /*string className = "null";
        if (obj != null)
        {
        className = obj.GetType().Name;
        }
        return className;*/
        
        return "str";
    }
    

    internal static func GetParameter(parameters : Dictionary<String, NSObject>, name : String, useName : Bool = false)->Dictionary<String, NSObject>
    {
        /*
        for parameter in parameters
        {
        string parameterName = parameter.Key;
        if (name.Equals(parameterName) || (useName && name.Equals(C8oUtils.USE_PARAMETER_IDENTIFIER + parameterName)))
        {
        return parameter;
        }
        }
        return new KeyValuePair<string, object>(null, null);
        */
        let a : Dictionary<String, NSObject> = Dictionary<String, NSObject>();
        return a ;
    }
    
    internal static func GetParameterObjectValue(parameters :  Dictionary<String, NSObject>, name : String, useName : Bool = false)->NSObject?
    {
        let parameter : Dictionary<String, NSObject> = GetParameter(parameters, name: name, useName: useName);
        if (parameter.keys.first != nil)
        {
            return parameter.values.first;
        }
        return nil;
    }
    

  internal static func GetParameterStringValue(parameters : Dictionary<String, NSObject> , name : String, useName : Bool = false)->String?
    {
        /*var parameter = GetParameter(parameters, name, useName);
        if (parameter.Key != nil)
        {
        return "" + parameter.Value;
        }*/
        return nil;
    }
    
  internal static func PeekParameterStringValue(parameters : Dictionary<String, NSObject> , name : String, exceptionIfMissing : Bool = false)->String?
    {
        /*
        string value = GetParameterStringValue(parameters, name, false);
        if (value == null)
        {
        if (exceptionIfMissing)
        {
        throw new ArgumentException(C8oExceptionMessage.MissParameter(name));
        }
        }
        else
        {
        parameters.Remove(name);
        }
        return value;*/
        return nil;
    }
    
    internal static func GetParameterJsonValue( parameters : Dictionary<String, NSObject>, name : Bool, useName : Bool = false)-> NSObject?
    {
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
    
    internal static func GetParameterJsonValue(parameter : Dictionary<String, NSObject> )->NSObject?
    {
        /* if (parameter.Value is string)
        {
        return C8oTranslator.StringToJson(parameter.Value as string);
        }
        return parameter.Value;*/
        return nil;
    }
    
    internal static func TryGetParameterObjectValue<T>(parameters : Dictionary<String, NSObject>, name : String, value : T, useName : Bool = false,  defaultValue : T )->Bool?
    {
        /*KeyValuePair<string, object> parameter = GetParameter(parameters, name, useName);
        if (parameter.Key != null && parameter.Value != null)
        {
        if (parameter.Value is string && typeof(T) != typeof(string))
        {
        value = (T) C8oTranslator.StringToObject(parameter.Value as string, typeof(T));
        }
        else
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
    internal static func IsValidUrl(url : String)->Bool
    {
        let uriResult : NSURL? = NSURL(string: url)

        if(uriResult?.scheme == "http" || uriResult?.scheme == "https"){
            return true
        }
        else{
            return false;
        }
        
    }
    

    internal static func GetUnixEpochTime(date : NSDate)->Int?
    {
        /*
        TimeSpan timeSpan = date.Subtract(new DateTime(1970, 1, 1, 0, 0, 0, 0));
        return timeSpan.TotalMilliseconds as Int;*/
        return nil;
    }
    
    //public static T GetParameterAndCheckType<T>(IDictionary<string, object> parameters, String name, T defaultValue = default(T))
    //{
    //    // KeyValuePair<SC8oUtils.GetParameter(parameters, name);
    
    //    return defaultValue;
    //}
    
    //public static T GetValueAndCheckType<T>(Dictionary<string, object> jObject, String key, T defaultValue = default(T))
    //{
    //    JToken value;
    //    if (jObject.TryGetValue(key, out value))
    //    {
    //        if (value is T)
    //        {
    //            return value as T;
    //        }
    //        else if (value is JValue && (value as JValue).Value is T)
    //        {
    //            return (value as JValue).Value;
    //        }
    //    }
    //    return defaultValue;
    //}
    
    internal static func TryGetValueAndCheckType<T>(jObject : JSON, key : String, value : T)->Bool?
    {
        /*
        JToken foundValue;
        if (jObject.TryGetValue(key, out foundValue))
        {
        if (foundValue is T)
        {
        value = (T)(object)foundValue;
        return true;
        }
        else if (foundValue is JValue && (foundValue as JValue).Value is T)
        {
        value = (T)(object)(foundValue as JValue).Value;
        return true;
        }
        }
        value = default(T);
        return false;*/
        return nil;
    }
    
    internal static func IdentifyC8oCallRequest(parameters : Dictionary<String, NSObject>, responseType : String)->String?
    {
        /*
        JObject json = new JObject();
        foreach (KeyValuePair<string, object> parameter in parameters)
        {
        JValue value = new JValue(parameter.Value);
        json.Add(parameter.Key, value);
        }
        return responseType + json.ToString();
        }
        
        public static func UrlDecode(string str)-> String
        {
        return Uri.UnescapeDataString(str);
        */
        return nil;
    }
    
}