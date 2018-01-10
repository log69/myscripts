#!/usr/bin/env ruby
# info: print info about zram memory compression ratio if any


def add(text); text.split.map{|x|x.to_i}.inject(:+).to_i / 1024 / 1024; end


if File.exist? "/sys/block/zram0"

	orig = add `zramctl --bytes --noheadings --output  DATA`
	comp = add `zramctl --bytes --noheadings --output COMPR`

	div  = (orig == 0) ? 0 : (100 * comp / orig)

	puts "Swap: Zram ratio (orig / comp): #{orig}M / #{comp}M -> #{div}%"

else

	warn "error: no zram available"

end
