//
//  C8oExceptionMessage.swift
//
//
//  Created by Charles Grimont on 18/02/2016.
//
//

import Foundation

internal class C8oExceptionMessage {
	
	internal static func notImplementedFullSyncInterface() -> String {
		return "You are using the default FullSyncInterface which is not implemented"
	}
	
	internal static func invalidParameterValue(_ parameterName: String, details: String? = nil) -> String {
		var errorMessage: String = "The parameter '" + parameterName + "' is invalid"
		if (details != nil) {
			errorMessage += ", " + details!
		}
		return errorMessage
	}
	
	internal static func missingValue(_ valueName: String) -> String {
		return "The " + valueName + " is missing"
	}
	
	internal static func unknownValue(_ valueName: String, value: String) -> String {
		return "The " + valueName + " value " + value + " is unknown"
	}
	
	internal static func unknownType(_ variableName: String, variable: NSObject) -> String {
		return "The " + variableName + " type " + C8oUtils.getObjectClassName(variable) + "is unknown"
	}
	
	internal static func ressourceNotFound(_ ressourceName: String) -> String {
		return "The " + ressourceName + " was not found"
	}
	
	internal static func toDo() -> String {
		return "TODO"
	}
	
	/** TAG Illegal argument */
	
	internal static func illegalArgumentInvalidFullSyncDatabaseUrl(_ fullSyncDatabaseUrlStr: String) -> String {
		return "The fullSync database url '" + fullSyncDatabaseUrlStr + "' is not a valid url"
	}
	
	internal static func FullSyncDatabaseInitFailed(_ databaseName: String) -> String {
		return "Failed to initialize the FullSync database '" + databaseName + "'"
	}
	
	internal static func MissParameter(_ parameterName: String) -> String {
		return "The parameter '" + parameterName + "' is missing"
	}
	
	fileprivate static func illegalArgumentInvalidParameterValue(_ parameterName: String, parameterValue: String) -> String {
		return "'" + parameterValue + "' is not a valid value for the parameter '" + parameterName + "'"
	}
	
	// internal static func illegalArgumentInvalidParameterProjectRequestableFullSync(string projectParameter)->String
	// {
	// return C8oExceptionMessage.illegalArgumentInvalidParameterValue(C8o.ENGINE_PARAMETER_PROJECT, projectParameter)->String +
	// ", to run a fullSync request this parameter must start with '" + FullSyncInterface.FULL_SYNC_PROJECT + "'"
	// }
	
	internal static func InvalidArgumentInvalidURL(_ urlStr: String) -> String {
		return "'" + urlStr + "' is not a valid URL"
	}
	
	internal static func UnknownFullSyncPolicy(_ policy: NSObject?/*NSOFullSyncPolicy*/) -> String {
		// return "Unknown the FullSync policy '" + policy + "'"
		return ""
	}
	
	internal static func InvalidArgumentInvalidEndpoint(_ endpoint: String) -> String {
		return "'" + endpoint + "' is not a valid Convertigo endpoint"
	}
	
	internal static func InvalidRequestable(_ requestable: String) -> String {
		return "'" + requestable + "' is not a valid requestable."
	}
	
	internal static func InvalidParameterType(_ parameterName: String, wantedParameterType: String, actualParameterType: String) -> String {
		return "The parameter '" + parameterName + "' must be of type '" + wantedParameterType + "' and not '" + actualParameterType + "'"
	}
	
	internal static func illegalArgumentIncompatibleListener(_ listenerType: String, responseType: String) -> String {
		return "The listener type '" + listenerType + "' is incompatible with the response type '" + responseType + "'"
	}
	
	internal static func InvalidArgumentNullParameter(_ parameterName: String) -> String {
		return parameterName + " must be not null"
	}
	
	/** TAG Initialization */
	
	// TODO
	internal static func InitError() -> String {
		return "Unable to initialize "
	}
	
	internal static func InitRsainternalKey() -> String {
		return "Unable to initialize the RSA internal key"
	}
	
	internal static func InitCouchManager() -> String {
		return "Unable to initialize the fullSync databases manager"
	}
	
	internal static func InitSslSocketFactory() -> String {
		return "Unable to initialize the ssl socket factory"
	}
	
	internal static func InitDocumentBuilder() -> String {
		return "Unable to initialize the XML document builder"
	}
	
