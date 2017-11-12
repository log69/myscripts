#!/usr/bin/env ruby
# info: return true only if an hour has already passed since last boot
#       or last resume and the load is less than a specific value
#       it will sleep until conditions meet delaying the command in line
# depends: ruby
# platform: linux
# usage: command ; [other shell commands]
# example: ifidle.rb ; echo OK


# wait max 12 hours
max_cycles = 60 / 15 * 12

loop {

	# get load average for last 15 min
	my_load = File.read("/proc/loadavg").split[2].to_f

	# get time passed since boot
	my_uptime = File.read("/proc/uptime").split[0].to_f

	# get time passed since last resume from suspend if any
	require "time"
	t1 = `journalctl -b 0 -o short-iso`.split("\n")
	if t1.size > 0
		t2 = t1.grep(/system resumed/i)[-1]
		if t2
			t3 = t2.split[0].to_s
			if t3 != ""
				my_uptime = Time.now - Time.parse(t3)
			end
		end
	end


	break  if (my_load < 0.5 and my_uptime > 60 * 60) or (max_cycles -= 1) <= 0

	sleep 15 * 60
}
