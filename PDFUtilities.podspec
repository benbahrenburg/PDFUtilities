#
# Be sure to run `pod lib lint PDFUtilities.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'PDFUtilities'
  s.version          = '0.1.0'
  s.summary          = 'Tools for working with PDFs'
  s.description      = <<-DESC
Tools to stop you pulling your hair out when working with PDFs.
                       DESC
  s.homepage         = 'https://github.com/benbahrenburg/PDFUtilities'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Ben Bahrenburg' => '@bencoding' }
  s.source           = { :git => 'https://github.com/benbahrenburg/PDFUtilities.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/bencoding'
  s.ios.deployment_target = '9.0'
  s.source_files = 'PDFUtilities/Classes/**/*'
end
