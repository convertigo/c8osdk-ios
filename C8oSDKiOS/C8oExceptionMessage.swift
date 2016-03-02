//
//  C8oExceptionMessage.swift
//  
//
//  Created by Charles Grimont on 18/02/2016.
//
//

import Foundation


internal class C8oExceptionMessage
{
    
    public static func NotImplementedFullSyncInterface()->String
    {
    return "You are using the default FullSyncInterface which is not implemented";
    }
    
    public static func InvalidParameterValue(parameterName : String, details : String? = nil)->String
    {
        var errorMessage : String = "The parameter '" + parameterName + "' is invalid";
    if (details != nil)
    {
    errorMessage += ", " + details!;
    }
    return errorMessage;
    }
    
    public static func MissingValue(valueName : String)->String
    {
    return "The " + valueName + " is missing";
    }
    
    public static func UnknownValue(valueName : String, value : String)->String
    {
    return "The " + valueName + " value " + value + " is unknown";
    }
    
    public static func UnknownType(variableName : String, variable : NSObject)->String
    {
    return "The " + variableName + " type " + C8oUtils.GetObjectClassName(variable) + "is unknown";
    }
    
    public static func RessourceNotFound(ressourceName : String)->String
    {
    return "The " + ressourceName + " was not found";
    }
    
    public static func ToDo()->String
    {
    return "TODO";
    }
    
    
    
    
    
    /** TAG Illegal argument */
    
    public static func illegalArgumentInvalidFullSyncDatabaseUrl(fullSyncDatabaseUrlStr : String)->String
    {
    return "The fullSync database url '" + fullSyncDatabaseUrlStr + "' is not a valid url";
    }
    
    internal static func FullSyncDatabaseInitFailed(databaseName: String)->String
    {
    return "Failed to initialize the FullSync database '" + databaseName + "'";
    }
    
    public static func MissParameter(parameterName: String)->String
    {
    return "The parameter '" + parameterName + "' is missing";
    }
    
    private static func illegalArgumentInvalidParameterValue(parameterName: String, parameterValue: String)->String
    {
    return "'" + parameterValue + "' is not a valid value for the parameter '" + parameterName + "'";
    }
    
    //public static func illegalArgumentInvalidParameterProjectRequestableFullSync(string projectParameter)->String
    //{
    //    return C8oExceptionMessage.illegalArgumentInvalidParameterValue(C8o.ENGINE_PARAMETER_PROJECT, projectParameter)->String +
    //    ", to run a fullSync request this parameter must start with '" + FullSyncInterface.FULL_SYNC_PROJECT + "'";
    //}
    
    public static func InvalidArgumentInvalidURL(urlStr: String)->String
    {
    return "'" + urlStr + "' is not a valid URL";
    }
    
    internal static func UnknownFullSyncPolicy(policy : NSObject?/*NSOFullSyncPolicy*/)->String
    {
        //return "Unknown the FullSync policy '" + policy + "'";
        return ""
    }
    
    public static func InvalidArgumentInvalidEndpoint(endpoint : String)->String
    {
    return "'" + endpoint + "' is not a valid Convertigo endpoint";
    }
    
    public static func InvalidRequestable(requestable : String)->String
    {
    return "'" + requestable + "' is not a valid requestable.";
    }
    
    public static func InvalidParameterType(parameterName : String, wantedParameterType : String, actualParameterType : String)->String
    {
    return "The parameter '" + parameterName + "' must be of type '" + wantedParameterType + "' and not '" + actualParameterType + "'";
    }
    
    public static func illegalArgumentIncompatibleListener(listenerType : String, responseType : String)->String
    {
    return "The listener type '" + listenerType + "' is incompatible with the response type '" + responseType + "'";
    }
    
    public static func InvalidArgumentNullParameter(parameterName : String)->String
    {
    return parameterName + " must be not null";
    }
    
    /** TAG Initialization */
    
    // TODO
    public static func InitError()->String
    {
    return "Unable to initialize ";
    }
    
    public static func InitRsaPublicKey()->String
    {
    return "Unable to initialize the RSA public key";
    }
    
    public static func InitCouchManager()->String
    {
    return "Unable to initialize the fullSync databases manager";
    }
    
    public static func InitSslSocketFactory()->String
    {
    return "Unable to initialize the ssl socket factory";
    }
    
