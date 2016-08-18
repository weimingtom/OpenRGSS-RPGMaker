#source :rubygems
source 'https://rubygems.org'

platform :ruby do
  gem 'rubysdl'
end

platforms :mswin, :mingw do
  gem 'rubysdl-mswin32-1.8'
end

gem 'inifile'

# gem 'openrgss'

if RUBY_PLATFORM["mswin"] or RUBY_PLATFORM["mingw"]
  gem 'ocra'
end
