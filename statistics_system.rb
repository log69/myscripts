#!/usr/bin/env ruby
# info: print overall system statistics
#  summarizes the values of the separate processes with the same names
#  cpu usage of processes shows the used cpu since their start
#  disk usage of processes shows the average of read + written kilobytes
#   since their start
#  all io usage shows all the used I/O (disk, network, tty, stdout etc.)
#   since their start
#  also shows a final order of the most resource hungry processes
#   based on the weighted mean of their statistics
# platform: Linux only
# depends: df command
# license: GPLv3+ <http://www.gnu.org/licenses/gpl.txt>
# Andras Horvath <mail@log69.com>


# constants
$num = 8
$jiffy = 100

# print colorized text
def colorize(text, color_code) "\e[#{color_code}m#{text}\e[0m" end
def red   (text); colorize(text, 31); end
def green (text); colorize(text, 32); end
def yellow(text); colorize(text, 33); end
def blue  (text); colorize(text, 34); end

# check the existence of an executable
def which(cmd)
	paths = ENV["PATH"].split(":")
	paths.push("/usr/local/bin", "/usr/bin", "/bin", "/usr/local/sbin", "/usr/sbin", "/sbin").uniq!
	paths.each do |dir|
		return true if File.executable? dir + "/" + cmd
	end
	return false
end


# check for Linux platform
if not File.directory?("/proc")
	puts "error: platform doesn't seem to be Linux or /proc filesystem is missing"
	exit 1
end

# --------------
# --- uptime ---
# --------------
# get uptime of system in seconds
text = File.read("/proc/uptime")
sys_uptime = text.split[0].to_i
sys_uptime_day  = sys_uptime / 60 / 60 / 24
sys_uptime_left = sys_uptime - sys_uptime_day * 60 * 60 * 24
sys_uptime_hour = sys_uptime_left / 60 / 60
sys_uptime_min  = (sys_uptime_left - sys_uptime_hour * 60 * 60) / 60
# print current time
print Time.now.to_s + ", up "
# print uptime
# print days of uptime
if sys_uptime_day > 0
	print sys_uptime_day.to_s
	if sys_uptime_day > 1 then print " days "
	else print " day " end
end
# print hours of uptime
print ("%02d" % sys_uptime_hour).to_s + ":" + ("%02d" % sys_uptime_min).to_s + ", "
# print times of waking up
f_wake = "/sys/power/wakeup_count"
print "awaken #{File.read(f_wake)[/[0-9]+/]}x, " if File.file? f_wake
# print load average
print "load " + (File.read("/proc/loadavg").split[0..2] * ", ").to_s
puts; puts


# ---------------------
# --- system memory ---
# ---------------------
print blue("Memory (MB): ")
text = File.read("/proc/meminfo")

bar = 40
mem_total   = text[/^memtotal.*/i][/[0-9]+/].to_i / 1024
mem_free    = text[/^memfree.*/i][/[0-9]+/].to_i / 1024
mem_buffers = text[/^buffers.*/i][/[0-9]+/].to_i / 1024
mem_cached  = text[/^cached.*/i][/[0-9]+/].to_i / 1024
mem_swap    = text[/^swaptotal.*/i][/[0-9]+/].to_i / 1024 - text[/^swapfree.*/i][/[0-9]+/].to_i / 1024
mem_used    = mem_total - mem_free - mem_buffers - mem_cached

print blue("[" + "#" * (bar * mem_used / mem_total) \
	+ "o" * (bar * (mem_cached + mem_buffers) / mem_total) \
	+ "." * (bar * mem_free / mem_total) + "]\n")

print "Total ("    + mem_total.to_s    + ") "
print "Used ("     + mem_used.to_s     + ") "
print "Buffers ("  + mem_buffers.to_s  + ") "
print "Cached ("   + mem_cached.to_s   + ") "
print "Free ("     + mem_free.to_s     + ") "
print "Swap ("     + mem_swap.to_s     + ") "
print "\n\n"

# get process infos
proc_list = []
# search for pid dirs in /proc
Dir.foreach("/proc") do |file|
	path = "/proc/" + file
	if File.directory?(path) and file[/^\d+$/]

		p_name = File.read(path + "/cmdline").split("\0")[0].to_s[/[^\/]+$/].to_s
		p_cpu  = 0
		p_disk = 0
		p_io   = 0
		p_mem  = 0

		# average get name and cpu usage
		if File.readable?(path + "/stat")
			f = File.open(path + "/stat", "r")
			text = f.read.split; f.close
			p_time = sys_uptime * $jiffy - text[21].to_f
			p_cpu = (text[13].to_f) * 100 / p_time if p_time > 0
		end


		# get disk usage
		if File.readable?(path + "/io")
			f = File.open(path + "/io", "r")
			text = f.read; f.close
			p_disk  = text[/^read_bytes\:.*/].to_s[/[0-9]+/].to_s.to_i
			p_disk += text[/^write_bytes\:.*/].to_s[/[0-9]+/].to_s.to_i
		end

		# get other io usage (includes network, tty, std etc.)
		if File.readable?(path + "/io")
			f = File.open(path + "/io", "r")
			text = f.read; f.close
			p_io  = text[/^rchar\:.*/].to_s[/[0-9]+/].to_s.to_i
			p_io += text[/^wchar\:.*/].to_s[/[0-9]+/].to_s.to_i
		end

		# get mem usage
		if File.readable?(path + "/status")
			f = File.open(path + "/status", "r")
			text = f.read; f.close
			p_mem = text[/^VmRSS\:.*/].to_s[/[0-9]+/].to_s.to_i
		end

		if p_name != ""
			proc_list += [[p_name, p_cpu, p_mem, p_disk, p_io]] end
	end
