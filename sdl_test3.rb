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
# sudo apt-get install libsdl-sge
# sudo gem install rubsdl
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


class Cube
	# set initial properties for object
	def initialize(center_x = 0, center_y = 0, center_z = 0, size = 1)
		# rectangles of object
		@rect = [	[[-1, +1, -1], [+1, +1, -1], [+1, -1, -1], [-1, -1, -1]], \
					[[-1, +1, +1], [-1, -1, +1], [+1, -1, +1], [+1, +1, +1]], \
					[[-1, +1, -1], [-1, -1, -1], [-1, -1, +1], [-1, +1, +1]], \
					[[+1, +1, -1], [+1, +1, +1], [+1, -1, +1], [+1, -1, -1]], \
					[[-1, +1, -1], [-1, +1, +1], [+1, +1, +1], [+1, +1, -1]], \
					[[-1, -1, -1], [+1, -1, -1], [+1, -1, +1], [-1, -1, +1]] ]
		# setup init values
		@rect.each do |a|
			a.each do |b|
				# set initial size
				b[0] *= size
				b[1] *= size
				b[2] *= size
				# set initial position
				b[0] += center_x
				b[1] += center_y
				b[2] += center_z
			end
		end
	end

	def get_rect
		return @rect
	end

	# rotate points of object around its middle point
	def rotate(angle_x = 0, angle_y = 0, angle_z = 0)
		c = 0; cx = 0; cy = 0; cz = 0
		# get middle point
		@rect.each do |a|
			a.each do |b|
				cx += b[0]
				cy += b[1]
				cz += b[2]
				c  +=1
			end
		end
		cx /= c; cy /= c; cz /= c
		# rotate points
		@rect.each do |a|
			a.each do |b|
				x = b[0]; y = b[1]; z = b[2]

				x, y, z = rotate_point(x, y, z, cx, cy, cz, angle_x, angle_y, angle_z)

				b[0] = x; b[1] = y; b[2] = z
			end
		end
	end

	# rotate points of object around origo
	def rotate_origo(angle_x = 0, angle_y = 0, angle_z = 0)
		@rect.each do |a|
			a.each do |b|
				x = b[0]; y = b[1]; z = b[2]

				x, y, z = rotate_point(x, y, z, 0, 0, 0, angle_x, angle_y, angle_z)

				b[0] = x; b[1] = y; b[2] = z
			end
		end
	end

	# draw object
	def draw(screen)
		@rect.each do |a|
			# draw lines of rectangle
			line(screen, a[0], a[1])
			line(screen, a[1], a[2])
			line(screen, a[2], a[3])
			line(screen, a[3], a[0])
		end
	end

	# draw object in rotated angle
	def draw_rotated(screen, angle_x = 0, angle_y = 0, angle_z = 0)
		@rect.each do |a|
			# get rotated points
			b = []
			a.each do |a2|
				b += [rotate_point(a2[0], a2[1], a2[2], 0, 0, 0, angle_x, angle_y, angle_z)]
			end
			# draw lines of rectangle
			line(screen, b[0], b[1])
			line(screen, b[1], b[2])
			line(screen, b[2], b[3])
			line(screen, b[3], b[0])
		end
	end

	# private methods
	private

	# rotate point around origo (point, origo, angles)
	def rotate_point(x, y, z, cx, cy, cz, angle_x, angle_y, angle_z)
		x -= cx ; y -= cy; z -= cz

		# rotate around x axis
		ac = Math.cos(angle_x) ; as = Math.sin(angle_x)
		y2 = y * ac - z * as
		z2 = z * ac + y * as
		y = y2
		z = z2

		# rotate around y axis
		ac = Math.cos(angle_y) ; as = Math.sin(angle_y)
		x2 = x * ac - z * as
		z2 = z * ac + x * as
		x = x2
		z = z2

		# rotate around z axis
		ac = Math.cos(angle_z) ; as = Math.sin(angle_z)
		y2 = y * ac - x * as
		x2 = x * ac + y * as
		y = y2
		x = x2

		x += cx ; y += cy; z += cz
		return x, y, z
	end

	# draw a line between 2 points
	def line(screen, p1, p2)
		# convert coords
		x1d, y1d = convert_coords(screen, p1[0], p1[1], p1[2])
		x2d, y2d = convert_coords(screen, p2[0], p2[1], p2[2])
		# draw line
		screen.line(x1d, y1d, x2d, y2d)
	end

	# convert coords to screen coords using perspectivity
	def convert_coords(screen, x, y, z)
		xd = x * $persp / (z + $space_size) + screen.width  / 2
		yd = y * $persp / (z + $space_size) + screen.height / 2
		return xd, yd
	end

end


# --------------------------------------
# ---------------- main ----------------
# --------------------------------------

# init
s = Screen.new(1000, 700)

# consts
$space_size		= 1000
$persp			= 500

# create objects
cube1 = Cube.new(0, 0, 0, 200)
cube2 = Cube.new(-500, 0, 0, 50)


# wait for escape key or window close to quit
e = []
x = 0; y = 0; z = 0
while e[0] != :quit and e[0] != :escape do

	# clear screen
	s.clear

	# change objects
	x += 0.02
	y += 0.033
	z += 0.005
	cube1.draw_rotated(s, x, y, z)

	cube2.rotate(0.03, 0.06, 0.04)
	cube2.rotate_origo(0.00, -0.01, 0.00)

	cube2.draw(s)

	# show drawing
	s.show

	e = s.event
	sleep 0.01
end

exit
