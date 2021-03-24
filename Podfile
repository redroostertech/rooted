platform :ios, '11.0'

source 'https://github.com/CocoaPods/Specs.git'

def shared_pods
  pod 'SSSpinnerButton'
  pod 'Firebase/Core'
  pod 'Firebase/Auth'
  pod 'Firebase/Firestore'
  pod 'Firebase/Storage'
  pod 'FirebaseUI/Storage'
  pod 'Firebase/Analytics'
  pod 'Alamofire', '4.9.1'
  pod 'ObjectMapper', '~> 3.1'
  pod 'SwiftyCodeView'
  pod 'Branch'
  pod 'SwiftDate', '~> 5.0'
  pod 'FSCalendar'
  pod 'PhoneNumberKit', '~> 3.1'
  pod 'OnboardKit'
  pod 'FormTextField'
  pod 'WordPress-Editor-iOS'
  pod 'Gridicons'
  pod 'KeychainSwift'
  pod 'SwiftyRSA'
  pod 'RNCryptor', '~> 5.0'
  pod 'CalendarKit'
  pod 'CLTokenInputView'
  pod 'DateToolsSwift'
  pod 'EggRating', :git => 'https://github.com/redroostertech/EGGRating.git', :commit => 'ad32b475b74ef1aae896d8d8a6f96d0851ffdffb'
  pod 'EachNavigationBar', :git => 'https://github.com/redroostertech/EachNavigationBar.git', :branch => 'iMessage_Port'
  pod 'Eureka', :git => 'https://github.com/redroostertech/Eureka.git', :branch => 'iMessage_Port'
  pod 'Sheeeeeeeeet', :git => 'https://github.com/redroostertech/Sheeeeeeeeet.git', :branch => 'iMessage_Port'
end

target 'Rooted' do
  use_frameworks!
end

target 'Rooted-App' do
  use_frameworks!
  shared_pods
end

target 'Rooted MessagesExtension' do
  use_frameworks!
  shared_pods
  pod 'iMessageDataKit'
  
end
