//
//  C8oBase.swift
//  C8oSDKiOS
//
//  Created by Charles Grimont on 04/02/2016.
//  Copyright © 2016 Convertigo. All rights reserved.
//

import Foundation

open class C8oBase: NSObject {
	override init() {
		super.init()
	}
	
	// *** HTTP ***//
	internal var _timeout: Int? = -1
	internal var _trustAllCertificates: Bool? = false
	internal var _cookies: Dictionary<String, String>?
	public typealias Byte = UInt8?
	internal var _clientCertificateBinaries: Dictionary<UInt8, String>?
	internal var _clientCertificateFiles: Dictionary<String, String>?
	
	// *** Log ***//
	internal var _logRemote: Bool? = true
	internal var _logLevelLocal: C8oLogLevel = C8oLogLevel.none
	internal var _logC8o: Bool? = true
	internal var _logOnFail: ((_ exception: C8oException, _ parameters: Dictionary<String, NSObject>?) -> (Void))? = nil
	
	// *** FullSync ***//
	internal var _defaultDatabaseName: String?
	internal var _authenticationCookieValue: String?
	internal var _fullSyncLocalSuffix: String?
    internal var _fullSyncStorageEngine: String = C8o.FS_STORAGE_SQL
    internal var _fullSyncEncryptionKey: String?
	internal var _fullSyncServerUrl: String = "http://localhost:5984"
	internal var _fullSyncUsername: String?
	internal var _fullSyncPassword: String?
	
	// *** Encryption ***//
	
	internal var _useEncryption: Bool?
	
	// *** Getter ***//
	
	/**
	 Gets the connection timeout to Convertigo in milliseconds. A value of zero means the timeout is not used (Default is 0).
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 timeout : Int = myC8o.Timeout
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @return The timeout.
	 */
	open var timeout: Int {
		get { return _timeout! }
	}
	
	/**
	 Gets a value indicating whether https calls trust all certificates or not. (Default is false).
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 trustAllCertificates : Bool = myC8o.TrustAllCetificates
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @return <c>true</c> if https calls trust all certificates otherwise, <c>false</c>.
	 */
	open var trustAllCertificates: Bool {
		get { return _trustAllCertificates! }
	}
	
	/**
	 Gets initial cookies to send to the Convertigo server (Default is <c>null</c>).
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 cookies : Dictionary<String, String>? = myC8o.Cookies
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @return A collection of cookies.
	 */
	open var cookies: Dictionary<String, String>? {
		get { return _cookies }
	}
	
	/**
	 Gets the client certificate binaries.
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 clientCertificateBinaries : Dictionary<UInt8, String>? = myC8o.ClientCertificateBinaries
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @return A Dictionary of client certificate binaries
	 */
	open var clientCertificateBinaries: Dictionary<UInt8, String>? {
		get { return _clientCertificateBinaries! }
	}
	
	/**
	 Gets the client certificate files.
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 clientCertificateFiles : Dictionary<String, String>? = myc8o.ClientCertificateFiles
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @return A Dictionary of client certificate files
	 */
	open var clientCertificateFiles: Dictionary<String, String>? {
		get { return _clientCertificateFiles }
	}
	
	/**
	 Gets a value indicating if logs are sent to the Convertigo server.
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 logRemote : Bool = myC8o.LogRemote
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @return <c>true</c> if logs are sent to the Convertigo server otherwise, <c>false</c>
	 */
	open var logRemote: Bool {
		get { return _logRemote! }
	}
	
	/**
	 Gets a value indicating the log level you want in the device console.
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 logLevelLocal : Bool = myC8o.LogLevelLocal
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @return <c>true</c> if logs are sent to the Convertigo server otherwise, <c>false</c>.
	 */
	open var logLevelLocal: C8oLogLevel {
		get { return _logLevelLocal }
	}
	
	/**
	 Gets a value indicating if C8o is log.
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 logC8o : Bool = myC8o.LogC8o
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @return <c>true</c> if c8o is log otherwise, <c>false</c>.
	 */
	open var logC8o: Bool {
		get { return _logC8o! }
	}
	
	/**
	 Gets the log on failure.
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 logOnFail : NSObject = myC8o.LogOnFail
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @return NSObject.
	 */
	open var logOnFail: ((_ exception: C8oException, _ parameters: Dictionary<String, NSObject>?) -> (Void))? {
		get { return _logOnFail }
	}
	
