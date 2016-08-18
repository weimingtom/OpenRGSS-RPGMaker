$LOAD_PATH.unshift '/home/zh99998/RubymineProjects/OpenRGSS/lib'

require 'rubygems' #for ruby 1.8.7
require 'inifile'
require 'openrgss'
require 'zlib'

#see http://stackoverflow.com/questions/4583924/string-force-encoding-in-ruby-1-8-7-or-rails-2-x
#replace for force_encoding('UTF-8')
require 'iconv'
class String
  def to_my_utf8
    ::Iconv.conv('UTF-8//IGNORE', 'UTF-8', self + ' ')[0..-2]
  end
end

include RGSS

#load config
$RGSS_CONFIG   = IniFile.load('Game.ini', {:encoding => "GBK"})['Game'] #how to detect charset?

#set title
RGSS.title    = $RGSS_CONFIG['Title']

#detect RGSS version
$RGSS_VERSION = if index = ['.rxdata', '.rvdata' '.rvdata2'].index(File.extname($RGSS_CONFIG['Scripts']))
  index + 1
elsif $RGSS_CONFIG['Library'] and $RGSS_CONFIG['Library'] =~ /RGSS(\d)\d\d\w?\.dll/i
  $1.to_i
else
  puts "warning: can't detect rgss version"
  1
end

#load RPG module
case $RGSS_VERSION
when 1
  require 'rpg/rpgxp'
when 2
  require 'rpg/rpgvx'
when 3
  require 'rpg/rpgva'
end

#set screen size.
if $RGSS_VERSION == 1
  Graphics.resize_screen(640, 480)
else
  Graphics.resize_screen(544, 416)
end

#load RTP on all platform
if $RGSS_VERSION == 1
  [$RGSS_CONFIG['RTP1'], $RGSS_CONFIG['RTP2'], $RGSS_CONFIG['RTP3']].each do |rtp|
    RGSS.load_path << ENV["RGSS_RTP_#{rtp}"]
  end
else
  RGSS.load_path << ENV["RGSS#{$RGSS_VERSION}_RTP_#{$RGSS_CONFIG['RTP']}"]
end

#load RTP on windows
if RUBY_PLATFORM['mingw'] or RUBY_PLATFORM['mswin']
  require 'win32/registry'
  registry = Win32::Registry::HKEY_LOCAL_MACHINE
  if $RGSS_VERSION == 1
    registry.open('Software\Enterbrain\RGSS\RTP') do |reg|
      [$RGSS_CONFIG['RTP1'], $RGSS_CONFIG['RTP2'], $RGSS_CONFIG['RTP3']].each do |rtp|
        (RGSS.load_path << reg[rtp].force_encoding(Encoding.default_external).encode('UTF-8')) rescue nil
      end
    end
  else
    registry.open("Software\\Enterbrain\\RGSS#{$RGSS_VERSION}\\RTP") do |reg|
      (RGSS.load_path << reg[$RGSS_CONFIG['RTP']].force_encoding(Encoding.default_external).encode('UTF-8')) rescue nil
    end
  end
end

#run scripts
$RGSS_SCRIPTS = load_data $RGSS_CONFIG['Scripts'].gsub('\\', '/')
begin
if $RGSS_VERSION <= 2
  #force_encoding('UTF-8')
  rgss_main { $RGSS_SCRIPTS.each { |script| eval Zlib::Inflate.inflate(script[2]).to_my_utf8, TOPLEVEL_BINDING, script[1], 0 } }
else
	#force_encoding('UTF-8')
  $RGSS_SCRIPTS.each { |script| eval Zlib::Inflate.inflate(script[2]).to_my_utf8, TOPLEVEL_BINDING, script[1], 0 }
  #$RGSS_SCRIPTS.each do |script|
  #for IDE debug
  #open("Data/#{script[1]}.rb", 'w') { |f| f.write Zlib::Inflate.inflate(script[2]) }
  #eval IO.read("Data/#{script[1]}.rb"), TOPLEVEL_BINDING, "Data/#{script[1]}.rb", 0
  #end
end
rescue SystemExit

rescue Exception => exception
  if RUBY_PLATFORM['mingw'] or RUBY_PLATFORM['mswin']
    #msgbox(exception, exception.backtrace.join("\n"))
	raise exception
  else
    raise exception
  end
end