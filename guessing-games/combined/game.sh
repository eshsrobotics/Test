#!/usr/bin/env bash

# Parallel arrays for storing player data.
names=()   # Names of all the players.
types=()   # The player type (such as "human" or "AI 1".)
mins=()    # You can use this to store the minimum value the number could have (or not.)
maxes=()   # You can use this to store the maximum value the number could have (or not.)
guesses=() # Store the most recent guess here.

# ---------------------------------------------------------------------------
# Initializes a player of the given type.
#
# Arguments:
#   $1: The player number.
# ---------------------------------------------------------------------------
function initializePlayer {
	local playerNumber=$1
	local playerType="${types[$playerNumber]}"
	local name=
	
	if [[ "$playerType" == "human" ]]; then		
	
		read -p "Player #$((playerNumber + 1)), what is your name? " name		
		
	elif [[ "$playerType" == "uche-ai" ]]; then
	
		name="Gamblor the Great"
	
	fi
	
	# Copy the name into the names array.
	names["$playerNumber"]="$name"
}

# ---------------------------------------------------------------------------
# Executes the guess for the given round for the given player.
#
# Arguments:
#   $1: The player number.
#   $2: The round number.
#   $3: The game min.
#   $4: The game max.
# ---------------------------------------------------------------------------
function makeGuess {
	local playerNumber=$1
	local roundNumber=$2
	local gameMin=$3
	local gameMax=$4
	local playerType=${types[$playerNumber]}
	local playerName=${names[$playerNumber]}
	local min=${mins[$playerNumber]}
	local max=${maxes[$playerNumber]}
	local guess=
	
	if [[ "$playerType" == "human" ]]; then		

		read -p "$playerName, I'm thinking of a number between $gameMin and $gameMax.  Enter your guess: " name		

	else
		if [[ "$playerType" == "uche-ai" ]]; then
	
			# Just guess the average.
			guess=$(( (max+min)/2 ))
		fi
		
		echo "$playerName, I'm thinking of a number between $gameMin and $gameMax.  Enter your guess: <<$guess>>"
	fi
	guesses[$playerNumber]=$guess
}

# Adds a player of any type to the game.
#
# Arguments:
#   $1: The player's type.
# Return value: prints the new player's number to stdout.
function addPlayer {

	local playerType=$1
	local numPlayers="${#types[@]}"
	
	types["$numPlayers"]="$playerType"	
	initializePlayer "$numPlayers"
}

# Starts the game for the given player.
#
# Arguments:
#   $1: The player number.
#   $2: The minimum in the number range (the "A" from "I'm thinking of a number between A and B.")
#   $3: The maximum in the number range (the "B" from "I'm thinking of a number between A and B.")

function startGame {
	local playerNumber=$1
	local min=$2
	local max=$3
	mins[$playerNumber]=$min
	maxes[$playerNumber]=$max
	guesses[$playerNumber]=
}

# Responds to a player's guess by printing "HIGHER!" or "LOWER!", then updates the min and max for that player
# and all of the others.
#
# Arguments:
#   $1: The player number.
#   $2: The actual number that would win this game.
#   $3: The game min.
#   $4: The game max.
function respond {
	local playerNumber=$1
	local guess=${guesses[$playerNumber]}
	local playerName=${names[$playerNumber]}
	local actualNumber=$2
	local gameMin=$3
	local gameMax=$4
	
	if ((guess < actualNumber)); then
		echo "Higher!"
		# All players are now aware that the number must be greater.
		for ((i=0; i<${#types[@]}; ++i)); do
			mins[$i]=$((guess + 1))
		done
	elif ((guess > actualNumber)); then
		echo "Lower!"
		# All players are now aware that the number must be less.
		for ((i=0; i<${#types[@]}; ++i)); do
			maxes[$i]=$((guess - 1))
		done
	else
		echo "$playerName has won the game!"
	fi
	
	
}

# Plays the game.
function main {

	local players=()
	local games=1
	local roundsPerGame=10
	
	# Why doesn't this execute addPlayer()?
	# players[${#players[@]}]=$(addPlayer "human")

	addPlayer "human"
	addPlayer "uche-ai"	
	local numPlayers=${#types[@]}
	
	for ((game=0; game<$games; ++game)); do
		
		# Reset the players for this game.
		local min=1
		local max=100
		local number=17
		for ((playerNumber=0; playerNumber<$numPlayers; ++playerNumber)); do
			startGame $playerNumber $min $max
		done
		
		# Run the game.
		for ((round=0; round<$roundsPerGame; ++round)); do
			# Have each player make their guess.
			for ((playerNumber=0; playerNumber<$numPlayers; ++playerNumber)); do
				makeGuess $playerNumber $round $min $max
				respond $playerNumber $number $min $max
			done		
		done
	done
}

main