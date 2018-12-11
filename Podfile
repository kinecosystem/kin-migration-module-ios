# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

use_frameworks!

workspace 'MigrationModule'

target 'MigrationModule' do
  project 'MigrationModule/MigrationModule.xcodeproj'

  pod 'KinSDK', :path => '../kin-sdk-ios/'
  pod 'KinCoreSDK', :path => '../kin-core-ios/'
  pod 'StellarKit', :path => '../kin-core-ios/KinSDK/StellarKit/'
  pod 'StellarErrors', :path => '../kin-core-ios/KinSDK/StellarKit/'
  pod 'Sodium'
end

target 'MigrationSampleApp' do
  project 'MigrationSampleApp/MigrationSampleApp.xcodeproj'

  pod 'KinSDK', :path => '../kin-sdk-ios/'
  pod 'KinCoreSDK', :path => '../kin-core-ios/'
  pod 'StellarKit', :path => '../kin-core-ios/KinSDK/StellarKit/'
  pod 'StellarErrors', :path => '../kin-core-ios/KinSDK/StellarKit/'
  pod 'Sodium'
end