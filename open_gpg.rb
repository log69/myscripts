#!/usr/bin/env ruby
# info: opens a public key encrypted gpg file for viewing or editing
#  with the application that is the registered for the file type
#  and encrypts back its content after application exit
# usage: script file
# example: script file.txt.gpg
# platform: Linux, Unix
# depends: gnupg, stty, zenity
# license: GPLv3+ <http://www.gnu.org/licenses/gpl.txt>
# Andras Horvath <mail@log69.com>

require 'tempfile'

# command names
GPG      = "gpg"
STTY     = "stty"
ZENITY   = "zenity"
# system file paths
MIMETYPE = "/etc/mime.types"
MIMEINFO = "/usr/share/applications/mimeinfo.cache"
APPICONS = "/usr/share/applications"


# check the existence of an executable
def which(cmd)
	paths = ENV["PATH"].split(":")
	paths.push("/usr/local/bin", "/usr/bin", "/bin").uniq!
	paths.each do |dir|
		file = dir + "/" + cmd
		if File.file?(file) and File.executable?(file)
			return true end
	end
	return
end

# print error message to console or to GUI
def error(text)
	# is command run from a console?
	if `#{STTY}` != ""
		# if so, then print message to console
		puts text
	else
		# otherwise print it to GUI
		title = File.basename($PROGRAM_NAME)
		c = "#{ZENITY} --error --title \"#{title}\" --text \"#{text}\""
		system(c)
	end
end

# read and return the contents of file
def fread(file)
	f = open(file, "r")
	text = f.read
	f.close
	return text
end

# get app name for extension type and return binary name
def mime_app(ext)
	# get all contents of mime type
	text = fread(MIMETYPE)
	# search for my extension
	type = text.match(/^.*[\t ]#{ext}[\t $].*/).to_s.split("\t")[0]
	# read up all mime info
	text = fread(MIMEINFO)
	# search for my mime type, the result is a .desktop file name
	icon = text.match(/^#{type}=[^;$\n]+/).to_s.match(/[^=]+$/).to_s
	# read content of .desktop file
	text = fread("#{APPICONS}/#{icon}")
	# get binary name from .desktop file
	app = text.match(/^exec=[^ \n$]+/i).to_s[5..-1]
	
	return app
end


# check if commands are available
if not which(GPG)    then error("error: command gpg is missing");    exit 1 end
if not which(STTY)   then error("error: command stty is missing");   exit 1 end
if not which(ZENITY) then error("error: command zenity is missing"); exit 1 end

# are there any arguments
if ARGV.length != 1
	# if no then fail
	error("usage: script [encrypted file]")
	exit 1
end

# get file name
file = ARGV[0].to_s
# file exists?
if not File.file?(file)
	error("error: file doesn't exist"); exit 1 end
# file has extension .gpg?
if file.match(/[^\.]+$/).to_s.downcase != "gpg"
	error("error: file is not appropriate type"); exit 1 end
# get secondary extension type
ext = file.match(/^.*\./).to_s.match(/\.[^\.]+/).to_s[1..-1]
if ext == "" or ext == nil
	error("error: no secondary file extension"); exit 1 end
ext = ext.downcase


# temp file to store unencrypted file temporarily
f=Tempfile.new("open_gpg"); temp=f.path; f.close
# temp file to store the stderr output of gpg
f=Tempfile.new("open_gpg"); outp=f.path; f.close

# is command run from a console?
# use --no-tty option for gpg only if it's run from GUI
if `#{STTY}` != ""
	# set command
	c = "#{GPG} -v --decrypt #{file} 1>#{temp} 2>#{outp}"
else
	# set command with "--no-tty" option
	c = "#{GPG} --no-tty -v --decrypt #{file} 1>#{temp} 2>#{outp}"
end

# decrypt the file
if not system(c)
	out = fread(outp)
	# was it cancelled by user?
	if out.match(/cancelled by user/) == nil
		error("error: failure during decryption") end
	# exit anyway
	exit 1
end

# get key id from gpg output
out = fread(outp)
keyid = out.match(/public key is.*/).to_s.match(/[^ ]+$/).to_s
if keyid == ""
	error("error: not a public key encrypted file"); exit 1 end

# get app for extension type
APP = mime_app(ext)
# open file and wait for the process to terminate
c = "#{APP} #{temp} &>/dev/null && wait"
system(c)
# encrypt back its content
text = fread(temp)
c = "cat #{temp} | #{GPG} -e -r #{keyid} 1>#{file}"
system(c)
# sync to make sure the deletion is committed
f = File.new(temp); f.fsync; f.close
f = File.new(outp); f.fsync; f.close
# delete unencrypted and temp datas
File.delete(temp)
File.delete(outp)


exit
