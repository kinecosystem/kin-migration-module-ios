# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

use_frameworks!

workspace 'KinMigrationModule'

target 'KinMigrationModule' do
  project 'KinMigrationModule/KinMigrationModule.xcodeproj'

  pod 'KinSDK', :path => '../kin-sdk-ios/'
  pod 'KinCoreSDK', :path => '../kin-core-ios/'
  pod 'StellarKit', :path => '../kin-core-ios/KinSDK/StellarKit/'
  pod 'StellarErrors', :path => '../kin-core-ios/KinSDK/StellarKit/'
  pod 'Sodium'
end

target 'KinMigrationSampleApp' do
  project 'KinMigrationSampleApp/KinMigrationSampleApp.xcodeproj'

  pod 'KinMigrationModule', :path => './'
  pod 'KinSDK', :path => '../kin-sdk-ios/'
  pod 'KinCoreSDK', :path => '../kin-core-ios/'
end