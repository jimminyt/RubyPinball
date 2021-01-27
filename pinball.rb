# Assignment: small pinball game

require 'io/console'

# cursor keys to control the racquet
RIGHT="\e[C"
LEFT="\e[D"

# Cells on the screen, blank and two boundaries, horizontal and vertical
SC_BLANK=' '
SC_H='-'
SC_V='|'
SC_STAR='*'

# The size of the screen
SCREEN_X=15
SCREEN_Y=15

RACQUET_SIZE=4

# the initial position of the ball
$x=SCREEN_X/2+2
$y=SCREEN_Y/2-2

# the old coordinates of the ball
$oldx=$x;$oldy=$y

# the speed of the ball - how much to increase the value of $x and $y per time unit.
$dx=0.1
# negative value means the ball is moving up the screen,
# positive means moving down.
$dy=0.2

# new globals to track ball movements and allocate stars to locations.
$moves = 0
$stars = Array.new(SCREEN_Y) { Array.new(SCREEN_X, 0)}

# used to configure keyboard for input without having to press Enter
def startKbd
	$stdin.echo=false
	$stdin.raw!
end

# used to configure keyboard for input when pinball terminates.
def endKbd
	$stdin.echo=true
	$stdin.cooked!
end

# obtains keystroke from keyboard if available
def readChar
	input = STDIN.read_nonblock(1) rescue nil
	if  input == "\e" then
		input  << STDIN.read_nonblock(1)  rescue  nil
		input  << STDIN.read_nonblock(1)  rescue  nil
	end
	
	return  input
end

# You are expected to modify this function to support bouncing of the ball
# on the walls and the racquet.
# Update is expected to return Nil if the ball misses a racquet.
# Otherwise, true is returned if the screen should not be updated (ball in the 
# same visible position) and false if the screen should be updated.
# The visible position is determined by the truncation of the floating-point values
# of the ball coordinates $x and $y, via $x.floor and $y.floor.
# You can use screen[$y.floor][$x.floor] to determine the cell that a ball 
# is going to hit. If it if SC_BLANK, it contains empty space.
# For SC_V it means a vertical wall.
# For SC_H,it is a horizonal wall.
# racquet is the horizonal coordinate of the centre of the racquet.
# testmode is true if this routine is run in a test mode where it is supposed
# to report the decisions it has made.
def update(racquet,screen,testmode)
    x=$x.floor
    y=$y.floor
    $x+=$dx
    $y+=$dy
    # Check for new location being a blank space
    if screen[$y.floor][$x.floor] == SC_BLANK || screen[$y.floor][$x.floor] == SC_STAR
        return false
    # Vertical walls
    elsif screen[$y.floor][$x.floor] == SC_V
        $dx = -$dx #Inverts x direction
    # Horizontal walls 
    elsif screen[$y.floor][$x.floor] == SC_H
        # Inverts y direction for walls not at the bottom of the screen
        if $y.floor != 14
            $dy = -$dy
        # Checks if ball reflects off racquet
        elsif ($x.floor - racquet >= -1) && ($x.floor - racquet <= 2)
            # Off centre bounces
            if ($x.abs - racquet >= 1) || ( $x.abs - racquet <= -1)
                $dx = rand(-0.9..0.9)
                # Cases where the ball maintains speed
                if $dx < 0.22 
                    $dy = -Math.sqrt(Math.sqrt((0.22-($dx*$dx))*(0.22-($dx*$dx))))
                # Otherwise new formula used which makes higher dx values give lower dy values
                else
                    $dy = -(0.15 - ($dx/7))
                end            
            else
                $dy = -$dy
            end
        # Ball missed
        else
            return nil
        end
    end
    print "no_wall" if testmode
    return x==$x.floor && y == $y.floor
end

# You are expected to write this to display the racquet
# It already contains a routine to display the ball.
# The idea is that displaying an expression 
# "\e[#{Y};#{X}H"
# can be used to place a cursor in position with coordinates X,Y 
# on the screen (starting from 1,1 for the top-left corner).
def displayDyn(screen,racquet)
    
  # clears the old position of the ball, using the value in the screen array
  # and plots the current position.
  if $y >= 0 && $x >= 0 && $y < SCREEN_Y && $x < SCREEN_X
      # Updates when ball moves to a new location on the grid
      if ($y.floor != $oldy.floor) || ($x.floor != $oldx.floor)
          $moves += 1
          $stars[$oldy.floor][$oldx.floor] += 1 # Increments array of number of visits for old location         
          # When conditions met then array is updated to contain star
          if $stars[$oldy.floor][$oldx.floor] > 3 && $stars[$oldy.floor][$oldx.floor]>($stars[$oldy.floor][$oldx.floor]/$moves)*50 && screen[$oldy.floor][$oldx.floor] == SC_BLANK
              screen[$oldy.floor][$oldx.floor] = SC_STAR
          end
      end
		# erases the old ball position
      print "\e[#{1+$oldy.floor};#{1+$oldx.floor}H#{screen[$oldy.floor][$oldx.floor]}"
		# displays the new position
      print "\e[#{1+$y.floor};#{1+$x.floor}H@"
		# records the current coordinates of the ball so that when displayDyn is 
		# called again, the ball can be erased
      $oldx=$x.floor;$oldy=$y.floor
  end
  # Prints out bottom row of horizontal walls
  (2..14).each do |x|
      print "\e[#{15};#{x}H-"
  end
  # Prints racquet at current racquet location
  (racquet-1..racquet+2).each do |x|    
      print "\e[#{15};#{x}H="
  end
  
