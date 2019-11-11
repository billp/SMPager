#
# Be sure to run `pod lib lint SMPager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SMPager'
  s.version          = '0.1.3'
  s.summary          = 'A lightweight, memory-efficient implementation of UIScrollView written in Swift.'
  s.swift_versions   = ["5.0"]
# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
SMPager or SimplePager is a lightweight, memory-efficient implementation of UIScrollView written in Swift. It works with reusable views the same way as UIKit's UITableView does.
                       DESC

  s.homepage         = 'https://github.com/billp/SMPager'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Bill Panagiotopoulos' => 'billp.dev@gmail.com' }
  s.source           = { :git => 'https://github.com/billp/SMPager.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'SMPager/Classes/**/*'
  
  # s.resource_bundles = {
  #   'SMPager' => ['SMPager/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
