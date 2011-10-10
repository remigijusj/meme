#!/usr/bin/env ruby
#
# === Meme generator script for Windows ===
# 
# Hacked together by http://github.com/marcinbunsch
# Modified by https://github.com/remigijusj
# Windows-specific parts are few and marked in the code
# 
# This assumes the following:
# - you have Ruby v1.8.6 or later
# - you have ImageMagick installed
# - you have a folder containing memes jpg
# - you have the Impact font
# - you have a Dropbox account and folder
# 
# Example:
#   When I have a yuno.jpg file in my Memes folder
#   And I run the command
#   > meme.rb yuno y u no // have your own\\meme generator? --name yuno_generator --dropbox
#   Then it will create a file yuno_generator.jpg in Dropbox/Public/memes 
#   Then it will copy the public URL to clipboard
#
# Usage notes:
# - To list available memes, use meme.rb -l
# - All arguments except options are joined by space
# - Inside text use \\ To insert newline; use // to separate picture top text from bottom text
# - Generated picture will be deleted after opening, except when -o is provided
# 
require 'optparse'
require 'fileutils'

# --> Modify these constants as appropriate <--
CONVERT = "C:/Tools/ImageMagick/convert.exe"
DRAWER  = "C:/Tools/memes"
FONT    = "C:/Windows/Fonts/impact.ttf"
DROPBOX = "C:/Dropbox/Public/memes"
DROPBOX_ID  = "28282517"
DROPBOX_URL = "http://dl.dropbox.com/u/#{DROPBOX_ID}"

# -- Default options for generator, modify if necessary
options = {
  :font_top    => 40,
  :font_bottom => 40,
  :y_top    => 10,
  :y_bottom => 5,
  :kern => 1
}

# -- Some preliminary setup
def show_usage
  puts <<-USAGE
> meme.rb <MEME> [TOP\\LINES // BOTTOM] [options]
    -l --list:   List available memes  (only option)
    -n --name:   Name of output file   (default: meme_)
    -r --random: Name generated random
    -o --open:   Open after generation (default)
    -d --drop:   Copy to dropbox after generation
    -t --top:    Font size of top text
    -b --bottom: Font size of bottom text
    -T --top-y:    Y position of top text
    -B --bottom-y: Y position of bottom text
  USAGE
end

OptionParser.new do |opts|
  opts.banner = "Usage: meme.rb <MEME> [TOP\\LINES // BOTTOM] [options]"

  opts.on("-l", "--list", "List available memes") do |v|
    options[:list] = true
  end

  opts.on("-n name", "--name name", "Name of output file") do |v|
    options[:output] = "#{v}.jpg"
  end

  opts.on("-r size", "--random size", "Generate random name") do |v|
    options[:random] = v.to_i
  end

  opts.on("-o", "--open", "Open after generation") do
    options[:open] = true
  end

  opts.on("-d", "--dropbox", "Copy to dropbox after generation") do
    options[:dropbox] = true
  end

  opts.on("-t size", "--top size", "Font size of top text") do |size|
    options[:font_top] = size
  end

  opts.on("-b size", "--bottom size", "Font size of bottom text") do |size|
    options[:font_bottom] = size
  end

  opts.on("-T pos", "--top-y pos", "Y position of top text") do |y|
    options[:y_top] = y
  end

  opts.on("-B pos", "--bottom-y pos", "Y position of bottom text") do |y|
    options[:y_bottom] = y
  end

end.parse!

# -- List or show usage
File.directory?(DROPBOX) or FileUtils.mkpath(DROPBOX)

if options[:list]
  Dir.glob(DRAWER+'/*.jpg').sort.each do |it|
    puts '  - ' << it[(DRAWER.length+1)..-5]
  end
  exit
end

if ARGV.size < 1
  show_usage
  exit
end

# -- Prepare the commands
meme = ARGV.shift
source = Dir.glob("#{DRAWER}/#{meme}*").first or begin
  puts "Error: Source meme not found!"
  exit
end
output = if options[:output]
  options[:output]
elsif options[:random]
  symbols = ['a'..'z','A'..'Z','0'..'9'].map(&:to_a).flatten.join
  options[:random].times.map { symbols[rand(symbols.size)] }.join << '.jpg'
else
  File.basename(source).sub(/\.jpg$/, '_.jpg')
end

texts = ARGV.join(' ').upcase.gsub('\\\\','\n').split('//').map {|it| it.strip }

commands = [%Q{#{CONVERT} "#{source}" -font "#{FONT}" -fill white}] 
commands.first.gsub!('/','\\')  # <- Windows specific!
if texts.size == 1
  commands << %Q{-pointsize #{options[:font_bottom]}}
  commands << %Q{-stroke black -strokewidth 4 -gravity North -kerning #{options[:kern]} -annotate +0+#{options[:y_bottom]} "#{texts[0]}" }
  commands << %Q{-stroke none  -strokewidth 4 -gravity North -kerning #{options[:kern]} -annotate +0+#{options[:y_bottom]} "#{texts[0]}" }
else # texts.size == 2
  commands << %Q{-pointsize #{options[:font_top]}}
  commands << %Q{-stroke black -strokewidth 4 -gravity North -kerning #{options[:kern]} -annotate +0+#{options[:y_top]} "#{texts[0]}" }
  commands << %Q{-stroke none  -strokewidth 4 -gravity North -kerning #{options[:kern]} -annotate +0+#{options[:y_top]} "#{texts[0]}" }
  commands << %Q{-pointsize #{options[:font_bottom]}}
  commands << %Q{-stroke black -strokewidth 4 -gravity South -kerning #{options[:kern]} -annotate +0+#{options[:y_bottom]} "#{texts[1]}" }
  commands << %Q{-stroke none  -strokewidth 4 -gravity South -kerning #{options[:kern]} -annotate +0+#{options[:y_bottom]} "#{texts[1]}" }
end
commands << output

# -- Generate the picture
system commands.join(' ')
puts "Generated into #{output}"

# -- Post-generate actions
if options[:open] or !options[:dropbox]
  system   "start #{output}" # <- Windows specific
end

if options[:dropbox]
  FileUtils.cp(output, DROPBOX)
  path     = DROPBOX.split("/Dropbox/Public/").last
  file     = File.basename(output)
  url      = "#{DROPBOX_URL}/#{path}/#{file}"
  system   "echo #{url} | clip" # <- Windows specific
  puts     "Dropbox url copied to clipboard!"
end

if options[:dropbox] or !options[:open]
  sleep 1
  FileUtils.rm(output)
end
