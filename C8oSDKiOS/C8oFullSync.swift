//
//  C8oFullSync.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

internal class C8oFullSync: NSObject {
	internal static var FULL_SYNC_URL_PATH: String = "/fullsync/";
	/**
    The project requestable value to execute a fullSync request.
	*/
	internal static var FULL_SYNC_PROJECT: String = "fs://";
	internal static var FULL_SYNC__ID: String = "_id";
	internal static var FULL_SYNC__REV: String = "_rev";
	internal static var FULL_SYNC__ATTACHMENTS: String = "_attachments";
	
	internal static var FULL_SYNC_DDOC_PREFIX: String = "_design";
	internal static var FULL_SYNC_VIEWS: String = "views";
	
	internal var c8o: C8o?;
	internal var fullSyncDatabaseUrlBase: String?
	internal var localSuffix: String?;
	
	internal init(c8o: C8o) {
		self.c8o = c8o;
		fullSyncDatabaseUrlBase = c8o.endpointConvertigo + C8oFullSync.FULL_SYNC_URL_PATH;
		localSuffix = (c8o.fullSyncLocalSuffix != nil) ? c8o.fullSyncLocalSuffix : "_device";
	}
	
	internal func handleFullSyncRequest(_ parameters_: Dictionary<String, Any>, listener: C8oResponseListener) throws -> Any? {
        let parameters = parameters_
        
		// Checks if this is really a fullSync request (even if this is normally already checked)
		let projectParameterValue = try! C8oUtils.peekParameterStringValue(parameters, name: C8o.ENGINE_PARAMETER_PROJECT, exceptionIfMissing: true);
		
		if (!projectParameterValue!.hasPrefix(C8oFullSync.FULL_SYNC_PROJECT)) {
			throw C8oException(message: C8oExceptionMessage.invalidParameterValue(projectParameterValue!, details: "its don't start with " + C8oFullSync.FULL_SYNC_PROJECT));
		}
		
		// Gets the sequence parameter to know which fullSync requestable to use
		let fullSyncRequestableValue: String = try! C8oUtils.peekParameterStringValue(parameters, name: C8o.ENGINE_PARAMETER_SEQUENCE, exceptionIfMissing: true)!;
		let fullSyncRequestable: FullSyncRequestable? = FullSyncRequestable.getFullSyncRequestable(fullSyncRequestableValue);
		if (fullSyncRequestable == nil) {
			throw C8oException(message: C8oExceptionMessage.invalidParameterValue(C8o.ENGINE_PARAMETER_PROJECT, details: C8oExceptionMessage.unknownValue("fullSync requestable", value: fullSyncRequestableValue)));
		}
		
		// Gets the database name if this is not specified then if takes the default database name
		let index1 = projectParameterValue!.characters.index(projectParameterValue!.startIndex, offsetBy: C8oFullSync.FULL_SYNC_PROJECT.characters.count)
		var databaseName: String? = projectParameterValue!.substring(from: index1)
		if (databaseName!.length < 1) {
			databaseName = c8o!.defaultDatabaseName;
			if (databaseName == nil) {
				throw C8oException(message: C8oExceptionMessage.invalidParameterValue(C8o.ENGINE_PARAMETER_PROJECT, details: C8oExceptionMessage.missingValue("fullSync database name")));
			}
		}
		
		var response: Any?;
		do {
			response = try fullSyncRequestable!.handleFullSyncRequest(self as! C8oFullSyncCbl, databaseNameName: databaseName!, parameters: parameters, c8oResponseListner: listener);
		}
		catch let e as C8oException {
			throw e
		}
		catch let e as NSError {
			throw C8oException(message: C8oExceptionMessage.FullSyncRequestFail(), exception: e);
		}
		
		if (response == nil) {
			throw C8oException(message: C8oExceptionMessage.couchNullResult());
		}
		
		response = try! handleFullSyncResponse(response!, listener: listener)
		return response;
	}
	
	internal func handleFullSyncResponse(_ response: Any, listener: C8oResponseListener) throws -> Any {
		var responseMutable = response
		if (responseMutable is JSON) {
			if (listener is C8oResponseXmlListener) {
				responseMutable = try! C8oFullSyncTranslator.fullSyncJsonToXml(responseMutable as! JSON)!;
			}
		} else if (responseMutable is C8oJSON) {
			if (listener is C8oResponseXmlListener) {
				responseMutable = try! C8oFullSyncTranslator.fullSyncJsonToXml((responseMutable as! C8oJSON).myJSON!)!;
			}
			
		}
		
		return responseMutable
		
	}
	
	internal static func isFullSyncRequest(_ requestParameters: Dictionary<String, Any>) -> Bool {
		// Check if there is one parameter named "__project" and if its value starts with "fs://"
		if let parameterValue: String = C8oUtils.getParameterStringValue(requestParameters, name: C8o.ENGINE_PARAMETER_PROJECT, useName: false) {
			return parameterValue.hasPrefix(C8oFullSync.FULL_SYNC_PROJECT);
		}
		return false;
		
	}
    
    internal func addFullSyncChangeListener(_ db: String, listener: C8oFullSyncChangeListener) throws {
    }
    
    internal func removeFullSyncChangeListener(_ db: String, listener: C8oFullSyncChangeListener) throws {
    }
}
