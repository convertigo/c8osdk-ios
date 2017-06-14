# The C8OSDK_VERSION variable will be defined by jenkins on Buildus.
# It is read from XCode: Target C8oSDKiOS, tab "General", "Version" field.

Pod::Spec.new do |s|
    s.name         = 'C8oSDK'
    s.module_name  = 'C8o'
    s.version      = '2.2.0-beta1'
    
    s.author       = 'Convertigo'
    s.license      = 'Apache License 2.0'
    
    s.summary      = 'Convertigo client SDK for iOS.'
    s.description  = <<-DESC
    Convertigo Client SDK is a set of native libraries used by iOS applications to access Convertigo mBaaS services.
    An application using the SDK can easily access Convertigo services such as Sequences and Transactions.
    
    Enterprises will use the Client SDK to abstract the programmer from handling the communication protocols, local cache, FullSync offline data management, UI thread management and remote logging.
    So the developer can focus on building the application.
    DESC
    
    s.homepage     = 'http://www.convertigo.com/convertigo-sdk/'
    documentation_url = 'http://www.convertigo.com/document/convertigo-client-sdk/'
    social_media_url  = 'https://twitter.com/convertigo'
    
    s.source           = { :git => 'https://github.com/convertigo/C8oSDKiOS.git' }
    s.source_files = 'C8oSDKiOS/*.{swift,h}', 'C8oSDKiOS/Internal/*.{swift,h,a}'
    
    s.platform     = :ios, '8.0'
    
    s.dependency 'SwiftyJSON', '3.1.4'
    s.dependency 'Alamofire', '4.4.0'
    s.dependency 'AEXML', '4.1.0'
    s.dependency 'couchbase-lite-ios', '1.4.0'
    s.dependency 'couchbase-lite-ios/ForestDB', '1.4.0'
end
