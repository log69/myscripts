#!/usr/bin/env ruby
# encoding: UTF-8

# info: checks the integrity of files in the file system and prints the name of changed files
#       it also takes into account which files have been udated by the os and skip those ones from the report


C_start_dir = "/"
C_exclude_dir = ["home", "media", "mnt", "proc", "sys"]
C_max_filesize = 1000


require "yaml/store"
require "digest"
require "zlib"


# return true on proper files that are not dirs, socket etc.
def test_file(f)
	return (File.file?(f) and File.readable?(f) and File.size?(f).to_i < C_max_filesize*1024*1024 and not (File.socket?(f) or File.blockdev?(f) or File.chardev?(f)))
end

# return the filename of our db
def get_db_name
	return File.basename($0, ".*") + "_db.yml"
end

# unzip file with gzip and return the string
def gunzip(filename)
	return Zlib::GzipReader.new(StringIO.new(File.read(filename))).read
end

# get all file list substracting the changed files by os update
def get_files
	start_dir = C_start_dir
	start_dir += "/" if start_dir[-1..-1] != "/"

	# get db mod time for compare
	t = File.mtime(get_db_name).to_s[/[0-9]+\-[0-9]+\-[0-9]+\ *[0-9]+\:[0-9]+\:[0-9]+/]
	# -------------------
	# --- dpkg plugin ---
	# -------------------
	# collect package names changed by os update from dpkg.log
	d1 = Dir["/var/log/dpkg.log*.gz"]
	d2 = Dir["/var/log/dpkg.log*"] - d1
	log = ""
	d1.each{|f| log += gunzip(f) }
	d2.each{|f| log += File.read(f) }
	# find package name entries more recent than our db
	l = log.split("\n").sort.select{|x|x > t}.select{|x| x[/status *installed/]}.map{|x|x[/status *installed *[^\:]+/].split[2]}
	# collect file names of all these package names
	list = []
	l.sort.uniq.each {|x|
		Dir.glob("/var/lib/dpkg/info/#{x}*.list") {|y|
			list << File.read(y).split("\n").select{|z| test_file(z)}
		}
	}

	# add list to recursive dir list
	res = Dir.glob("#{start_dir}**/*", File::FNM_DOTMATCH) - list.sort.uniq

	# remove excluded dirs
	C_exclude_dir.each{|d| res = res.select{|x| not x[/^#{start_dir}#{d}\//]} }
	return res
end

# return the permission, size and hash of file
def info(filename, nohash = nil)
	f = filename
	if test_file(f)
		h = nohash ? (nil) : (Digest::SHA1.hexdigest(File.read(f)))
		return [File.mtime(f), File.stat(f).mode.to_s(8).to_i, h]
	end
	return nil
end

# store data in file or return it on null input
def store(data = nil)
	f = get_db_name
	y = YAML::Store.new(f)
	y.transaction{
		if data
			y["data"] = data
		else
			return y["data"]
		end
	}
end



puts "-----------------------"
puts "--- integrity check ---"
puts "-----------------------"

time1 = Time.now.to_i
dotcount = 1000
db = {}

if not test_file(db_name)
	print "first time run (takes longer), creating db..."
	db = {}
	d = 0
	get_files.each {|f|
		db[f] = info(f)

		# print progress
		d += 1
		if d >= dotcount
			print "."
			d = 0
		end
	}
	store(db)

	puts "done (#{(Time.now.to_i - time1) / 60} min)"
	puts "you can rerun this script later in order to print changed files"
	puts "(updated files by os will not be printed but automaticallly updated in db)"

else
	print "loading db..."
	db = store
	puts "done"

	print "checking files..."
	res = []
	counter = 0
	d = 0
	get_files.each {|f|
		i = info(f, 1)
		# is file in db yet?
		i2 = db[f]
		if not i2
			# store new file not in db yet
			db[f] = info(f)
		else
			flag = nil
			# mod time and permissions only to speed up process
			# permission changed?
			if i2[1] != i[1]
				flag = 1
			# mod time changed?
			elsif i2[0] != i[0]
				i = info(f)
				# hash changed?
				if i2[2] != i[2]
					flag = 2
				end
			end
			# print warning if permission or content (hash) has changed
			if flag
				db[f] = i
				w = (flag == 1) ? "(permission change)" : "(content change)"
				res << "  #{f}  #{w}"

				counter += 1
			end
		end

		# print progress
		d += 1
		if d >= dotcount
			print "."
			d = 0
		end
	}
	store(db)

	puts "done (#{(Time.now.to_i - time1) / 60} min, #{counter} changed files)"

	# print result
	res.each {|x| puts x}
end

