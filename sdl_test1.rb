#!/usr/bin/env ruby
# info: Screen class for simple 2D graphics using SDL
# depends: libsdl-ruby
# original example code taken from:
# http://lorenzod8n.wordpress.com/2007/05/30/ruby-meet-sdl/
# license: GPLv3+ <http://www.gnu.org/licenses/gpl.txt>
# Andras Horvath <mail@log69.com>
#
# SDL INSTALL:
#
# on Debian or Ubuntu:
# sudo apt-get install libsdl-sge libsdl-sge-dev libsdl-dev
# sudo gem install rubysdl
#
# on Fedora, RHEL or clones:
# su -c "yum group install 'Development Tools'"
# su -c "yum install ruby ruby-devel rubygems SDL SDL-devel SDL_image SDL_image-devel freetype-devel"
#
# # compile and install ruby 1.9.x rather from source if only 1.8.x is available
#
# # get source code from these sites:
# # http://www.digitalfanatics.org/cal/sge/
# # http://packages.debian.org/source/stable/libsdl-sge
#
# wget "http://ftp.de.debian.org/debian/pool/main/libs/libsdl-sge/libsdl-sge_030809dfsg.orig.tar.gz"
# wget "http://ftp.de.debian.org/debian/pool/main/libs/libsdl-sge/libsdl-sge_030809dfsg-3.debian.tar.gz"
# tar xf *sge*orig*
# tar xf *sge*debian*
#
# cd sge*
# find ../debian/patches/ -iname "*.diff" | sort | while read FF; do patch < "$FF"; done
#
# make
# su -c "make install; ldconfig"
#
# su -c "gem install rubysdl"
#


require 'sdl'


# Screen object using SDL
# rubysdl home:
# http://www.kmc.gr.jp/~ohai/rubysdl.en.html
# SDL doc:
# http://www.kmc.gr.jp/~ohai/rubysdl_doc.en.html
class Screen
	attr_reader	:width, :height

	# init and show screen
	def initialize(width = 800, height = 600)
		@width = width
		@height = height
		SDL.init SDL::INIT_VIDEO
		@screen = SDL::set_video_mode @width, @height, 24, SDL::SWSURFACE
		@color_bg = @screen.format.mapRGB 240, 240, 240
		@color_fg = @screen.format.mapRGB 0, 0, 0
		clear
	end

	# clear the content of screen
	def clear
		@screen.fill_rect 0, 0, @width, @height, @color_bg
	end

	# switch screen to the active buffer and show it
	def show
		@screen.flip
	end

	# return an event in an array [:description, param1, param2, ...]
	def event
		while event = SDL::Event2.poll
			case event
			when SDL::Event2::Quit
				return [:quit]
			when SDL::Event2::MouseButtonDown
				return [:mouse, event.x, event.y]
			when SDL::Event2::KeyDown
				return [:escape] if event.sym == SDL::Key::ESCAPE
				return [:space]  if event.sym == SDL::Key::SPACE
			end
		end
		return []
	end

	# draw a point
	def point(x, y)
		@screen.drawLine x, y, x, y, @color_fg
	end

	# draw a line
	def line(x1, y1, x2, y2)
		@screen.drawAALine x1, y1, x2, y2, @color_fg
	end

	# draw a rectangle
	def rect(x1, y1, x2, y2)
		@screen.drawRectAlpha x1, y1, x2-x1, y2-y1, @color_fg, 255
	end

	# draw a filled rectangle
	def rect_filled(x1, y1, x2, y2)
		@screen.drawFilledRectAlpha x1, y1, x2-x1, y2-y1, @color_fg, 255
	end

	# draw a cirlce
	def circle(x, y, r)
		@screen.drawAACircle x, y, r, @color_fg
	end

	# draw a filled cirlce
	def circle_filled(x, y, r)
		@screen.drawAAFilledCircle x, y, r, @color_fg
	end

	# draw an ellipse
	def ellipse(x, y, rx, ry)
		@screen.drawAAEllipse x, y, rx, ry, @color_fg
	end

	# draw a filled ellipse
	def ellipse_filled(x, y, rx, ry)
		@screen.drawAAFilledEllipse x, y, rx, ry, @color_fg
	end
end



# main
s = Screen.new(600, 400)

10.times{ s.circle(rand(s.width), rand(s.height), rand(50)) }
10.times{ s.line(rand(s.width), rand(s.height), rand(s.width), rand(s.height)) }
s.show

# wait for escape key or window close to quit
e = []
while e[0] != :quit and e[0] != :escape do

	if e[0] == :mouse
		s.circle(e[1], e[2], rand(50))
		s.show
	end

	e = s.event
	sleep 0.01
end

exit
