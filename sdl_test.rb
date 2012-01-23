#!/usr/bin/ruby

require 'sdl'

# init SDL
screen_width  = 1000
screen_height = 700
SDL.init SDL::INIT_VIDEO
screen = SDL::set_video_mode screen_width, screen_height, 24, SDL::SWSURFACE
FGCOLOR = screen.format.mapRGB 255, 255, 255
BGCOLOR = screen.format.mapRGB 0, 0, 0


# store random pixel coords
num = 500
speed = 5
rad = 3
points = []
for i in (1..num) do points[i] = \
	[rand * screen_width, rand * screen_height] end

# run it
running = true
while running
	while event = SDL::Event2.poll
		case event
		when SDL::Event2::Quit
			running = false
		#when SDL::Event2::MouseMotion
			#x = event.x
			#y = event.y
		end
	end

	# clear screen
	screen.fill_rect 0, 0, screen_width, screen_height, BGCOLOR

	# draw points
	for i in (1..num)
		#screen.put_pixel points[i][0], points[i][1], FGCOLOR end
		screen.draw_filled_circle points[i][0], points[i][1], rad, FGCOLOR end

	# update screen
	screen.flip

	# move points toward each other
	r_max = 0
	for i1 in (1..num)
		i2 = i1 + 1
		if i2 > num then i2 = 1 end

		x1 = points[i1][0]
		y1 = points[i1][1]
		x2 = points[i2][0]
		y2 = points[i2][1]

		r = ((x2 - x1) ** 2 + (y2 - y1) ** 2) ** 0.5
		x3 = (x2 - x1) * speed / r + x1
		y3 = (y2 - y1) * speed / r + y1
		
		if r > r_max then r_max = r end

		points[i1][0] = x3
		points[i1][1] = y3
	end
	
	# generate new points when all points are too close
	if r_max < speed * 2 then
		for i in (1..num) do points[i] = \
			[rand * screen_width, rand * screen_height] end
	end

end