    public static func InitDocumentBuilder()->String
    {
    return "Unable to initialize the XML document builder";
    }
    
    /** TAG Parse */
    
    public static func ParseStreamToJson()->String
    {
    return "Unable to parse the input stream to a json document";
    }
    
    public static func ParseStreamToXml()->String
    {
    return "Unable to parse the input stream to an xml document";
    }
    
    public static func parseInputStreamToString()->String
    {
    return "Unable to parse the input stream to a string";
    }
    
    public static func parseXmlToString()->String
    {
    return "Unable to parse the xml document to a string";
    }
    
    public static func parseRsaPublicKey()->String
    {
    return "Unable to parse the RSA public key";
    }
    
    public static func parseQueryEnumeratorToJson()->String
    {
    return "Unable to parse the query to a json document";
    }
    
    public static func parseLogsToJson()->String
    {
    return "Unable to parse logs to a json document";
    }
    
    public static func parseLogsStreamToJson()->String
    {
    return "Unable to parse stream containing logs response to a json document";
    }
    
    public static func parseC8oReplicationResultToJson()->String
    {
    return "Unable to parse the replication result to a json document";
    }
    
    public static func parseFullSyncDefaultResponseToJson()->String
    {
    return "Unable to parse the default fullSync result to a json document";
    }
    
    public static func parseFullSyncPostDocumentResponseToJson()->String
    {
    return "Unable to parse the post document fullSync result to a json document";
    }
    
    public static func parseStringToJson()->String
    {
    return "Unable to parse the string to a JSON document";
    }
    
    public static func ParseStringToObject(type : NSObject/*type*/)->String
    {
    return "Unable to parse the string (JSON)->String to an object of type " // + type;
    }
    
    public static func StringToJsonValue(str : String)->String
    {
    return "Unable to translate the string '" + str + "' to a JSON value";
    }
    
    public static func GetParameterJsonValue(parameter : Dictionary<String, NSObject>)->String
    {
        return "" //return "Unable to translate the string value '" + parameter.values + "' of the key + '" + parameter.keys + "' to a JSON value";
    }
    
    /** TAG HTTP */
    
    public static func retrieveRsaPublicKey()->String
    {
    return "Error during http request to get the RSA public key";
    }
    
    public static func httpLogs()->String
    {
    return "Error during http request to send logs to the Convertigo server";
    }
    
    /** TAG Couch */
    
    public static func couchRequestGetView()->String
    {
    return "Unable to run the view query";
    }
    
    public static func couchRequestAllDocuments()->String
    {
    return "Unable to run the all query";
    }
    
    public static func couchRequestResetDatabase()->String
    {
    return "Unable to run the reset query";
    }
    
    public static func couchRequestDeleteDocument()->String
    {
    return "Unable to run the delete document query";
    }
    
    public static func couchRequestInvalidRevision()->String
    {
    return "The revision is invalid";
    }
    
    public static func couchRequestPostDocument()->String
    {
    return "Unable to run the post document query";
    }
    
    public static func unableToGetFullSyncDatabase(databaseName : String)->String
    {
    return "Unable to get the fullSync database '" + databaseName + "' from the manager";
    }
    
    public static func couchNullResult()->String
    {
    return "An error occured during the fullSync request, its result is null";
    }
    
    public static func couchFullSyncNotActive()->String
    {
    return "Unable to use fullSync because it was not activated at the initialization";
    }
    
    public static func CouchDeleteFailed()->String
    {
    return "Delete the Couch document failed";
    }
    
    //public static func fullSyncPutProperties(Map<string, object> properties)->String
    //{
    //    return "Unable to put the following properties in the fullSync Document : " + properties;
    //}
    
    public static func fullSyncGetOrCreateDatabase(databaseName : String)->String
    {
    return "Unable to get or create the fullSync database '" + databaseName + "'";
    }
    
    //public static func fullSyncHandleRequest(string requestable, string databaseName, List<NameValuePair> parameters)->String
    //{
    //    return "Error while running the fullSync request, requestalbe='" + requestable + "', databaseName='" + databaseName + "', parameters=" + parameters;
    //}
    
    public static func fullSyncHandleResponse()->String
    {
    return "Error while handling the fullSync response";
    }
    
    /** TAG Certificate */
    
    public static func loadKeyStore()->String
    {
    return "Failed to load key store";
    }
    
