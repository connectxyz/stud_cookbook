name             "stud"
maintainer       "CX Inc."
maintainer_email "miah@cx.com"
license          "Apache 2.0"
description      "Installs/Configures stud"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.3"

%w(
  runit
  git
  build-essential
).each do |recipe|
  depends recipe
end
