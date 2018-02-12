# Decrypt certificate
openssl aes-256-cbc -k "$SECURITY_PASSWORD" -in scripts/certs/ios_development.cer.enc -d -a -out scripts/certs/ios_development.cer
# Decrypt p12
openssl aes-256-cbc -k "$SECURITY_PASSWORD" -in scripts/certs/Certificats.p12.enc -d -a -out scripts/certs/Certificats.p12
# Create custom keychain
security create-keychain -p "$CUSTOM_KEYCHAIN_PASSWORD" ios-build.keychain
# Make the ios-build.keychain default, so xcodebuild will use it
security default-keychain -s ios-build.keychain
# Unlock the keychain
security unlock-keychain -p "$CUSTOM_KEYCHAIN_PASSWORD" ios-build.keychain
# Set keychain timeout to 1 hour for long builds
# see here
security set-keychain-settings -t 3600 -l ~/Library/Keychains/ios-build.keychain
security import ./scripts/certs/AppleWWDRCA.cer -k ios-build.keychain -A
security import ./scripts/certs/ios_development.cer -k ios-build.keychain -A
security import ./scripts/certs/Certificats.p12 -k ios-build.keychain -P $SECURITY_PASSWORD -A
# Fix for OS X Sierra that hungs in the codesign step
security set-key-partition-list -S apple-tool:,apple: -s -k $SECURITY_PASSWORD ios-build.keychain > /dev/null
