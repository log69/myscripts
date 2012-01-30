#!/usr/bin/env ruby
# info: sdl test in ruby, some playing around with wired 3D objects
# depends: libsdl-ruby
# license: GPLv3+ <http://www.gnu.org/licenses/gpl.txt>
# Andras Horvath <mail@log69.com>

require 'sdl'

# consts
$screen_width	= 1000
$screen_height	= 700
$space_size		= 1000
$persp			= 500
$BGCOLOR		= 0xffffff
$FGCOLOR		= 0x000000


class Screen

	# init and create SDL screen
	def initialize
		SDL.init SDL::INIT_VIDEO
		@screen = SDL::set_video_mode $screen_width, $screen_height, 24, SDL::SWSURFACE
		@screen.fill_rect 0, 0, $screen_width, $screen_height, $BGCOLOR
	end

	# get screen object
	def get
		return @screen
	end

	# clear screen
	def clear
		@screen.fill_rect 0, 0, $screen_width, $screen_height, $BGCOLOR
	end

	# update screen
	def update
		@screen.flip
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
		# get screen object
		s = screen.get
		# convert coords
		x1d, y1d = convert_coords(p1[0], p1[1], p1[2])
		x2d, y2d = convert_coords(p2[0], p2[1], p2[2])
		# draw line
		s.draw_aa_line(x1d, y1d, x2d, y2d, $FGCOLOR)
	end
	
	# convert coords to screen coords using perspectivity
	def convert_coords(x, y, z)
		r = (x * x + y * y + (z - $space_size) * (z - $space_size)) ** 0.5
		xd = x * $persp / r + $screen_width  / 2
		yd = y * $persp / r + $screen_height / 2
		return xd, yd
	end

end


# --------------------------------------
# ---------------- main ----------------
# --------------------------------------

# init
screen = Screen.new

# create objects
cube1 = Cube.new(0, 0, 0, 200)
cube2 = Cube.new(500, 0, 0, 50)

# run it
running = true
while running
	while event = SDL::Event2.poll
		case event
		when SDL::Event2::Quit
			running = false
		when SDL::Event2::MouseMotion
			x = event.x
			y = event.y
		when SDL::Event2::KeyDown
			if event.sym == SDL::Key::ESCAPE
				running = false end
			if event.sym == SDL::Key::SPACE
				running = false end
		end
	end

	# clear screen
	screen.clear

	# change objects
	cube1.draw_rotated(screen,	-(y - $screen_height / 2).to_f/100.0, \
								-(x - $screen_width /  2).to_f/100.0, 0)
	cube2.rotate(0.03, 0.06, 0.04)
	cube2.rotate_origo(0.00, 0.01, 0.00)
	cube2.draw(screen)

	# update screen
	screen.update

end