	/** TAG Parse */
	
	internal static func ParseStreamToJson() -> String {
		return "Unable to parse the input stream to a json document"
	}
	
	internal static func ParseStreamToXml() -> String {
		return "Unable to parse the input stream to an xml document"
	}
	
	internal static func parseInputStreamToString() -> String {
		return "Unable to parse the input stream to a string"
	}
	
	internal static func parseXmlToString() -> String {
		return "Unable to parse the xml document to a string"
	}
	
	internal static func parseRsainternalKey() -> String {
		return "Unable to parse the RSA internal key"
	}
	
	internal static func parseQueryEnumeratorToJson() -> String {
		return "Unable to parse the query to a json document"
	}
	
	internal static func parseLogsToJson() -> String {
		return "Unable to parse logs to a json document"
	}
	
	internal static func parseLogsStreamToJson() -> String {
		return "Unable to parse stream containing logs response to a json document"
	}
	
	internal static func parseC8oReplicationResultToJson() -> String {
		return "Unable to parse the replication result to a json document"
	}
	
	internal static func parseFullSyncDefaultResponseToJson() -> String {
		return "Unable to parse the default fullSync result to a json document"
	}
	
	internal static func parseFullSyncPostDocumentResponseToJson() -> String {
		return "Unable to parse the post document fullSync result to a json document"
	}
	
	internal static func parseStringToJson() -> String {
		return "Unable to parse the string to a JSON document"
	}
	
	internal static func ParseStringToObject(_ type: NSObject/*type*/) -> String {
		return "Unable to parse the string (JSON)->String to an object of type " // + type
	}
	
	internal static func StringToJsonValue(_ str: String) -> String {
		return "Unable to translate the string '" + str + "' to a JSON value"
	}
	
	internal static func GetParameterJsonValue(_ parameter: Dictionary<String, NSObject>) -> String {
		return "" // return "Unable to translate the string value '" + parameter.values + "' of the key + '" + parameter.keys + "' to a JSON value"
	}
	
	/** TAG HTTP */
	
	internal static func retrieveRsainternalKey() -> String {
		return "Error during http request to get the RSA internal key"
	}
	
	internal static func httpLogs() -> String {
		return "Error during http request to send logs to the Convertigo server"
	}
	
	/** TAG Couch */
	
	internal static func couchRequestGetView() -> String {
		return "Unable to run the view query"
	}
	
	internal static func couchRequestAllDocuments() -> String {
		return "Unable to run the all query"
	}
	
	internal static func couchRequestResetDatabase() -> String {
		return "Unable to run the reset query"
	}
	
	internal static func couchRequestDeleteDocument() -> String {
		return "Unable to run the delete document query"
	}
	
	internal static func couchRequestInvalidRevision() -> String {
		return "The revision is invalid"
	}
	
	internal static func couchRequestPostDocument() -> String {
		return "Unable to run the post document query"
	}
	
	internal static func unableToGetFullSyncDatabase(_ databaseName: String) -> String {
		return "Unable to get the fullSync database '" + databaseName + "' from the manager"
	}
	
	internal static func couchNullResult() -> String {
		return "An error occured during the fullSync request, its result is null"
	}
	
	internal static func couchFullSyncNotActive() -> String {
		return "Unable to use fullSync because it was not activated at the initialization"
	}
	
	internal static func CouchDeleteFailed() -> String {
		return "Delete the Couch document failed"
	}
	
	internal static func fullSyncPutProperties(_ properties: Dictionary<String, AnyObject>) -> String {
		return "Unable to put the following properties in the fullSync Document : " + String(describing: properties)
	}
	
	internal static func fullSyncGetOrCreateDatabase(_ databaseName: String) -> String {
		return "Unable to get or create the fullSync database '" + databaseName + "'"
	}
	
	// internal static func fullSyncHandleRequest(string requestable, string databaseName, List<NameValuePair> parameters)->String
	// {
	// return "Error while running the fullSync request, requestalbe='" + requestable + "', databaseName='" + databaseName + "', parameters=" + parameters
	// }
	
	internal static func fullSyncHandleResponse() -> String {
		return "Error while handling the fullSync response"
	}
	
	/** TAG Certificate */
	
	internal static func loadKeyStore() -> String {
		return "Failed to load key store"
	}
	
	internal static func trustAllCertificates() -> String {
		return "Unable to load a key store trusting all certificates"
	}
	
