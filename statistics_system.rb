#!/usr/bin/env ruby
# info: print overall system statistics
#  summarizes the values of the separate processes with the same names
#  cpu usage of processes show the used cpu since their start
#  disk usage of processes show the average of read + written kilobytes
#   since their start
# platform: Linux only
# depends: *acpi, *pydf (*optional dependencies)
# license: GPLv3+ <http://www.gnu.org/licenses/gpl.txt>
# Andras Horvath <mail@log69.com>


# print colorized text
def colorize(text, color_code) "\e[#{color_code}m#{text}\e[0m" end
def red   (text); colorize(text, 31); end
def green (text); colorize(text, 32); end
def yellow(text); colorize(text, 33); end
def blue  (text); colorize(text, 34); end

# check the existence of an executable
def which(cmd)
	paths = ENV["PATH"].split(":")
	paths.push("/usr/local/bin", "/usr/bin", "/bin").uniq!
	paths.each do |dir|
		file = dir + "/" + cmd
		if File.exists?(file) and File.executable?(file)
			return true end
	end
	return
end


# --------------
# --- uptime ---
# --------------
# get uptime of system in seconds
f = File.open("/proc/uptime")
text = f.read; f.close
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
# get load of system
f = File.open("/proc/loadavg")
text = f.read; f.close
# print load average
print "load " + (text.split[0..2] * ", ").to_s
puts; puts


# ---------------------
# --- system memory ---
# ---------------------
print blue("Memory (MB): ")
file = File.open("/proc/meminfo", "r")
text = file.read
file.close
text = text.gsub(/ kB$/, "")
text = text.gsub(/\: */, " ")
text = text.split("\n")[0..4]

bar = 40
mem_total   = text[0].split[1].to_i / 1024
mem_free    = text[1].split[1].to_i / 1024
mem_buffers = text[2].split[1].to_i / 1024
mem_cached  = text[3].split[1].to_i / 1024
mem_swap    = text[4].split[1].to_i / 1024
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
	if File.directory?(path) and file =~ /^\d+$/
		
		p_name = ""
		p_cpu  = 0
		p_disk = 0
		p_mem  = 0

		# get name and cpu usage
		if File.readable?(path + "/stat")
			f = File.open(path + "/stat", "r")
			text = f.read.split; f.close

			p_name = text[1][1..-2]

			p_cpu = 0
			text[13, 2].each {|x| p_cpu += x.to_i}
		end


		# get disk usage
		if File.readable?(path + "/io")
			f = File.open(path + "/io", "r")
			text = f.read; f.close
			p_disk  = text.match("^read_bytes\:.*" ).to_s.match("[0-9]+").to_s.to_i
			p_disk += text.match("^write_bytes\:.*").to_s.match("[0-9]+").to_s.to_i
		end

		# get mem usage
		if File.readable?(path + "/status")
			f = File.open(path + "/status", "r")
			text = f.read; f.close
			p_mem = text.match("^VmRSS\:.*").to_s.match("[0-9]+").to_s.to_i
		end
		
#		puts p_name + " / cpu = " + p_cpu.to_s + " / mem = " + p_mem.to_s + " / disk = " + p_disk.to_s
		
		if p_name != ""
			proc_list += [[p_name, p_cpu, p_mem, p_disk]] end
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
for i in proc_cur.sort.reverse[0..4]
	print i[1] + " (" + ("%.2f" % (i[0].to_f / sys_uptime)).to_s + ") "
end
puts; puts

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
for i in proc_cur.sort.reverse[0..4]
	print i[1] + " (" + i[0].to_s + ") "
end
puts; puts

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
for i in proc_cur.sort.reverse[0..4]
	print i[1] + " (" + ("%.2f" % (i[0].to_f / sys_uptime)).to_s + ") "
end
puts; puts


# -------------------------
# --- system disk usage ---
# -------------------------
if which("pydf")
	system("pydf")
end

# ---------------
# --- battery ---
# ---------------
if which("acpi")
	puts
	bar = 40
	out = `acpi -V 2>/dev/null`
	bat = out.scan(/[0-9]+\%/)
	if bat != [] then
		len = bat[0].match(/[0-9]+/).to_s.to_i
		if len < 0   then len = 0   end
		if len > 100 then len = 100 end
		text = "Battery: [" + "#" * (len * bar / 100) + \
			"." * ((100 - len) * bar / 100) + "]"
		if len >= 20 then puts green(text)
		else              puts red(text)
		end
		puts out
		puts
	end
end


# ------------------------------
# --- check for dependencies ---
# ------------------------------
miss = []
comm = %w[ pydf acpi ]
comm.each do |c|
	if not which(c) then miss += [c] end
end
# print warning message about missing dependencies
if miss.length > 0
	print "warning: the following commands missing: "
	print miss.join(", ")
	puts
end
