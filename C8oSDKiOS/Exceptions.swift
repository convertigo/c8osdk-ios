//
//  Exceptions.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

open class C8oException: NSError {
	open static let NSC8oErrorDomain: String = "com.convertigo.clientsdk.exception.C8oException"
	open var message: String?
	
	public init(message: String, exception: NSError?) {
		self.message = message
		super.init(domain: C8oException.NSC8oErrorDomain, code: exception!.code, userInfo: [NSLocalizedFailureReasonErrorKey: message])
		
	}
	
	public init(message: String) {
		self.message = message
		super.init(domain: C8oException.NSC8oErrorDomain, code: 1, userInfo: [NSLocalizedFailureReasonErrorKey: message])
		
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	fileprivate static func filterMessage(_ message: String, exception: NSError) -> String {
		var message = message
		if (exception is C8oException) {
			message = String(describing: exception) + " | " + message
		}
		return message
	}
	
	fileprivate static func filterException(_ exception: NSError) -> NSError {
		/*if (exception is C8oException)
		 {
		 return null
		 }*/
		return exception
	}
}

open class C8oHttpException: NSError {
	public init(message: String, innerException: NSError) {
		super.init(domain: "com.convertigo.C8o.Error", code: C8oCode.c8oHttpException.rawValue as Int, userInfo: [NSLocalizedFailureReasonErrorKey: message])
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

open class C8oRessourceNotFoundException: C8oException {
	public override init(message: String, exception: NSError?) {
		super.init(message: message, exception: exception)
	}
	
	public override init(message: String) {
		super.init(message: message)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

open class c8oCouchbaseLiteException: C8oException {
	public override init(message: String, exception: NSError?) {
		super.init(message: message, exception: exception)
	}
	
	public override init(message: String) {
		super.init(message: message)
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}

open class C8oUnavailableLocalCacheException: NSError {
	
	public init(message: String) {
		super.init(domain: "com.convertigo.C8o.Error", code: C8oCode.c8oUnavailableLocalCacheException.rawValue as Int, userInfo: [NSLocalizedFailureReasonErrorKey: message])
	}
	
	required public init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
} }

public enum C8oError: Error {
	
	case invalidArgument(String)
	case argumentException(String)
	case c8oException(String)
	case argumentNilException(String)
	
}

public enum C8oCode: Int {
	case c8oUnavailableLocalCacheException = -6000
	case c8oRessourceNotFoundException = -6001
	case c8oHttpException = -6002
	case invalidArgument = -6003
	case argumentException = -6004
	case c8oException = -6005
	
}

