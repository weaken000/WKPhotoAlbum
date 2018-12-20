

Pod::Spec.new do |s|

  s.name         = "WKPhotoAlbum"
  s.version      = "2.4.1"
  s.summary      = "自定义相册，提供照片的编辑和选取以及视频选取功能"
  s.homepage     = "https://github.com/weaken000/WKPhotoAlbum"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "weaken" => "845188093@qq.com" }
  s.source       = { :git => "https://github.com/weaken000/WKPhotoAlbum.git", :tag => "2.4.1" }
  s.source_files = "WKPhotoAlbum"
  s.resources    = "WKPhotoAlbum/Resources/WKPhotoAlbum.bundle"
  s.frameworks   = "Photos"
  s.ios.deployment_target = '9.0'

end
