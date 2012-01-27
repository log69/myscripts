#!/usr/bin/ruby
# info: print overall system statistics
# (also summarizes the values of separate processes with the same names)
# depends: ruby, ps, pidstat (sysstat), acpi, pydf
# license: GPLv3+
# Andras Horvath <mail@log69.com>


# colorizing rutins
def colorize(text, color_code) "\e[#{color_code}m#{text}\e[0m" end
def red   (text); colorize(text, 31); end
def green (text); colorize(text, 32); end
def yellow(text); colorize(text, 33); end
def blue  (text); colorize(text, 34); end

# uptime
system("clear")
puts red("Uptime: " + `uptime`)

# battery
if not system("which acpi >/dev/null")
	puts "error: acpi command missing"; puts
else
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
	puts out.scan(/^(?!Cooling).*/)
	puts
end
end

# memory
print blue("Memory (MB): ")
file = File.open("/proc/meminfo", "rb")
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

# mem usage
if not system("which ps >/dev/null")
	puts "error: ps command missing"; puts
else
puts red("Memory usage (MB):")
text = `ps -eo comm,rss`
texta = text.split("\n")[1..text.split("\n").length-1]
textb = []
for i in (0..(texta.length-1))
	textb[i] = texta[i].split[0], \
		texta[i].split[1].to_i / 1024
end
textb = textb.sort
textc = []
t1 = ""; t2 = ""
n1 = 0; n2 = 0
c1 = 0; c2 = 0
while true
	t1 = textb[c1][0]
	n1 = textb[c1][1].to_i
	if t2 == "" then
		t2 = t1; n2 = n1
		textc[c2] = n2, t2
	else
		if t1 == t2 then
			n2 += n1
			textc[c2][0] = n2
		else
			c2 += 1
			t2 = t1; n2 = n1
			textc[c2] = n2, t2
		end
	end
	c1 += 1
	if c1 >= textb.length then break end
end
for i in textc.sort.reverse[0..4]
	print i[1] + " (" + i[0].to_s + ") "
end
puts; puts
end

# disk usage
if not system("which pidstat >/dev/null")
	puts "error: pidstat command missing"; puts
else
puts red("Disk usage (KB/s):")
text = `pidstat -hd`
texta = text.split("\n")[3, text.split("\n").length-1]
textb = []
for i in (0..(texta.length-1))
	textb[i] = texta[i].split[5], \
		texta[i].split[2].to_f + texta[i].split[3].to_f
end
textb = textb.sort
textc = []
t1 = ""; t2 = ""
n1 = 0; n2 = 0
c1 = 0; c2 = 0
while true
	t1 = textb[c1][0]
	n1 = textb[c1][1].to_f
	if t2 == "" then
		t2 = t1; n2 = n1
		textc[c2] = n2, t2
	else
		if t1 == t2 then
			n2 += n1
			textc[c2][0] = n2
		else
			c2 += 1
			t2 = t1; n2 = n1
			textc[c2] = n2, t2
		end
	end
	c1 += 1
	if c1 >= textb.length then break end
end
for i in textc.sort.reverse[0..4]
	print i[1] + " (" + i[0].to_s + ") "
end
puts; puts
end

# cpu usage
if not system("which pidstat >/dev/null")
	puts "error: pidstat command missing"; puts
else
puts red("CPU usage (%):")
text = `pidstat -h`
texta = text.split("\n")[3, text.split("\n").length-1]
textb = []
for i in (0..(texta.length-1))
	textb[i] = texta[i].split[7], texta[i].split[5]
end
textb = textb.sort
textc = []
t1 = ""; t2 = ""
n1 = 0; n2 = 0
c1 = 0; c2 = 0
while true
	t1 = textb[c1][0]
	n1 = textb[c1][1].to_f
	if t2 == "" then
		t2 = t1; n2 = n1
		textc[c2] = n2, t2
	else
		if t1 == t2 then
			n2 += n1
			textc[c2][0] = n2
		else
			c2 += 1
			t2 = t1; n2 = n1
			textc[c2] = n2, t2
		end
	end
	c1 += 1
	if c1 >= textb.length then break end
end
for i in textc.sort.reverse[0..4]
	print i[1] + " (" + i[0].to_s + ") "
end
puts; puts
end

# disk usage
if not system("which pydf >/dev/null")
	puts "error: pydf command missing"; puts
else
system("pydf"); puts
end
