# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

use_frameworks!
inhibit_all_warnings!

workspace 'KinMigrationModule'

target 'KinMigrationModule' do
  project 'KinMigrationModule/KinMigrationModule.xcodeproj'

  pod 'KinSDK'
  pod 'KinCoreSDK'
  pod 'StellarKit'
  pod 'StellarErrors'
  pod 'KinUtil'
  pod 'Sodium', '0.7.0'

  # Fixes the framework tests failing to build
  target 'KinMigrationModuleTests' do
    inherit! :search_paths
  end
end

target 'KinMigrationSampleApp' do
  project 'KinMigrationSampleApp/KinMigrationSampleApp.xcodeproj'

  pod 'KinMigrationModule', :path => './'
end