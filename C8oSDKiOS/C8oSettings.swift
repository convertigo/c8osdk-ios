//
//  C8oSettings.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 18/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

open class C8oSettings: C8oBase {
	public override init() {
	}
	
	public init(c8oSettings: C8oBase) {
		super.init()
		copyProperties(c8oSettings)
	}
	
	open func clone() -> C8oSettings {
		return C8oSettings(c8oSettings: self)
	}
	
	/**
	 Sets the connection timeout to Convertigo in milliseconds. A value of zero means the timeout is not used.<br/>
	 Default is <b>0</b>.
	 Example usage:
	 C8oSettings().setTimeout(100)
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @param timeout : Int
	 @return The current <b>C8oSettings</b>, for chaining.

	 */
	open func setTimeout(_ timeout: Int) -> C8oSettings {
		var timeout = timeout
		if (timeout <= 0) {
			timeout = -1
		}
		_timeout = timeout
		return self
	}
	
	/**
	 Sets a value indicating whether https calls trust all certificates or not.<br/>
	 Default is <b>false</b>.
	 Example usage:
	 C8oSettings().setTrustAllCertificates(true)
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @param trustAllCertificates : Bool
	 @return The current <b>C8oSettings</b>, for chaining.

	 */
	open func setTrustAllCertificates(_ trustAllCertificates: Bool) -> C8oSettings {
		_trustAllCertificates = trustAllCertificates
		return self
	}
	
	open func addClientCertificate(_ certificate: Byte, password: String) -> C8oSettings {
		if (_clientCertificateBinaries == nil) {
			//_clientCertificateBinaries = Dictionary<AnyHashable, String>?(certificate , password)
		}
		// clientCertificateBinaries = [certificate! as NSObject: password]
		
		return self
	}
	
	open func addClientCertificate(_ certificatePath: String, password: String) -> C8oSettings {
		if (_clientCertificateFiles == nil) {
			_clientCertificateFiles = Dictionary<String, String>()
		}
		_clientCertificateFiles = [certificatePath: password]
		
		return self
	}
	
	/**
	 Add a new cookie to the initial cookies send to the Convertigo server.
	 Example usage:
	 C8oSettings().setTrustAllCertificates("username", value : "Convertigo")
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @param name : String
	 @param value : String
	 @return The current <b>C8oSettings</b>, for chaining.

	 */
	open func addCookie(_ name: String, value: String) -> C8oSettings {
		
		if (_cookies == nil) {
			_cookies = Dictionary<String, String>()
		}
		_cookies = [name: value]
		
		return self
	}
	
	/**
	 Add a new cookie to the initial cookies send to the Convertigo server.
	 Example usage:
	 C8oSettings().setTrustAllCertificates("username", value : "Convertigo")
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @param name : String
	 @param value : String
	 @return The current <b>C8oSettings</b>, for chaining.

	 */
	open func setLogRemote(_ logRemote: Bool) -> C8oSettings {
		_logRemote = logRemote
		return self
	}
	
	open func setLogLevelLocal(_ logLevelLocal: C8oLogLevel) -> C8oSettings {
		_logLevelLocal = logLevelLocal
		return self
	}
	
	open func setLogC8o(_ logC8o: Bool) -> C8oSettings {
		_logC8o = logC8o
		return self
	}
	
	open func setLogOnFail(_ logOnFail: ((_ exception: C8oException, _ parameters: Dictionary<String, NSObject>?) -> (Void))?) -> C8oSettings {
		_logOnFail = logOnFail
		return self
	}
	/**
	 pecify the default FullSync database name. Must match a Convertigo Server
	 FullSync connector name
	 */
	open func setDefaultDatabaseName(_ defaultDatabaseName: String) -> C8oSettings {
		_defaultDatabaseName = defaultDatabaseName
		return self
	}
	
	open func setAuthenticationCookieValue(_ authenticationCookieValue: String) -> C8oSettings {
		_authenticationCookieValue = authenticationCookieValue
		return self
	}
	
	open func setFullSyncServerUrl(_ fullSyncServerUrl: String) -> C8oSettings {
		_fullSyncServerUrl = fullSyncServerUrl
		return self
	}
	
	open func setFullSyncUsername(_ fullSyncUsername: String) -> C8oSettings {
		_fullSyncUsername = fullSyncUsername
		return self
	}
	
	open func setFullSyncPassword(_ fullSyncPassword: String) -> C8oSettings {
		_fullSyncPassword = fullSyncPassword
		return self
	}
	
	open func setFullSyncLocalSuffix(_ fullSyncLocalSuffix: String) -> C8oSettings {
		_fullSyncLocalSuffix = fullSyncLocalSuffix
		return self
    }
    
    open func setFullSyncStorageEngine(_ fullSyncStorageEngine: String) -> C8oSettings {
        if (C8o.FS_STORAGE_SQL == fullSyncStorageEngine || C8o.FS_STORAGE_FORESTDB == fullSyncStorageEngine) {
            _fullSyncStorageEngine = fullSyncStorageEngine
        }
        return self
    }
    
    open func setFullSyncEncryptionKey(_ fullSyncEncryptionKey: String) -> C8oSettings {
        _fullSyncEncryptionKey = fullSyncEncryptionKey
        return self
    }
	
	open func setUseEncryption(_ useEncryption: Bool) -> C8oSettings {
		_useEncryption = useEncryption
		return self
	}
}
