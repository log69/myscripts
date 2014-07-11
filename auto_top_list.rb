#!/usr/bin/env ruby
# encoding: UTF-8

# author: Andras Horvath <mail@log69.com>
# license: BSDL
# all rights reserved.


# -------------------------------
# --- auto top list algorithm ---
# -------------------------------
# description:
# if there are a list of items with access time pairs,
# then this creates a top list with position numbers
# saying which item should be at which position
# the goal is to create a fully automatic top list
# that's not too short and not too long either
# and make it adaptive to the latest customs of the user
#
# algorithm:
# we walk through hills (the diff of time values) resgistering
# the biggest one until the way is upwards, if it starts to go downwards
# then we go until we get to a hill that is bigger than the rest before
# and we stop taking the items here
# in other words:
# we take those items only whose access happened not too long ago
# compared to their own access times


# input: an array of times in seconds compared to now
# output: an array of integers showing the position of each item
def auto_top_list(times)
	# constants:
	# the min time passed since item visit - if it is less,
	# then it it taken as if it had been visited this time ago
	min_timeout = 60 * 60 * 24
	# do not display items with bigger time diffs than this
	max_timeout = 60 * 60 * 24 * 7
	# max number of the list
	max_list    = 10

	# create a list of numbers
	list = (0..times.size-1).to_a
	# sort this list by the time values
	items = (times.zip list).sort.transpose[1]

	# calculate here the differences of times between items
	# and create a list of it
	timediff = []
	prev = 0
	c = 0
	times.sort.each { |t|
		diff = t - prev
		break if diff > max_timeout

		items.push(c)
		timediff.push(diff)

		c += 1
		prev = t
	}
	return [] if timediff.size < 1


	# create the top list based on the time diffs
	max = 0
	direction = 1
	flag = 1
	c = 0
	timediff.each { |x|
		y = x
		y = min_timeout if y < min_timeout

		if direction
			if y >= max
				max = y
			else
				direction = nil
			end
		else
			break if y > max
		end

		c += 1
		break if c >= max_list
	}

	# do not sort the result, so it will carry the information
	# that the first ones will be the most recent
	return items[0..c - 1]
end


# -----------------
# --- test code ---
# -----------------
# items contains names of anything, like urls or songs from a page etc.
# times contains their access times in seconds compared to now,
# 60 means it was accessed a minute ago
items = ["apple", "banana", "orange", "lemon", "melon", "tomato",
         "radish", "pineapple", "coconut", "onion"]
times = (1..items.size).to_a.map{rand(60 * 60 * 24 * 30)}

puts "original inputs:"
p items, times
puts
puts "result:"
p auto_top_list(times).map{|i| items[i]}
