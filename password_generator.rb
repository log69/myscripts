#!/usr/bin/ruby
# info: generate random passwords without special or mixable chars
# license: public domain
# Andras Horvath <mail@log69.com>


# get a password of a specified length
# that doesn't contain similar easily mixable chars
# and can be used properly on english and hungarian keybords too
# len means an integer of 4 or greater
def get_password(len)

	# all available chars to choose from
	# "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	# exception chars
	# "o|O|0|1|i|j|l|I|z|Z|y|Y|g|q|9"
	# "z" and "y" are exceptions because of querty key maps
	ch = "abcdefhkmnprstuvwxABCDEFGHJKLMNPQRSTUVWX2345678"

	# pass should have at least 4 chars
	if len < 4 then return "" end

	while true
		clow = 0
		cupp = 0
		cnum = 0

		# get a sample
		pass = ""
		for i in (0..len-1)
			x = rand(ch.length)
			c = ch[x..x]
			pass += c

			# low case, upper case or num?
			if c >= "a" and c <= "z" then clow = 1 end
			if c >= "A" and c <= "Z" then cupp = 1 end
			if c >= "0" and c <= "9" then cnum = 1 end

		end

		# pass should have at least 1 low case and 1 upcase letter
		# and 1 number too from the exception list
		# if so, then success and exit
		if clow == 1 and cupp == 1 and cnum == 1 then return pass end

	end
end


# get a _pronounceable_ password of a specified length
# that doesn't contain similar easily mixable chars
# and can be used properly on english and hungarian keybords too
# len means an integer of 4 or greater
#
# the rules are:
# - max 2 vowels may follow each other
# - max 2 consonants may follow each other if they match
# - max 1 upper case letter is allowed
# - max 1 number is allowed
def get_password_pron(len)

	# all available chars to choose from
	# "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	# exception chars
	# "o|O|0|1|i|j|l|I|z|Z|y|Y|g|q|9"
	# "z" and "y" are exceptions because of querty key maps
	ch = "abcdefhkmnprstuvwxABCDEFGHJKLMNPQRSTUVWX2345678"
	ch_vow = "aeuAEU"
	ch_con = "bcdfhkmnprstvwxBCDFGHJKLMNPQRSTVWX"
	ch_num = "2345678"
	ch_con_double = ["sh", "ch", "th"]

	# pass should have at least 4 chars
	if len < 4 then return "" end

	while true

		# get a sample
		pass = ""
		cupp = 0
		ch_type_old = -1
		ch2 = ""
		num_vow = 0
		num_con = 0
		num_num = 0
		first_run = 1
		for i in (0..len-1)

			# choose a char type (vowel, consonant or number)
			# don't choose number if there was one already
			if num_num == 0
				ch_type = rand(3)
			else
				ch_type = rand(2)
			end

			# run it until 1 good char returns
			ok = 0
			while ok == 0
				case ch_type

				# vowels -----
				when 0
					# get random char
					n = rand(ch_vow.length)
					ch1 = ch_vow[n..n]
					if cupp == 1 then ch1 = ch1.downcase end

					# is it the first run on the first char?
					if first_run == 1 then
						pass += ch1
						num_vow += 1
						ok = 1
					else
						# last char was a vowel?
						if ch_type_old == 0
							# max 2 vowels allowed after each other
							if num_vow < 2
								pass += ch1
								num_vow += 1
								ok = 1
							else
								# ask for a consonant in the next run
								ch_type = 1
							end
						else
							pass += ch1
							num_vow += 1
							ok = 1
						end
					end

				# consonants -----
				when 1
					# get random char
					n = rand(ch_con.length)
					ch1 = ch_con[n..n]
					if cupp == 1 then ch1 = ch1.downcase end

					# is it the first run on the first char?
					if first_run == 1 then
						pass += ch1
						num_con += 1
						ok = 1
					else
						# last char was a consonant?
						if ch_type_old == 1
							# max 2 consonants allowed after each other
							# they must be the same or in the allowed match list
							if num_con < 2 and (ch2 == ch1 or ch_con_double.include? ch2.downcase + ch1.downcase)
								pass += ch1
								num_con += 1
								ok = 1
							else
								# ask for a vowel in the next run
								ch_type = 0
							end
						else
							pass += ch1
							num_con += 1
							ok = 1
						end
					end

				# numbers -----
				when 2
					# get random char
					n = rand(ch_num.length)
					ch1 = ch_num[n..n]

					pass += ch1
					num_num += 1
					ok = 1
				end
			end

			first_run = 0
			ch_type_old = ch_type
			ch2 = ch1
			
			# was char an upper case?
			if ("A".."Z").to_a.to_s.include? ch1 then cupp = 1 end
		end


		# check sample
		clow = 0
		cupp = 0
		cnum = 0
		for i in (0..len-1)
			c = pass[i..i]

			# low case, upper case or num?
			if c >= "a" and c <= "z" then clow = 1 end
			if c >= "A" and c <= "Z" then cupp = 1 end
			if c >= "0" and c <= "9" then cnum = 1 end

		end

		# pass should have at least 1 low case and 1 upcase letter
		# and 1 number too from the exception list
		# if so, then success and exit
		if clow == 1 and cupp == 1 and cnum == 1 then return pass end

	end
end


# get simple and pronounceable passwords and print them
# odd columns are much simpler pronounceable passwords
10.times {
	print get_password_pron(6)  + " " + get_password(6)  + " " + \
		  get_password_pron(8)  + " " + get_password(8)  + " " + \
		  get_password_pron(10) + " " + get_password(10)
	puts
}
puts
