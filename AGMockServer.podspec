Pod::Spec.new do |spec|

  spec.name         = "AGMockServer"
  spec.version      = "1.0"
  spec.summary      = "A small and very simple implementation of HTTP server mock."

  spec.homepage     = "https://github.com/AlexeyGolovenkov/AGMockServer"

  spec.license      = { 
    :type => "MIT", 
    :file => "LICENSE" 
  }

  spec.author       = { 
    "Alexey Golovenkov" => "mobidevelop@gmail.com" 
  }

  spec.platforms    = { 
    :ios => "11.0",
    :osx => "11.0" 
  }

  spec.source       = {
    :git => "https://github.com/AlexeyGolovenkov/AGMockServer.git", 
    :tag => spec.version.to_s
  }
  
  spec.swift_versions = "5.0"

  spec.requires_arc = true

  spec.source_files  = "AGMockServer", "Sources/AGMockServer/**/*.{swift}"

  spec.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/**/*.{swift}'
  end  
end