    public static func trustAllCertificates()->String
    {
    return "Unable to load a key store trusting all certificates";
    }
    
    public static func clientKeyStore()->String
    {
    return "Unable to load the client key store";
    }
    
    public static func serverKeyStore()->String
    {
    return "Unable to load the server key store";
    }
    
    /** TAG Not found */
    
    public static func illegalArgumentNotFoundFullSyncView(viewName : String, databaseName : String)->String
    {
    return "Cannot found the view '" + viewName + "' in database '" + databaseName + "'";
    }
    
    /** TAG Other */
    
    public static func unhandledResponseType(responseType : String)->String
    {
    return "The response type '" + responseType + "' is not handled";
    }
    
    public static func unhandledListenerType(listenerType : String)->String
    {
    return "The listener type '" + listenerType + "' is not handled";
    }
    
    public static func WrongListener(c8oListener : C8oResponseListener)->String
    {
    return "" //"The C8oListener class " + C8oUtils.GetObjectClassName(c8oListener) + " is not handled";
    }
    
    //public static func wrongResult(Object result)->String
    //{
    //    return "The response class " + C8oUtils.getObjectClassName(result)->String + " is not handled";
    //}
    
    public static func toDo()->String
    {
    return "todo";
    }
    
    public static func unhandledFullSyncRequestable(fullSyncRequestableValue : String)->String
    {
    return "The fullSync requestable '" + fullSyncRequestableValue + "' is not handled";
    }
    
    public static func closeInputStream()->String
    {
    return "Unable to close the input stream";
    }
    
    public static func deserializeJsonObjectFromString(str : String)->String
    {
    return "Unable to deserialize the JSON object from the following string : '" + str + "'";
    }
    
    //public static func getNameValuePairObjectValue(NameValuePair nameValuePair)->String
    //{
    //    return "Unable to get the value from the NameValuePair with name '" + nameValuePair.getName()->String + "'";
    //}
    
    public static func postDocument()->String
    {
    return "Unable to post document";
    }
    
    public static func getNameValuePairObjectValue(name : String)->String
    {
    return "Unable to get the object value from the NameValuePair named '" + name + "'";
    }
    
    public static func queryEnumeratorToJSON()->String
    {
    return "Unable to parse the QueryEnumerato to a JSON document";
    }
    
    public static func queryEnumeratorToXML()->String
    {
    return "Unable to parse the QueryEnumerato to a XML document";
    }
    
    public static func addparametersToQuery()->String
    {
    return "Unable to add parameters to the fullSync query";
    }
    
    public static func putJson()->String
    {
    return "Failed to put data in JSON ...";
    }
    
    public static func changeEventToJson()->String
    {
    return "Failed to parse ChangeEvent to JSON document";
    }
    
    public static func initC8oSslSocketFactory()->String
    {
    return "Failed to initialize C8oSslSocketFactory";
    }
    
    public static func createSslContext()->String
    {
    return "failed to create a new SSL context";
    }
    
    public static func keyManagerFactoryInstance()->String
    {
    return "Failed to instanciate KeyManagerFactory";
    }
    
    public static func initKeyManagerFactory()->String
    {
    return "Failed to initialize the key manager factory";
    }
    
    public static func InitHttpInterface()->String
    {
    return "Failed to initialize the secure HTTP Interface";
    }
    
    public static func trustManagerFactoryInstance()->String
    {
    return "Failed to instanciate KeyManagerFactory";
    }
    
    public static func initTrustManagerFactory()->String
    {
    return "Failed to initialize the key manager factory";
    }
    
    public static func initSslContext()->String
    {
    return "Failed to initialize the SSL context";
    }
    
    public static func initCipher()->String
    {
    return "Failed to initialize the cipher";
    }
    
    public static func urlEncode()->String
    {
    return "Failed to URL encode prameters";
    }
    
    public static func getParametersStringBytes()->String
    {
    return "Failed to get parameters string bytes";
    }
    
    public static func encodeParameters()->String
    {
    return "Failed to encode parameters";
    }
    
    public static func RunHttpRequest()->String
    {
    return "Failed to run the HTTP request";
    }
    
    public static func generateRsaPublicKey()->String
    {
    return "Failed to generate RSA public key";
    }
    
    public static func keyFactoryInstance()->String
    {
    return "Failed to get KeyFactory instance";
    }
    
