# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

platform :ios, '10.0'

target 'kaamelott' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for kaamelott
  pod 'Alamofire', :git => 'https://github.com/Alamofire/Alamofire.git', :branch => '4.0.0'
  pod 'HanekeSwift', :git => 'https://github.com/Haneke/HanekeSwift.git', :branch => 'feature/swift-3'
  pod 'SwiftyMarkdown', :git => 'https://github.com/SimonFairbairn/SwiftyMarkdown', :branch => 'swift3'

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '3'
    end
  end
end
