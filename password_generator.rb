#!/usr/bin/env ruby
# info: generate random passwords, also without special or mixable chars
# command [pass length]
# without parameter it prints several columns of passwords
# each containing stronger ones going left to right
# license: GPLv3+ <http://www.gnu.org/licenses/gpl.txt>
# Andras Horvath <mail@log69.com>


# shuffle method of Array class is not available before Ruby 1.8.7
# add this to make this script compatible with earlier versions too
# this function is approx. 10 times slower then the native shuffle method
# info: mix the contents of an array into random order
#  and return result array
def shuffle(array)
	result = []
	l = array.length
	l.times do
		i = rand(l)
		a = array[i]
		array.delete_at(i)
		result.push(a)
		l -= 1
	end
	return result
end


# get a specified length of random number as a string
# len means an integer of 4 or greater
def get_number(len)
	l = len.to_i
	l = 4 if l < 4
	return (1..l).map {rand 10}.join
end


# get a strong password of a specified length
# len means an integer of 4 or greater
#
# the rules are:
# - characters can be any of the ASCII chars
def get_password_strong(len)

	pass = ""

	# choose chars from ASCII code 33 - 126
	len.times do
		pass += (rand(126+1-33) + 33).chr
	end

	return pass
end


# get a password of a specified length
# that doesn't contain similar easily mixable chars
# and can be used properly on english and hungarian keyboards too
# len means an integer of 4 or greater
#
# the rules are:
# - min 1 lower case letter is necessary
# - min 1 upper case letter is necessary
# - min 1 number is necessary
def get_password(len)

	# all available chars to choose from
	# "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	# exception chars
	# "o|O|0|Q|1|i|j|l|I|z|Z|y|Y|g|q|9|G|6|B|8"
	# "z" and "y" are exceptions because of querty key maps
	ch = "abcdefhkmnprstuvwxABCDEFHJKLMNPRSTUVWX234578".chars.to_a
	ch_low = "abcdefhkmnprstuvwx".chars.to_a
	ch_upp = "ACDEFHJKLMNPRSTUVWX".chars.to_a
	ch_num = "23457".chars.to_a

	# pass should have at least 4 chars
	if len < 4 then return "" end

	pass = ""

	# get 1 lower, 1 upper case and 1 number for sure
	pass += ch_low[rand(ch_low.length)]
	pass += ch_upp[rand(ch_upp.length)]
	pass += ch_num[rand(ch_num.length)]

	# get the rest of the sample randomly
	for i in (0..len-4)
		c = ch[rand(ch.length)]
		pass += c
	end

	# shuffle the order of chars in result
	#return pass.chars.to_a.shuffle.join
	return shuffle(pass.chars.to_a).join
end