	internal static func clientKeyStore() -> String {
		return "Unable to load the client key store"
	}
	
	internal static func serverKeyStore() -> String {
		return "Unable to load the server key store"
	}
	
	/** TAG Not found */
	
	internal static func illegalArgumentNotFoundFullSyncView(_ viewName: String, databaseName: String) -> String {
		return "Cannot found the view '" + viewName + "' in database '" + databaseName + "'"
	}
	
	/** TAG Other */
	
	internal static func unhandledResponseType(_ responseType: String) -> String {
		return "The response type '" + responseType + "' is not handled"
	}
	
	internal static func unhandledListenerType(_ listenerType: String) -> String {
		return "The listener type '" + listenerType + "' is not handled"
	}
	
	internal static func WrongListener(_ c8oListener: C8oResponseListener) -> String {
		return "" // "The C8oListener class " + C8oUtils.GetObjectClassName(c8oListener) + " is not handled"
	}
	
	internal static func wrongResult(_ result: AnyObject) -> String {
		return "The response class " + C8oUtils.getObjectClassName(result) + " is not handled"
	}
	
	internal static func todo() -> String {
		return "todo"
	}
	
	internal static func unhandledFullSyncRequestable(_ fullSyncRequestableValue: String) -> String {
		return "The fullSync requestable '" + fullSyncRequestableValue + "' is not handled"
	}
	
	internal static func closeInputStream() -> String {
		return "Unable to close the input stream"
	}
	
	internal static func deserializeJsonObjectFromString(_ str: String) -> String {
		return "Unable to deserialize the JSON object from the following string : '" + str + "'"
	}
	
	// internal static func getNameValuePairObjectValue(NameValuePair nameValuePair)->String
	// {
	// return "Unable to get the value from the NameValuePair with name '" + nameValuePair.getName()->String + "'"
	// }
	
	internal static func postDocument() -> String {
		return "Unable to post document"
	}
	
	internal static func getNameValuePairObjectValue(_ name: String) -> String {
		return "Unable to get the object value from the NameValuePair named '" + name + "'"
	}
	
	internal static func queryEnumeratorToJSON() -> String {
		return "Unable to parse the QueryEnumerato to a JSON document"
	}
	
	internal static func queryEnumeratorToXML() -> String {
		return "Unable to parse the QueryEnumerato to a XML document"
	}
	
	internal static func addparametersToQuery() -> String {
		return "Unable to add parameters to the fullSync query"
	}
	
	internal static func putJson() -> String {
		return "Failed to put data in JSON ..."
	}
	
	internal static func changeEventToJson() -> String {
		return "Failed to parse ChangeEvent to JSON document"
	}
	
	internal static func initC8oSslSocketFactory() -> String {
		return "Failed to initialize C8oSslSocketFactory"
	}
	
	internal static func createSslContext() -> String {
		return "failed to create a new SSL context"
	}
	
	internal static func keyManagerFactoryInstance() -> String {
		return "Failed to instanciate KeyManagerFactory"
	}
	
	internal static func initKeyManagerFactory() -> String {
		return "Failed to initialize the key manager factory"
	}
	
	internal static func InitHttpInterface() -> String {
		return "Failed to initialize the secure HTTP Interface"
	}
	
	internal static func trustManagerFactoryInstance() -> String {
		return "Failed to instanciate KeyManagerFactory"
	}
	
	internal static func initTrustManagerFactory() -> String {
		return "Failed to initialize the key manager factory"
	}
	
	internal static func initSslContext() -> String {
		return "Failed to initialize the SSL context"
	}
	
	internal static func initCipher() -> String {
		return "Failed to initialize the cipher"
	}
	
	internal static func urlEncode() -> String {
		return "Failed to URL encode prameters"
	}
	
	internal static func getParametersStringBytes() -> String {
		return "Failed to get parameters string bytes"
	}
	
	internal static func encodeParameters() -> String {
		return "Failed to encode parameters"
	}
	
	internal static func RunHttpRequest() -> String {
		return "Failed to run the HTTP request"
	}
	
	internal static func generateRsainternalKey() -> String {
		return "Failed to generate RSA internal key"
	}
	
	internal static func keyFactoryInstance() -> String {
		return "Failed to get KeyFactory instance"
	}
	
