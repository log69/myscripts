#!/usr/bin/env ruby
# info: opens a public key encrypted gpg file for viewing or editing
#  with the application that is registered for that file type
#  or the one that is manually specified on the command line
#  and encrypts back its content after application exit
# usage: script [file] or script [app] [file]
# example: script file.txt.gpg
# platform: Linux, Unix
# depends: gpg, zenity, xdg-open, *strace
# (*optional dependency, it helps with an ugly hack)
# (gpg is the part of gnupg, xdg-open is part of xdg-utils package)
# license: GPLv3+ <http://www.gnu.org/licenses/gpl.txt>
# Andras Horvath <mail@log69.com>

# IMPORTANT:
#  the script is not entire and not fully functional yet
# KNOWN ISSUES:
#  if the app to be opened for the file type is already running,
#  then the script doesn't work as expected
#  this issue must still be addressed

require 'tempfile'
require 'fileutils'


# temp file settings
$TEMPDIR  = "/dev/shm"
$TEMPNAME = "open_gpg_41eb8f6cd3df437c815ca32c44ab568d_"

# shell commands
GPG      = "gpg"
ZENITY   = "zenity"
OPEN     = "xdg-open"


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

# print info message to console or to GUI
def info(text)
	# is command run from a console?
	# to determine this, thanks goes to hrgy84 and this site:
	# http://rubyonwindows.blogspot.com/2008/06/running-in-console-window.html
	if STDIN.isatty
		# if so, then print message to console
		puts text
	else
		# otherwise print it to GUI
		title = File.basename($PROGRAM_NAME)
		c = "#{ZENITY} --info --title \"#{title}\" --text \"#{text}\""
		system(c)
	end
end

# print error message to console or to GUI
def error(text)
	# is command run from a console?
	if STDIN.isatty
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
	res = f.read
	f.close
	return res
end

# write the content to a file
def fwrite(file, text)
	f = File.open(file, "w")
	f.write(text)
	f.close
end

# delete file
def fdelete(file)
	# file has a name?
	if file != "" and file != nil
		# file exists?
		if File.file? file
			# delete file
			File.delete(file)
		end
	end
end