end

# You need to write the routine that will display the contents
# of the screen array including walls at the top, bottom, sides 
# as well as the walls in the middle.
def displayBoundaries(screen)
  # this clears the screen and sets the cursor to the top-left corner
  # Iterates through whole of 2d screen array
  (0...screen.length).each do |x|
      (0...screen[x].length).each do |y|
          print screen[x][y] # Prints screen item
      end
      puts "" # New line
  end
  print "\e[#{1};#{1}H" # Resets cursor
end

# you need to write the code to update the position of the racquet when a user presses cursor left
def racquetLeft(racquet)
    # If the racquet has space to move left the new racquet value is returned
	if racquet > 3
        return racquet - 1
    else
        return racquet
    end
end

# you need to write the code to update the position of the racquet when a user presses cursor right
def racquetRight(racquet)
	if racquet < 12
        return racquet + 1
    else
        return racquet
    end
end
  
# Reports that the game is over
def displayEndgame
 	puts "\e[#{SCREEN_Y+1};#{1}HGame over.\e[#{SCREEN_Y+2};#{1}H"
end

# This is a routine to run the game
def mainloop(screen)
	# draws the screen
	displayBoundaries(screen)
	# configures keyboard
	startKbd

	# initial racquet position in the middle
	racquet=SCREEN_X/2
	# displayes the ball and racquet
  displayDyn(screen,racquet)
    
	loop do
    # updates the position of the ball
    u=update(racquet,screen,false)
    if u == nil
      # missed the racquet, game over
      displayEndgame
      break
    elsif !u
      # display needs to be updated
      displayDyn(screen,racquet)
    end

    ch = readChar
    if ch == 'q' || ch == "\003" 
      # character 'q' or Ctrl-C means 'quit the game'
      displayEndgame
      break
    elsif ch != nil
      if ch == LEFT 
        racquet = racquetLeft(racquet)
      elsif ch == RIGHT
        racquet = racquetRight(racquet)
      end

    end
    # 100ms per cycle
    sleep(0.1)	
    end
    ensure
		# ensures that when application stops, the keyboard is in a usable state
		endKbd
end

# You can use this routine for testing of collisions: running 
# the ball and watching it go through the walls is not fun.
# For testing, add "puts" statements to the 'update' routine above
# such that if the value of testmode is true, it will display
# decisions it is making. For example, to report bouncing from a vertical wall 
# you can write the following line:
# puts "LR" if testmode
# to mean that line "LR" will be displayed if testmode is true.
# In this case, you can try calling tryupdate(0,SCREEN_Y/2,screen)
# to see if it will display the correct response.
#
# What your code should display: 
# "LR" for a ball hitting a vertical wall
# "UD" for a ball hitting a horizontal wall
# "no_wall" for a ball not hitting anything
# "racquet_miss" for a ball	 missing a racquet
# "racquet_hit" for a ball reflecting from a raquet
# "racquet_hit RND" to indicate that a ball reflected from a peripheral part of the 
# racquet.
def tryupdate(x,y,screen)
	$x=x;$y=y
	print "#{x},#{y} : "
	update(SCREEN_X/2,screen,true)
  puts
end

# this routine is the test routine - you can add tryupdate calls to it
# to check that you correctly detect when the ball should reflect from 
# a racquet and when it will miss it.
def trytest(screen)
	$dx=0;$dy=0
	tryupdate(0.5,SCREEN_Y/2,screen)
  tryupdate(SCREEN_Y-1.5,SCREEN_Y/2,screen)
end

# This is the main part of the code
begin
	#creating the boundaries
	screen = Array.new(SCREEN_Y) { Array.new(SCREEN_X, SC_BLANK)}

	(0...SCREEN_Y).each do |row|
		(0...SCREEN_X).each do |column| 
		  if row == 0 || row == SCREEN_Y-1
		    screen[row][column] = SC_H
		  end
			if column == 0 || column == SCREEN_X-1
				screen[row][column] = SC_V
			end
		end
	end
        

	# This code adds t-shape wall in the middle of the screen
	(4...SCREEN_X/2).each do |column| 
		screen[SCREEN_Y/2][column] = SC_H
	end

	(5...SCREEN_Y-5).each do |row| 
		screen[row][SCREEN_X/2] = SC_V
	end

	# this runs the main loop for the game
	mainloop(screen)

	# if you comment out the above main loop and instead uncomment trytest, 
	#it will run your test routines.
	#trytest(screen)

end

