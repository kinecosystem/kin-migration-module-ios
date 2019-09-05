Pod::Spec.new do |s|
  s.name         = 'KinMigrationModule'
  s.version      = '0.1.3'
  s.summary      = 'Pod for the Kin migration.'
  s.description  = 'Pod for the KinCore to KinSDK migration.'
  s.homepage     = 'https://github.com/kinecosystem/kin-migration-module-ios'
  s.license      = { :type => 'Kin Ecosystem SDK License' }
  s.author       = { 'Kin Foundation' => 'info@kin.org' }
  s.source       = { :git => 'https://github.com/kinecosystem/kin-migration-module-ios.git', :tag => "#{s.version}", :submodules => true }

  s.source_files = 'KinMigrationModule/KinMigrationModule/**/*.swift'

  s.dependency 'Sodium', '0.8.0'
  s.dependency 'KinSDK', '0.9.2'
  s.dependency 'KinCoreSDK', '0.8.1'

  s.ios.deployment_target = '8.0'
  s.swift_version = "5.0"
  s.platform = :ios, '8.0'
end
