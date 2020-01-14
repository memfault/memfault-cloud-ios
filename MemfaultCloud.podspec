#
# Be sure to run `pod lib lint MemfaultCloud.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'MemfaultCloud'
  s.version          = '1.0.0'
  s.summary          = 'MemfaultCloud Podspec'
  s.description      = <<-DESC
MemfaultCloud Podspec
                       DESC

  s.homepage         = 'https://github.com/memfault/memfault'
  s.license          = { :type => 'Modified BSD', :file => 'LICENSE' }
  s.author           = { 'Memfault' => 'hello@memfault.com' }
  s.source           = { :git => 'https://github.com/memfault/memfault-ios-cloud-sdk.git', :branch => 'master' }

  s.ios.deployment_target = '10.0'

  s.source_files = 'MemfaultCloud/Classes/**/*'
  
  s.public_header_files = 'MemfaultCloud/Classes/include/**/*.h'
  s.private_header_files = 'MemfaultCloud/Classes/*.h'
end
