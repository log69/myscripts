#!/usr/bin/env ruby
# info: exit only if an hour has already passed since last boot
#       or last resume and the load is less than a desired value
#       or sleep until conditions meet delaying the commands in line
#       the purpose is to delay a job until the computer gets idle
# depends: ruby
# platform: linux
# usage: command ; [other shell commands]
# example: ifidle.rb ; echo do something ...


max_load = 0.5
min_uptime = 60 * 60

# sleep 15m between checking values
max_sleep = 15 * 60
# wait max 12 hours and then exit anyway
max_cycles = 12 * 60 * 60 / max_sleep


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


	break  if (my_load < max_load and my_uptime > min_uptime) \
			  or (max_cycles -= 1) <= 0

	sleep max_sleep
}