# get a _pronounceable_ password of a specified length
# that doesn't contain similar easily mixable chars
# and can be used properly on english and hungarian keyboards too
# len means an integer of 4 or greater
#
# the rules are:
# - only 1 upper case letter is necessary
# - only 1 number is necessary
# - min 1 lower case letter is necessary
# - max 2 vowels may follow each other if they're not identical except "ee"
# - max 2 consonants may follow each other if they match
def get_password_pron(len)

	# all available chars to choose from
	# "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPRSTUVWXYZ0123456789"
	# exception chars
	# "o|O|0|Q|1|i|j|l|I|y|Y|g|q|9|G|6|B|8"
	# "z" and "y" are exceptions because of querty key maps
	ch = "abcdefhkmnprstuvwxACDEFHJKLMNPRSTUVWX23457".chars.to_a
	ch_low = "abcdefhkmnprstuvwxz".chars.to_a
	ch_upp = "ACDEFHJKLMNPRSTUVWXZ".chars.to_a
	ch_num = "23457".chars.to_a
	ch_vow = "aeu".chars.to_a
	ch_con = "bcdfhkmnprstvwxz".chars.to_a
	ch_con_double = %w[ ch kh ph sh th ]

	# pass should have at least 4 chars
	if len < 4 then return "" end

	pass = []

	# get 1 number for sure
	pass += [ch_num[rand(ch_num.length)]]

	while true

		# get the rest of the sample randomly
		ch_type_old = -1
		ch_old = ""
		num_vow = 0
		num_con = 0
		first_run = 1
		for i in (0..len-2)

			# choose a char type (vowel or consonant)
			# we have number and upper case already
			ch_type = rand(2)

			# run it until 1 good char returns
			ok = 0
			while ok == 0
				case ch_type

				# vowels -----
				when 0
					# get random char
					ch = ch_vow[rand(ch_vow.length)]

					# is it the first run on the first char?
					if first_run == 1 then
						# make sure there is 1 upper case
						pass += [ch.upcase]
						num_vow += 1
						ok = 1
					else
						# last char was a vowel?
						if ch_type_old == 0
							# max 2 vowels allowed after each other
							# if they're not identical except "ee"
							if num_vow < 2 and (ch != ch_old or ch == "e")
								pass[pass.length-1] += ch
								num_vow += 1
								ok = 1
							else
								# ask for a consonant in the next run
								ch_type = 1
							end
						else
							pass += [ch]
							num_vow += 1
							ok = 1
						end
					end

				# consonants -----
				when 1
					# get random char
					ch = ch_con[rand(ch_con.length)]

					# is it the first run on the first char?
					if first_run == 1 then
						# make sure there is 1 upper case
						pass += [ch.upcase]
						num_con += 1
						ok = 1
					else
						# last char was a consonant?
						if ch_type_old == 1
							# max 2 consonants allowed after each other
							# they must be the same or in the allowed match list
							if num_con < 2 and (ch_old == ch or ch_con_double.include? ch_old + ch)
								pass[pass.length-1] += ch
								num_con += 1
								ok = 1
							else
								# ask for a vowel in the next run
								ch_type = 0
							end
						else
							pass += [ch]
							num_con += 1
							ok = 1
						end
					end

				end
			end

			first_run = 0
			ch_type_old = ch_type
			ch_old = ch

		end

		# shuffle the order of chars of the result
		# it must be done separately in groups of vowels and consonants
		# so the same type won't get next to each other after mixing
		pass_num = pass[0]
		pass_ar1 = []
		pass_ar2 = []
		# start from char 1 because first char is a number
		for i in (1..pass.length-1)
			case i % 2
			when 0
				pass_ar1 += [pass[i]]
			when 1
				pass_ar2 += [pass[i]]
			end
		end
		# shuffle them separately
		#pass_ar1.shuffle!
		#pass_ar2.shuffle!
		pass_ar1 = shuffle(pass_ar1)
		pass_ar2 = shuffle(pass_ar2)
		# put them back to their places
		pass2 = []
		c1 = 0; c2 = 0;
		for i in (1..pass.length-1)
			case i % 2
			when 0
				pass2 += [pass_ar1[c1]]
				c1 += 1
			when 1
				pass2 += [pass_ar2[c2]]
				c2 += 1
			end
		end
		# insert number randomly into somewhere
		pass2.insert(rand(pass2.length+1), pass_num)
		return pass2.join

	end
end


# is there an argument?
if ARGV.length == 0
	# get pronounceable, simple and strong passwords and print them
	10.times do
		print 	get_number(4)			+ " " + \
				get_number(6)			+ " " + \
				get_password_pron(8) 	+ " " + \
				get_password_pron(10)	+ " " + \
				get_password(8)			+ " " + \
				get_password(10)		+ " " + \
				get_password_strong(8)	+ " " + \
				get_password_strong(10)
		puts
	end
	puts
else
	c = ARGV[1].to_i
	c = 1 if c < 1
	n = ARGV[0].to_i
	n = 4 if n < 4
	c.times{ puts get_password_pron(n) }
end