	/**
	 Gets the default database's name.
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 defaultDatabaseName : String = myC8o.DefaultDatabaseName
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @return A string containing the default database's name.
	 */
	open var defaultDatabaseName: String {
		get {
			return _defaultDatabaseName!
		}
	}
	
	/**
	 Gets the authentification cookie value.
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 authenticationCookieValue : String = myC8o.AuthenticationCookieValue
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @return A string containing the authentification cookie value.
	 */
	open var authenticationCookieValue: String {
		get { return _authenticationCookieValue! }
	}
	
	/**
	 Gets the fullSync local suffix.
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 fullSyncLocalSuffix : String = myC8o.FullSyncLocalSuffix
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @return A string containing the fullSync local suffix.
	 */
	open var fullSyncLocalSuffix: String? {
		get { return _fullSyncLocalSuffix }
	}
	
    open var fullSyncStorageEngine: String {
        get { return _fullSyncStorageEngine }
    }
    
    open var fullSyncEncryptionKey: String? {
        get { return _fullSyncEncryptionKey }
    }
    
	/**
	 Gets the fullSync server url.
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 fullSyncServerUrl : String = myC8o.FullSyncServerUrl
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @return A string containing the fullSync server url.
	 */
	open var fullSyncServerUrl: String {
		get { return _fullSyncServerUrl }
	}
	
	/**
	 Gets the fullSync username.
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 fullSyncUsername : String = myC8o.FullSyncUsername
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @return A string containing the fullSync username.
	 */
	open var fullSyncUsername: String {
		get { return _fullSyncUsername! }
	}
	
	/**
	 Gets the fullSync password.
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 fullSyncPassword : String = myC8o.FullSyncPassword
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @return A string containing the fullSync password.
	 */
	open var fullSyncPassword: String {
		get { return _fullSyncPassword! }
	}
	
	/**
	 Copy any c8oBase object into another.
	 Example usage:
	 @code
	 myc8o : C8o = C8o()
	 mySecondC8o : C8o
	 mySecondC8o.Copy(myC8o)
	 @endcode
	 @see http://www.convertigo.com/document/convertigo-client-sdk/programming-guide/ for more information.
	 @param c8oBase
	 any C8oBase object that yout wants to copy
	 @return Void.
	 */
	internal func copyProperties (_ c8oBase: C8oBase) -> Void {
		// *** HTTP ***//
		
		_timeout = c8oBase._timeout
		_trustAllCertificates = c8oBase._trustAllCertificates
		
		if (c8oBase._cookies != nil) {
			if (_cookies == nil) {
				_cookies = NSObject() as? Dictionary<String, String>// CookieCollection()
			}
			// cookies.Add(c8oBase.cookies)
		}
		
		if (c8oBase._clientCertificateBinaries != nil) {
			if (_clientCertificateBinaries == nil) {
				_clientCertificateBinaries = c8oBase._clientCertificateBinaries
			} else {
				for entry in c8oBase._clientCertificateBinaries! {
					
					_clientCertificateBinaries?.updateValue(entry.1, forKey: entry.0)
				}
			}
		}
		
		if (c8oBase._clientCertificateFiles != nil) {
			if (_clientCertificateFiles == nil) {
				_clientCertificateFiles = c8oBase._clientCertificateFiles
			} else {
				for entry in c8oBase._clientCertificateFiles! {
					_clientCertificateFiles?.updateValue(entry.1, forKey: entry.0)
				}
			}
		}
		
		// *** Log ***//
		
		_logRemote = c8oBase._logRemote
		_logLevelLocal = c8oBase._logLevelLocal
		_logC8o = c8oBase._logC8o
		_logOnFail = c8oBase._logOnFail
		
		// *** FullSync ***//
		
		_defaultDatabaseName = c8oBase._defaultDatabaseName
		_authenticationCookieValue = c8oBase._authenticationCookieValue
		_fullSyncLocalSuffix = c8oBase._fullSyncLocalSuffix
        _fullSyncStorageEngine = c8oBase._fullSyncStorageEngine
        _fullSyncEncryptionKey = c8oBase._fullSyncEncryptionKey
        
		_fullSyncServerUrl = c8oBase._fullSyncServerUrl
		_fullSyncUsername = c8oBase._fullSyncUsername
		_fullSyncPassword = c8oBase._fullSyncPassword
		
		// uiDispatcher = c8oBase.uiDispatcher
	}
}
