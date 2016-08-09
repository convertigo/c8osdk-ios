# Convertigo SDK for iOS #
Convertigo Mobility Platform supports native iOS developpers. Services brought by the platform are available for iOS clients applications thanks to the Convertigo MBaaS SDK. SDK provides a iOS framework you can use to access Convertigo Server’s services such as:

- Connectors to back-end data (SQL, NoSQL, REST/SOAP, SAP, - WEB HTML, AS/400, Mainframes)
- Server Side Business Logic (Protocol transform, Business logic augmentation, ...)
- Automatic offline replicated databases with FullSync technology
- Security and access control (Identity managers, LDAP , SAML, oAuth)
- Server side Cache
- Push notifications (APND, GCM)
- Auditing Analytics and logs (SQL, and Google Analytics)

Download Convertigo Technology Overview :

 [http://download.convertigo.com/webrepository/Marketing/ConvertigoTechnologyOverview.pdf](http://download.convertigo.com/webrepository/Marketing/ConvertigoTechnologyOverview.pdf "Overview")

Access Convertigo mBaaS technical documentation :

[ http://www.convertigo.com/document/latest/]( http://www.convertigo.com/document/latest/ "Documentation")

Access Convertigo SDK Documentations :

[ http://www.convertigo.com/document/latest/reference-manual/Convertigo-SDK/]( http://www.convertigo.com/document/latest/reference-manual/Convertigo-SDK/)

## Installation ##
Create a PodFile with :

    use_frameworks!

	target 'C8oSDKiOS' do
	  pod 'C8oSDK', '2.0.4'
	end

run `pod install`

Restart Xcode and open the .xcworkspace

And there you go !

## Sample code ##

Initializing a Convertigo Enpoint:

	import C8o

	// In swift there is two ways to handle errors :
	// We can either choose to don't care about errors using the following syntax (this may produce in case of error an "EXC_BAD_INSTRUCTION")

	let c8o : C8o = try! C8o(endpoint: "https://demo.convertigo.net/cems/projects/sampleMobileCtfGallery", c8oSettings: nil)
	
	// or we can choose to use do/catch syntax that will allow us to catch errors
	do{
		let c8o : C8o = try C8o(endpoint: "https://demo.convertigo.net/cems/projects/sampleMobileCtfGallery", c8oSettings: nil)
	}
	catch let e as NSError{
		print(e.description)
	}
	// the C8o instance is ready to interact over https with the demo.convertigo.net server, using sampleMobileUsDirectoryDemo as default project.


Calling a Convertigo Requestable:

	import SwiftyJSON

	// c8o is a C8o instance
	let JObject : JSON = try! c8o.callJson(".getSimpleData")!.sync()!

	// You now have JSON objecct that you can use in your app!

## More information ##
Please see about other SDKs for .NET (Xamarin):

[https://components.xamarin.com/view/convertigo-mbaas](https://components.xamarin.com/view/convertigo-mbaas "Xamarin")

For .NET

[https://www.nuget.org/packages/C8oFullSyncExtensions/](https://www.nuget.org/packages/C8oFullSyncExtensions/)

    