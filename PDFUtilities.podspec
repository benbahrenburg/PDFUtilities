
Pod::Spec.new do |s|
  s.name             = 'PDFUtilities'
  s.version          = '0.0.5'
  s.summary          = 'PDFUtilities makes working with PDFs in Swift easier.'

  s.description  = <<-DESC
    Utilities to make working with PDFs bearable.
  DESC

  s.homepage         = 'https://github.com/benbahrenburg/PDFUtilities'
  s.license          = 'MIT'
  s.authors          = { 'Ben Bahrenburg' => 'hello@bencoding.com' }
  s.source           = { :git => 'https://github.com/benbahrenburg/PDFUtilities.git', :tag => s.version }
  s.social_media_url = 'https://twitter.com/bencoding'
  s.ios.deployment_target = '9.0'
  s.source_files = 'PDFUtilities/Classes/**/*'
end
