# The C8OSDK_VERSION variable will be defined by jenkins on Buildus.
# It is read from XCode: Target C8oSDKiOS, tab "General", "Version" field.

Pod::Spec.new do |s|
    s.name         = 'C8oSDK'
    s.module_name  = 'C8o'
    s.version      = C8OSDK_VERSION
    
    s.author       = 'Convertigo'
    s.license      = { :type => 'Enterprise License', :file  => 'LICENSE.txt' }
    
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
    
    s.source       = { :http => "http://download.convertigo.com/webrepository/sdk/ios/C8oSDKiOS-universal-#{C8OSDK_VERSION}.zip" }
    
    s.preserve_path       = 'C8o.framework'
    s.vendored_frameworks = 'C8o.framework'
    
    s.platform     = :ios, '8.0'
    
    # We can't enable bitcode because of some dependencies
    s.user_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }
    
    s.dependency 'SwiftyJSON', '2.3.2'
    s.dependency 'Alamofire', '3.1.5'
    s.dependency 'AEXML', '3.0.0'
end