require 'json'

package = JSON.parse(File.read(File.join(__dir__, 'package.json')))

Pod::Spec.new do |s|
  s.name = 'FitnessWorkoutBridge'
  s.version = package['version']
  s.summary = 'HealthKit + WatchConnectivity bridge for LR Training Pro'
  s.license = 'MIT'
  s.homepage = 'https://github.com/lucaripa/Fitness-Healtly'
  s.author = 'Luca Ripa'
  s.source = { :git => 'https://github.com/lucaripa/Fitness-Healtly.git', :tag => s.version.to_s }
  s.source_files = 'ios/Sources/WorkoutBridgePlugin/**/*.{swift,h,m,c,cc,mm,cpp}'
  s.ios.deployment_target = '15.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.1'
end
