Pod::Spec.new do |s|

  s.name             = 'ImpressionKit-OC'
  s.version          = '0.0.2'
  s.summary          = 'This is a library to analyze impression events for UIView in iOS (exposure of UIView).'
  s.homepage         = 'https://github.com/Dwarven/ImpressionKit-OC'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Dwarven' => 'prison.yang@gmail.com' }
  s.platform         = :ios, '11.0'
  s.swift_versions   = '5'
  s.default_subspecs = 'Core'
  s.source           = { :git => 'https://github.com/Dwarven/ImpressionKit-OC.git', :tag => s.version }
  s.requires_arc     = true

  s.subspec 'Core' do |ss|
    ss.framework     = 'UIKit'
    ss.source_files  = 'ImpressionKit-OC/*.{h,m}'
  end

  s.subspec 'SwiftUI' do |ss|
    ss.dependency      'ImpressionKit-OC/Core'
    ss.source_files  = 'ImpressionKit-OC/*.swift'
  end

end
