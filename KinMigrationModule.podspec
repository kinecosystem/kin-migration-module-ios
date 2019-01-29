Pod::Spec.new do |s|
  s.name         = 'KinMigrationModule'
  s.version      = '0.0.1'
  s.summary      = 'Pod for the Kin migration.'
  s.description  = 'Pod for the KinCore to KinSDK migration.'
  s.homepage     = 'https://github.com/kinecosystem/kin-migration-module-ios'
  s.license      = { :type => 'MIT', :file => 'LICENSE.md' }
  s.author       = { 'Kin Foundation' => 'kin@kik.com' }
  s.source       = { :git => 'https://github.com/kinecosystem/kin-migration-module-ios.git', :tag => "#{s.version}", :submodules => true }

  s.source_files = 'KinMigrationModule/KinMigrationModule/**/*.swift'

  s.dependency 'Sodium', '0.7.0'
  s.dependency 'KinSDK'
  s.dependency 'KinCoreSDK'

  s.ios.deployment_target = '8.0'
  s.swift_version = "4.2"
  s.platform = :ios, '8.0'
end
