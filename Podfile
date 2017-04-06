# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

platform :ios, '10.0'

target 'kaamelott' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for kaamelott
  pod 'Alamofire', :git => 'https://github.com/Alamofire/Alamofire.git', :branch => '4.0.0'
  pod 'EVReflection', :git => 'https://github.com/evermeer/EVReflection.git', :branch => 'Swift3.0'
  pod 'AlamofireJsonToObjects', :git => 'https://github.com/evermeer/AlamofireJsonToObjects.git', :branch => 'Swift3'
  pod 'HanekeSwift', :git => 'https://github.com/Haneke/HanekeSwift.git', :branch => 'feature/swift-3'

  #pod 'Alamofire', :git => 'https://github.com/Alamofire/Alamofire.git', :tag => '4.4.0'
  #pod 'EVReflection', :git => 'https://github.com/evermeer/EVReflection.git', :branch => 'Swift3.0'
  #pod 'AlamofireJsonToObjects', :git => 'https://github.com/evermeer/AlamofireJsonToObjects.git', :branch => 'Swift3'
  #pod 'HanekeSwift', :git => 'https://github.com/Haneke/HanekeSwift.git', :branch => 'feature/swift-3'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3'
    end
  end
end