    public static func getCipherInstance()->String
    {
    return "Failed to get Cipher instance";
    }
    
    public static func entryNotFound(entryKey : String)->String
    {
    return "Entry key '" + entryKey + "' not found";
    }
    
    public static func c8oCallRequestToJson()->String
    {
    return "Failed to parse c8o call request to JSON";
    }
    
    public static func getJsonKey(key : String)->String
    {
    return "Failed to get the JSON key '" + key + "'";
    }
    
    public static func jsonValueToXML()->String
    {
    return "Failed to parse JSON value to XML";
    }
    
    public static func inputStreamToXML()->String
    {
    return "Failed to parse InputStream to an XML document";
    }
    
    public static func inputStreamReaderEncoding()->String
    {
    return "Failed to instanciate the InputStreamReader";
    }
    
    public static func readLineFromBufferReader()->String
    {
    return "Failed to read line from the BufferReader";
    }
    
    public static func GetLocalCacheParameters()->String
    {
    return "Failed to get local cache parameters";
    }
    
    public static func GetLocalCachePolicy(policy : String)->String
    {
    return "Failed to get local cache policy: " + policy;
    }
    
    public static func fullSyncJsonToXML()->String
    {
    return "Failed to translate full sync JSON to XML";
    }
    
    public static func takeLog()->String
    {
    return "Failed to take a log line in the list";
    }
    
    public static func remoteLogHttpRequest()->String
    {
    return "Failed while running the HTTP request sending logs to the Convertigo server";
    }
    
    public static func getInputStreamFromHttpResponse()->String
    {
    return "Failed to get InputStream from the HTTP response";
    }
    
    public static func inputStreamToJSON()->String
    {
    return "Failed to translate the input stream to a JSON document";
    }
    
    public static func httpInterfaceInstance()->String
    {
    return "Failed to instanciate the HTTP interface";
    }
    
    public static func FullSyncInterfaceInstance()->String
    {
    return "Failed to instanciate the FullSync interface";
    }
    
    public static func getDocumentFromDatabase(documentId  : String)->String
    {
    return "Failed to get fullSync document '" + documentId + "' from the database";
    }
    
    internal static func FullSyncReplicationFail(databaseName : String, way : String)->String
    {
    return "Failed to '" + way + "' replicate the '" + databaseName + "' database";
    }
    
    public static func localCachePolicyIsDisable()->String
    {
    return "Depending to the network state the local cache is disabled";
    }
    
    public static func localCacheDocumentJustCreated()->String
    {
    return "The local cache document is just created (empty)->String";
    }
    
    public static func illegalArgumentInvalidLocalCachePolicy(localCachePolicyString : String)->String
    {
    return "The local cache policy '" + localCachePolicyString + "' is invalid";
    }
    
    public static func timeToLiveExpired()->String
    {
    return "The time to live expired";
    }
    
    public static func InvalidLocalCacheResponseInformation()->String
    {
    return "Local cache response informations are invalid";
    }
    
    public static func overrideDocument()->String
    {
    return "Failed to override the fullSync document";
    }
    
    public static func handleFullSyncRequest()->String
    {
    return "Failed while running the fullSync request";
    }
    
    public static func serializeC8oCallRequest()->String
    {
    return "Failes to serialize the Convertigo call request";
    }
    
    public static func getResponseFromLocalCache()->String
    {
    return "Failed to get response from the local cache";
    }
    
    public static func getResponseFromLocalCacheDocument()->String
    {
    return "Failed to get response form the local cache document";
    }
    
    public static func handleC8oCallRequest()->String
    {
    return "Failed while runnig the c8o call request";
    }
    
    public static func saveResponseToLocalCache()->String
    {
    return "Failed to save the response to the local cache";
    }
    
    //	public static func illegalArgumentCallParametersNull()->String {
    //		return "Call parameters must be not null";
    //	}
    //
    //	public static func illegalArgumentCallC8oResponseListenerNull()->String {
    //		return "Call response listener must be not null";
    //	}
    
    public static func RemoteLogFail()->String
    {
    return "Failed to send log to the Convertigo server: disabling remote logging";
    }
    
    public static func FullSyncRequestFail()->String
    {
    return "Failed to process the fullsync request";
    }
    
    internal static func MissingLocalCacheResponseDocument()->String
    {
    return "Missing local cache response document";
    }
}