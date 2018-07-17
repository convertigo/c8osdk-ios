<p align="center">
  <img src="https://www.convertigo.com/wp-content/themes/EightDegree/images/logo_convertigo.png">
  <h2 align="center"> C8oSDK iOS</h2>
</p>
<p align="center">
  <a href="/LICENSE"><img src="https://img.shields.io/badge/License-Apache%202.0-blue.svg" alt="License"></a>
  <a href="https://travis-ci.org/convertigo/c8osdk-ios"><img
  src="https://travis-ci.org/convertigo/c8osdk-ios.svg?branch=master" alt="Travis Status"></a>
</a> 
</p>

## TOC ##

- [TOC](#toc)
- [Introduction](#introduction)
- [Requirements](#requirements)
- [Installation](#installation)
- [Documentation](#documentation)
	- [Initializing a Convertigo Enpoint](#initializing-a-convertigo-enpoint)
	- [Advanced instance settings](#advanced-instance-settings)
	- [Calling a Convertigo Requestable](#calling-a-convertigo-requestable)
	- [Call parameters](#call-parameters)
	- [Working with threads](#working-with-threads)
	- [Chaining calls](#chaining-calls)
	- [Handling failures](#handling-failures)
- [Building c8osdk-ios](#building-c8osdk-ios)

## Introduction ##
This is the Convertigo library for native swift iOS

Convertigo Client SDK is a set of libraries used by mobile or Windows desktop applications to access Convertigo Server services. An application using the SDK can easily access Convertigo services such as Sequences and Transactions.

The Client SDK will abstract the programmer from handling the communication protocols, local cache, FullSync off line data management, UI thread management and remote logging. So the developer can focus on building the application.

Client SDK is available for:
* [Android Native](https://github.com/convertigo/c8osdk-android) apps as a standard Gradle dependency
* [iOS native](https://github.com/convertigo/c8osdk-ios) apps as a standard Cocoapod
* [React Native](https://github.com/convertigo/react-native-c8osdk) as a NPM package
* [Google Angular framework](https://github.com/convertigo/c8osdk-angular) as typescript an NPM package
* [Vue.js](https://github.com/convertigo/c8osdk-js), [ReactJS](https://github.com/convertigo/c8osdk-js), [AngularJS](https://github.com/convertigo/c8osdk-js) Framework, or any [Javascript](https://github.com/convertigo/c8osdk-js) project as a standard Javascript NPM package
* Windows desktop or Xamarin apps as Nugets or Xamarin Components


This current package is the Native iOS SDK. For others SDKs see official Convertigo Documentation.

## Requirements ##

* Cocoapods >= 1.5.3
* Xcode >= 9.4


## Installation ##
Create a PodFile with :

    use_frameworks!

	target 'MyApp' do
	  pod 'C8oSDK', '2.3.3'
	end

run `pod install`

Restart Xcode and open the .xcworkspace

And there you go !

## Documentation ##

### Initializing a Convertigo Enpoint ###

For the .NET SDK, there is a common static initialization to be done before using the SDK feature. It prepares some platform specific features. After that, you will be able to create and use the C8o instance to interact with the Convertigo server and the Client SDK features. A C8o instance is linked to a server through is endpoint and cannot be changed after.  
You can have as many C8o instance,pointing to a same or different endpoint. Each instance handles its own session and settings. We strongly recommend using a single C8o instance per application because server licensing can based on the number of sessions used.

	import C8o

	// In swift there is two ways to handle errors :
	// We can either choose to don't care about errors using the following syntax (this may produce in case of error an "EXC_BAD_INSTRUCTION")

	let c8o : C8o = try! C8o(endpoint: "https://demo.convertigo.net/cems/projects/sampleMobileCtfGallery")
	
	// or we can choose to use do/catch syntax that will allow us to catch errors
	do{
		let c8o : C8o = try C8o(endpoint: "https://demo.convertigo.net/cems/projects/sampleMobileCtfGallery")
	}
	catch let e as NSError{
		print(e.description)
	}
	// the C8o instance is ready to interact over https with the demo.convertigo.net server, using sampleMobileUsDirectoryDemo as default project.
	
### Advanced instance settings ###

The endpoint is the mandatory setting to get a C8o instance, but there is additional settings through the C8oSettings class.  
A C8oSettings instance should be passed after the endpoint. Settings are copied inside the C8o instance and a C8oSettings instance can be modified and reused after the C8o constructor.  
Setters of C8oSettings always return its own instance and can be chained.  
A C8oSettings can be instantiated from an existing C8oSettings or C8o instance.
    
    import C8o
    // The common way
    var c8o : C8o = try! C8o(endpoint: "https://demo.convertigo.net/cems/projects/sampleMobileCtfGallery", c8oSettings: C8oSettings().setDefaultDatabaseName("mydb_fullsync").setTimeout(30000))
    
    // The verbose way
    let endpoint : String = "https://demo.convertigo.net/cems/projects/sampleMobileCtfGallery"
	let c8oSettings : C8oSettings = C8oSettings()
	c8oSettings.setDefaultDatabaseName("mydb_fullsync")
	c8oSettings.setTimeout(30000)
	c8o = try! C8o(endpoint: endpoint, c8oSettings: c8oSettings)
	
	// customize existing settings
	var customSettings : C8oSettings = C8oSettings(c8oSettings: c8oSettings).setTimeout(60000);
	// or from a C8o instance
	customSettings = C8oSettings(c8oSettings: c8o).setTimeout(60000);
	        
	// all settings can be retrieve from a C8o or C8oSettings instance
	let timeout : Int = c8o.timeout

### Calling a Convertigo Requestable ###

With a C8o instance you can call Convertigo Sequence and Transaction or make query to your local FullSync database. You must specify the result type you want: an XML Document or a JSON Object response.
  
Returning JSON:   
Just use the `c8o.callJson` method to request a JSON response.

	import SwiftyJSON

	// c8o is a C8o instance
	let jObject : JSON = try! c8o.callJson(".getSimpleData")!.sync()!

	// You now have JSON object that you can use in your app!

Returning XML:  
Just use the c8o.callXml method to request a XML response.

	import AEXML

	// c8o is a C8o instance
	let document : AEXMLDocument = try! c8o.callXml(".getSimpleData").sync()!

### Call parameters ###

The call method expects the requester string of the following syntax:

- For a transaction: [project].connector.transaction  
- For a sequence: [project].sequence


The project name is optional, i.e. if not specified, the project specified in the endpoint will be used.  
Convertigo requestables generally need key/value parameters. The key is always a string and the value can be any object but a string is the standard case.  
Here a sample with JSON but this would be the same for XML calls:

	// the common way with parameters
	let JObject : JSON = try! c8o.callJson(".getSimpleData",
	         	parameters:
	            "firstname", "John",
	            "lastname", "Do"
	)!.sync()!
	
	// the verbose way
	var parameters : Dictionary = Dictionary()
	parameters["firstname"] = "John"
	parameters["lastname"] = "Do"
	let JSONObject : JSON = try! c8o.callJson(".getSimpleData", parameters: parameters)!.sync()!
	
### Working with threads ###

Maybe you noticed that the calls methods doesn’t return the result directly and that all the sample code chains to the `.sync()` method.  
This is because the call methods return a `C8oPromise` instance. That allows the developer to choose if he wants to block the current thread, make an async request or get the response in a callback.  
The `.sync()` method locks the current thread and return the result as soon as it’s avalaible. Of course this should not be used in a UI thread as this will result to a frozen UI untill data is returned by the server. You should use the `.sync()` method only in worker threads.  


	// lock the current thread while the request is done
	let JSONObject : JSON = try! c8o.callJson(".getSimpleData")!.sync()!
	// the response can be used in this scope

As in many cases, locking the current thread is not recommended, the `.then()` method allows to register a callback that will be executed on a worker thread.  
The `.thenUI()` method does the same but the callback will be executed on a UI thread. This is useful for quick UI widgets updates.  
The `.then()` and `.thenUI()` callbacks receives as parameters the response and the request parameters.

  	// doesn't lock the current thread while the request is done
  	
	c8o.callJson(".getSimpleData")?.then({ (response, parameters) -> (C8oPromise?) in
		// the jObject is available, the current code is executed in an another working thread
			
		return nil // return nil for a simple call
	})
	
	// following lines are executed immediately, before the end of the request.
	        
	c8o.callJson(".getSimpleData")?.thenUI({ (response, parameters) -> (C8oPromise?) in
		// the jObject is available, the current code is executed in the UI thread
		self.simpleLabel.text = response.stringValue

		return nil // return nil for a simple call
	})
	
	// following lines are executed immediately, before the end of the request.
	
### Chaining calls ###

The `.then()` or `.thenUI()` returns a C8oPromise that can be use to chain other promise methods, such as `.then()` or `.thenUI()` or failure handlers.  
 The last `.then()` or `.thenUI()` must return a nil value. `.then()` or `.thenUI()` can be mixed but the returning type must be the same: XML or JSON.
 
	c8o.callJson(".getSimpleData", parameters: "callNumber", 1)?.then({ (response, parameters) -> (C8oPromise?) in
	    // you can do stuff here and return the next C8oPromise instead of deep nested blocks
	    return c8o.callJson(".getSimpleData", parameters: "callNumber", 2)
	})?.thenUI({ (response, parameters) -> (C8oPromise?) in
	    // you can do stuff here and even modify previous parameters
	    var parameters : [String : AnyObject]? = nil
	    parameters!["callNumber"] = 3
	    parameters!["extraParameter"] = "ok"
	    return c8o.callJson(".getSimpleData", parameters: parameters)
	})?.then({ (response, parameters) -> (C8oPromise?) in
	    // you can do stuff here and return nil because this is the end of the chain
	    return nil
	})

### Handling failures ###

A call can throw an error for many reasons: technical failure, network error and so on.  
The standard do/catch should be used to handle this.  
This is the case for the `.sync()` method: if an exception occurs during the request execution, the original exception is thrown by the method and can be encapsulated in a `C8oException`.

	do{
	    try c8o.callJson(".getSimpleData")!.sync()
	} catch let Exception as NSError{
	    // process the exception
	}
	
When you use the `.then()` or the `.thenUI()` methods, the do/catch mechanism can’t catch a “future” exception or throwable: you have to use the `.fail()` or `.failUI()` methods at the end on the promise chain.  
One fail handler per promise chain is allowed. The fail callback provide the object thrown (like an Exception) and the parameters of the failed request.


	c8o.callJson(".getSimpleData", parameters: "callNumber", 1)?.then({ (jObject, parameters) -> (C8oPromise?) in
    	return c8o.callJson(".getSimpleData", parameters: "callNumber", 2)
	})?.thenUI({ (response, parameters) -> (C8oPromise?) in
	    return nil
	})?.fail({ (exception, parameters) in
	    // exception catched from the first or the second CallJson, can be an Exception
	    // this code runs in a worker thread
	    //...
	})
	        
	c8o.callJson(".getSimpleData", parameters: "callNumber", 1)?.then({ (jObject, parameters) -> (C8oPromise?) in
	    return c8o.callJson(".getSimpleData", parameters: "callNumber", 2)
	})?.thenUI({ (jObject, parameters) -> (C8oPromise?) in
	    return nil
	})?.failUI({ (exception, parameters) in
	    // exception catched from the first or the second CallJson, can be an Exception
	    // this code runs in a UI thread
	    //...
	})

## Building c8osdk-ios ##

Please see the [wiki page](https://github.com/convertigo/c8osdk-ios/wiki)


    
