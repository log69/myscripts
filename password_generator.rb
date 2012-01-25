#!/usr/bin/ruby
# info: generate random passwords without special or mixable chars
# depends: pwgen
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
			c = ch[x..x].to_s
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
def get_password_pron(len)

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
		cerr = 0

		# get a sample
		pass = `pwgen -c -n -B #{len} 1`
		pass = pass[0..-2]

		for i in (0..len-1)
			c = pass[i..i].to_s

			# no exception chars?
			if not ch.index(c) then cerr = 1 end

			# low case, upper case or num?
			if c >= "a" and c <= "z" then clow = 1 end
			if c >= "A" and c <= "Z" then cupp = 1 end
			if c >= "0" and c <= "9" then cnum = 1 end

		end

		# pass should have at least 1 low case and 1 upcase letter
		# and 1 number too from the exception list
		# if so, then success and exit
		if clow == 1 and cupp == 1 and cnum == 1 \
			and cerr == 0 then return pass end

	end
end


# get simple and pronounceable passwords and print them
puts "pronounceable passwords (8 chars):"
8.times { print get_password_pron(8)  + " " }
puts; puts

puts "fully random passwords (8 chars):"
8.times { print get_password(8)  + " " }
puts; puts

puts "pronounceable passwords (10 chars):"
8.times { print get_password_pron(10) + " " }
puts; puts

puts "fully random passwords (10 chars):"
8.times { print get_password(10) + " " }
puts; puts
