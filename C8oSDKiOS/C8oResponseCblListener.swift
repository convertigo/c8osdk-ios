//
//  C8oLocalCacheResponse.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 01/04/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import CouchbaseLite.All

public protocol C8oResponseCblListener: C8oResponseListener {
	
	func onDocumentResponse(_ document: CBLDocument, requestParameters: Dictionary<String, NSObject>)
	
	func onQueryEnumeratorResponse(_ queryEnumerator: CBLQueryEnumerator, requestParameters: Dictionary<String, NSObject>)
	
	// func onReplicationChangeEventResponse(changeEvent : , requestParameters : Dictionary<String, NSObject>)
}
