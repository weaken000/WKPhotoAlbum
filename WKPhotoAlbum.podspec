

Pod::Spec.new do |s|

  s.name         = "WKPhotoAlbum"
  s.version      = "0.0.1"
  s.summary      = "自定义相册，提供照片的编辑和选取以及视频选取功能"
  s.homepage     = "https://github.com/weaken000/WKPhotoAlbum"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "weaken" => "845188093@qq.com" }
  s.source       = { :git => "https://github.com/weaken000/WKPhotoAlbum.git", :tag => "#{s.version}" }
  s.source_files = "WKPhotoAlbum/*.{h,m}"
  s.frameworks   = "Photos"
  s.ios.deployment_target = '9.0'
end