end

# sort list by name first
proc_list.sort!

# migrate duplicates of process info by name
proc_new = []
t1 = ""; t2 = ""
c1 = 0; c2 = 0
while true
	t1 = proc_list[c1]
	if t2 == "" then
		proc_new[c2] = t1
		t2 = t1
	else
		if t1[0] == t2[0] then
			proc_new[c2][1] += t1[1]
			proc_new[c2][2] += t1[2]
			proc_new[c2][3] += t1[3]
			proc_new[c2][4] += t1[4]
		else
			c2 += 1
			proc_new[c2] = t1
			t2 = t1
		end
	end
	c1 += 1
	if c1 >= proc_list.length then break end
end


# -----------------
# --- cpu usage ---
# -----------------
# get cpu list
proc_cur = []
for i in (0..proc_new.length-1)
	proc_cur[i] = [proc_new[i][1], proc_new[i][0]]
end
# print cpu list
puts red("CPU usage (%):")
for i in proc_cur.sort.reverse[0..$num-1]
	print i[1] + " (" + (i[0].to_i).to_s + ") "
end
puts

# -----------------
# --- mem usage ---
# -----------------
# get mem list
proc_cur = []
for i in (0..proc_new.length-1)
	proc_cur[i] = [proc_new[i][2] / 1024, proc_new[i][0]]
end
# print mem list
puts red("Memory usage (MB):")
for i in proc_cur.sort.reverse[0..$num-1]
	print i[1] + " (" + i[0].to_i.to_s + ") "
end
puts

# ------------------
# --- disk usage ---
# ------------------
# get disk list
proc_cur = []
for i in (0..proc_new.length-1)
	proc_cur[i] = [proc_new[i][3] / 1024, proc_new[i][0]]
end
# print disk list
puts red("Disk usage (KB/s):")
for i in proc_cur.sort.reverse[0..$num-1]
	print i[1] + " (" + (i[0] / sys_uptime).to_i.to_s + ") "
end
puts


# --------------------
# --- all io usage ---
# --------------------
# get disk list
proc_cur = []
for i in (0..proc_new.length-1)
	proc_cur[i] = [proc_new[i][4] / 1024 / 1024, proc_new[i][0]]
end
# print disk list
puts red("All I/O usage (MB, includes disk, network, tty, stdout etc.):")
for i in proc_cur.sort.reverse[0..$num-1]
	print i[1] + " (" + i[0].to_i.to_s + ") "
end
puts; puts


# --------------------------------------------
# --- processes in order of weighted means ---
# --------------------------------------------
c = []
proc_new2 = []
# calculate sum of separate value types (cpu, disk, mem etc.)
l = proc_new.length
for i2 in (1..4)
	c[i2] = 1
end
for i in (0..l-1)
	for i2 in (1..4)
		c[i2] = c[i2].to_i + proc_new[i][i2]
	end
end
for i in (0..l-1)
	name   = proc_new[i][0]
	weight = 0
	for i2 in (1..4)
		weight += proc_new[i][i2].to_f / c[i2]
	end
	proc_new2.push([weight, name])
end
# print process list
puts blue("Processes with weighted order:")
for i in proc_new2.sort.reverse[0..$num-1]
	print i[1] + "  "
end
puts
puts


# -------------------------
# --- system disk usage ---
# -------------------------
if which("df")
	res  = []
	res2 = []
	# get info for "/dev/" only
	`df -hP 2>/dev/null`.split("\n")[1..-1].sort_by{|x|x[/[^ ]+$/]}.each do |x|
		y = x.split.to_a[0]
		if x[/^\/dev\//] and not res2.include? y
			res.push(x)
			res2.push(y)
		end
	end
	if res.length > 0
		puts yellow("Disk capacity:")
	end
	res.each do |x|
		z = x.split
		# get percentage
		y = z[4].scan(/[0-9]+/)[0].to_i
		# create bar
		n = bar * y / 100 / 2
		s = "[" + "#" * n + "." * (bar / 2 - n) + "] "
		# print it in red if above 95%
		if y >= 95
			print red(s)
		else
			print yellow(s)
		end
		# print disk info
		puts "#{z[0]} #{z[5]} #{z[1]} #{z[4]}"
	end
end

