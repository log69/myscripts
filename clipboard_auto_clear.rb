#!/usr/bin/env ruby
# info: clear clipboard automatically after some time
#       or restart waiting if clipboard changes
#       so every copy on clipboard has the same time before clear
# depends on package: ruby, xsel
# tested on: Ubuntu 14 LTS 64 bit

timeout = 60
poll = 5

def get
	return "#{`xsel --display :0 -p`}#{`xsel --display :0 -s`}#{`xsel --display :0 -b`}".strip
end

def clear
	`xsel --display :0 -pc; xsel --display :0 -sc; xsel --display :0 -bc`
end

temp = ""
count = timeout / poll
c = 0
while true do
	clip = get

	# clipboard changed?
	if temp != clip
		temp = clip

		# restart counter if so
		c = 0 if clip != ""
	end

	sleep poll
	c += 1

	# timeout reached?
	if c >= count
		# clear clipboard if so
		clear if clip != ""
		# restart
		c = 0
	end
end