# delete all temp files
def fdelete_pattern(dir, pattern)
	# input params are ok?
	if dir != "" and dir != nil and pattern != "" and pattern != nil
		# list all files in temporary dir
		Dir.foreach(dir).to_a.each do |d|
			# file name contains temp name?
			if d.match(/#{pattern}/) != nil
				# delete file
				fdelete("#{dir}/#{d}")
			end
		end
	end
end


# --- main ---

# global temp files
$temp = ""; $putp = ""

# check if commands are available
if not which(GPG)    then error("error: command gpg is missing");      exit 1 end
if not which(ZENITY) then error("error: command zenity is missing");   exit 1 end
if not which(OPEN)   then error("error: command xdg-open is missing"); exit 1 end

# are there any arguments
if ARGV.length == 0
	# if no then fail
	error("usage: script [file] or script [app] [file]")
	exit 1
end

# get arguments
comm = ""
name = ""
if ARGV.length > 1
	# get app name and file name
	comm = ARGV[0].to_s
	name = ARGV[1].to_s
else
	# get file name
	name = ARGV[0].to_s
end

# file exists?
if not File.file?(name)
	error("error: file doesn't exist"); exit 1 end
# file has extension .gpg?
if name.match(/[^\.]+$/).to_s.downcase != "gpg"
	error("error: file is not appropriate type"); exit 1 end
# get secondary extension type
ext = name.match(/^.*\./).to_s.match(/\.[^\.]+/).to_s[1..-1].to_s.downcase


# temp file to store unencrypted file temporarily
f = Tempfile.new($TEMPNAME, $TEMPDIR); $temp = f.path + "." + ext; f.delete; f.close
# temp file to store the stderr output of gpg
f = Tempfile.new($TEMPNAME, $TEMPDIR); $outp = f.path + "." + ext; f.delete; f.close


# trap code to delete unencrypted files on exit
Signal.trap("INT") do
	fdelete_pattern($TEMPDIR, File.basename($temp))
	fdelete_pattern($TEMPDIR, File.basename($outp))
	error("error: program has been terminated!")
	exit 1
end
Signal.trap("TERM") do
	fdelete_pattern($TEMPDIR, File.basename($temp))
	fdelete_pattern($TEMPDIR, File.basename($outp))
	error("error: program has been terminated!")
	exit 1
end


# create safety backup as file.gpg.bak
FileUtils.cp name, "#{name}.bak"

# is command run from a console?
# use --no-tty option for gpg if it's run from GUI
if STDIN.isatty
	# set command
	c = "#{GPG} -v --decrypt #{name} 1>#{$temp} 2>#{$outp}"
else
	# set command with "--no-tty" option
	c = "#{GPG} --no-tty -v --decrypt #{name} 1>#{$temp} 2>#{$outp}"
end

# decrypt the file
if not system(c)
	out = fread($outp)
	fdelete_pattern($TEMPDIR, File.basename($temp))
	fdelete_pattern($TEMPDIR, File.basename($outp))
	# was it cancelled by user?
	if out.match(/cancelled by user/) == nil
		error("error: failure during decryption") end
	# exit anyway
	exit 1
end

# get key id from gpg output
out = fread($outp)
keyid = out.match(/public key is.*/).to_s.match(/[^ ]+$/).to_s
if keyid == ""
	fdelete_pattern($TEMPDIR, File.basename($temp))
	fdelete_pattern($TEMPDIR, File.basename($outp))
	error("error: not a public key encrypted file");
	exit 1
end


if comm == ""
	# command to run xdg.open on a file to open it in an app
	c = "#{OPEN} #{$temp}"
	system(c)

	# this is a safety delay here to research for the app if it hasn't started yet
	# this can happen when xdg-open is late a bit and the app opens up
	#  after this part of code
	# cc is the maximum number of tries and tt is the time to wait
	#  so this adds up to a whole 3 sec
	cc = 15
	tt = 0.2
	while cc > 0

		# search for process whose process group ID matches my PID
		pidok = 0
		Dir.foreach("/proc").to_a.reverse.each do |d|
			# is subdir a number?
			if d.match(/^\d+$/)
				p = "/proc/#{d}/cmdline"
				# cmdline file exists?
				if File.file? p
					# read up /proc/PID/cmdline file
					cmdline = fread(p)
					# does the process's cmdline contain the temp file name?
					if cmdline.match($temp)
						# if so, then this is what I'm looking for
						# because I don't expect any other process to contain
						# my random file name
						pidok = d.to_i
						break
					end
				end
			end
		end

		# did I find any process?
		if pidok > 0 then break end

		# sleep some and then search for it again
		sleep tt
		cc -= 1
	end

	# wait for the foreign pid to finish
	# this is not a child process, so I can't wait for it with the system wait
	# an ugly hack might do the job without having to be polling it :)
	# if strace is available, then I use that one - if not, then I keep polling
	# thanks to lacos
	if which("strace")
		c = "strace -e none -p #{pidok} &>/dev/null"
		system("strace -e none -p #{pidok} &>/dev/null")
	else
		f = "/proc/#{pidok}"
		while File.directory? f
			sleep 0.1
		end
	end
else
	# open file with manually specified app
	c = "#{comm} #{$temp}"
	system(c)
end


# encrypt back its content
c = "cat #{$temp} | #{GPG} -e -r #{keyid} 1>#{name}"
system(c)

# delete unencrypted temporary datas
fdelete_pattern($TEMPDIR, File.basename($temp))
fdelete_pattern($TEMPDIR, File.basename($outp))

# info message
info("info: data has been encrypted back successfully")


exit
