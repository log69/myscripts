#!/usr/bin/env ruby
# info: generate random passwords without special or mixable chars too
# command [pass length]
# without parameter it prints 6 columns of passwords
# each containing stronger ones by going to the right
# license: GPLv3+ <http://www.gnu.org/licenses/gpl.txt>
# Andras Horvath <mail@log69.com>


# shuffle method of Array class is not available before Ruby 1.8.7
# add it to make this script compatible with earlier versions too
# this fucntion is 10 times slower then the shuffle method in 1.8.7
# info: mix the contents of an array in random order
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
	ch = "abcdefhkmnprstuvwxABCDEFHJKLMNPRSTUVWX234578".split("")
	ch_low = "abcdefhkmnprstuvwx".split("")
	ch_upp = "ACDEFHJKLMNPRSTUVWX".split("")
	ch_num = "23457".split("")

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
	#return pass.split("").shuffle.join
	return shuffle(pass.split("")).join
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
	# "o|O|0|Q|1|i|j|l|I|z|Z|y|Y|g|q|9|G|6|B|8"
	# "z" and "y" are exceptions because of querty key maps
	ch = "abcdefhkmnprstuvwxACDEFHJKLMNPRSTUVWX23457".split("")
	ch_low = "abcdefhkmnprstuvwx".split("")
	ch_upp = "ACDEFHJKLMNPRSTUVWX".split("")
	ch_num = "23457".split("")
	ch_vow = "aeu".split("")
	ch_con = "bcdfhkmnprstvwx".split("")
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
		print 	get_password_pron(8) 	+ " " + \
				get_password_pron(10)	+ " " + \
				get_password(8)			+ " " + \
				get_password(10)		+ " " + \
				get_password_strong(8)	+ " " + \
				get_password_strong(10)
		puts
	end
	puts
else
	n = ARGV[0].to_i
	# argument must be a number greater than 4
	if n >= 4
		10.times do
		print 	get_password_pron(n) 	+ " " + \
				get_password(n)			+ " " + \
				get_password_strong(n)
		puts
		end
	end
end
