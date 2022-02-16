Pod::Spec.new do |s|
		s.name 				= "CombineTestExtensions"
		s.version 			= "0.1.0"
		s.summary         	= "A set of tools making writing tests for Apple's Combine framework easy. Inspired by RxTest and RxBlocking."
	    s.homepage        	= "https://github.com/amine2233/CombineTestExtensions"
	    s.license           = { type: 'MIT', file: 'LICENSE' }
	    s.ios.deployment_target = '13.0'
	    s.osx.deployment_target = '10.15'
	    s.tvos.deployment_target = '13.0'
	    s.watchos.deployment_target = '6.0'
	    s.requires_arc = true
	    s.source            = { :git => "https://github.com/amine2233/CombineTestExtensions.git", :tag => s.version.to_s }
		s.source_files      = "Sources/**/*.{h,m,swift}"
		s.module_name 	= s.name
  		s.swift_version = "5.0"
  		s.pod_target_xcconfig = {
    		'SWIFT_VERSION' => s.swift_version.to_s
		}
		s.test_spec 'Tests' do |test_spec|
			test_spec.source_files = 'Tests/**/*.{swift}'
		end
	end