	internal static func getCipherInstance() -> String {
		return "Failed to get Cipher instance"
	}
	
	internal static func entryNotFound(_ entryKey: String) -> String {
		return "Entry key '" + entryKey + "' not found"
	}
	
	internal static func c8oCallRequestToJson() -> String {
		return "Failed to parse c8o call request to JSON"
	}
	
	internal static func getJsonKey(_ key: String) -> String {
		return "Failed to get the JSON key '" + key + "'"
	}
	
	internal static func jsonValueToXML() -> String {
		return "Failed to parse JSON value to XML"
	}
	
	internal static func inputStreamToXML() -> String {
		return "Failed to parse InputStream to an XML document"
	}
	
	internal static func inputStreamReaderEncoding() -> String {
		return "Failed to instanciate the InputStreamReader"
	}
	
	internal static func readLineFromBufferReader() -> String {
		return "Failed to read line from the BufferReader"
	}
	
	internal static func GetLocalCacheParameters() -> String {
		return "Failed to get local cache parameters"
	}
	
	internal static func GetLocalCachePolicy(_ policy: String) -> String {
		return "Failed to get local cache policy: " + policy
	}
	
	internal static func fullSyncJsonToXML() -> String {
		return "Failed to translate full sync JSON to XML"
	}
	
	internal static func takeLog() -> String {
		return "Failed to take a log line in the list"
	}
	
	internal static func remoteLogHttpRequest() -> String {
		return "Failed while running the HTTP request sending logs to the Convertigo server"
	}
	
	internal static func getInputStreamFromHttpResponse() -> String {
		return "Failed to get InputStream from the HTTP response"
	}
	
	internal static func inputStreamToJSON() -> String {
		return "Failed to translate the input stream to a JSON document"
	}
	
	internal static func httpInterfaceInstance() -> String {
		return "Failed to instanciate the HTTP interface"
	}
	
	internal static func FullSyncInterfaceInstance() -> String {
		return "Failed to instanciate the FullSync interface"
	}
	
	internal static func getDocumentFromDatabase(_ documentId: String) -> String {
		return "Failed to get fullSync document '" + documentId + "' from the database"
	}
	
	internal static func FullSyncReplicationFail(_ databaseName: String, way: String) -> String {
		return "Failed to '" + way + "' replicate the '" + databaseName + "' database"
	}
	
	internal static func localCachePolicyIsDisable() -> String {
		return "Depending to the network state the local cache is disabled"
	}
	
	internal static func localCacheDocumentJustCreated() -> String {
		return "The local cache document is just created (empty)->String"
	}
	
	internal static func illegalArgumentInvalidLocalCachePolicy(_ localCachePolicyString: String) -> String {
		return "The local cache policy '" + localCachePolicyString + "' is invalid"
	}
	
	internal static func timeToLiveExpired() -> String {
		return "The time to live expired"
	}
	
	internal static func InvalidLocalCacheResponseInformation() -> String {
		return "Local cache response informations are invalid"
	}
	
	internal static func overrideDocument() -> String {
		return "Failed to override the fullSync document"
	}
	
	internal static func handleFullSyncRequest() -> String {
		return "Failed while running the fullSync request"
	}
	
	internal static func serializeC8oCallRequest() -> String {
		return "Failes to serialize the Convertigo call request"
	}
	
	internal static func getResponseFromLocalCache() -> String {
		return "Failed to get response from the local cache"
	}
	
	internal static func getResponseFromLocalCacheDocument() -> String {
		return "Failed to get response form the local cache document"
	}
	
	internal static func handleC8oCallRequest() -> String {
		return "Failed while running the c8o call request"
	}
	
	internal static func saveResponseToLocalCache() -> String {
		return "Failed to save the response to the local cache"
	}
	
	// internal static func illegalArgumentCallParametersNull()->String {
	// return "Call parameters must be not null"
	// }
	//
	// internal static func illegalArgumentCallC8oResponseListenerNull()->String {
	// return "Call response listener must be not null"
	// }
	
	internal static func RemoteLogFail() -> String {
		return "Failed to send log to the Convertigo server: disabling remote logging"
	}
	
	internal static func FullSyncRequestFail() -> String {
		return "Failed to process the fullsync request"
	}
	
	internal static func MissingLocalCacheResponseDocument() -> String {
		return "Missing local cache response document"
	}
}
