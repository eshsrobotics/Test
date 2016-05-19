#!/usr/bin/env bash

# Parallel arrays for storing player data.
names=()   # Names of all the players.
types=()   # The player type (such as "human" or "AI 1".)
mins=()    # You can use this to store the minimum value the number could have (or not.)
maxes=()   # You can use this to store the maximum value the number could have (or not.)
guesses=() # Store the most recent guess here.
wins=()    # Updated when the game ends.
losses=()  # Updated when the game ends.
debug=     # Set to 1 to print debugging statements.

# ---------------------------------------------------------------------------
# Initializes a player of the given type.
#
# Arguments:
#   $1: The player number.
# ---------------------------------------------------------------------------
function playerInitialize {
    local playerNumber=$1
    local playerType="${types[$playerNumber]}"
    local name=

    if [[ "$playerType" == "human" ]]; then

        read -p "Player #$((playerNumber + 1)), what is your name? " name

    elif [[ "$playerType" == "binary-search" ]]; then

        name="Computron"

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
function playerGuess {
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

        read -p "game> $playerName: I'm thinking of a number between $gameMin and $gameMax.  Enter your guess: " guess

    else
        # Computer players go here.

        if [[ "$playerType" == "binary-search" ]]; then
            # Just guess the average.
            guess=$(( (max+min)/2 ))
        fi

        printf "game> $playerName: I'm thinking of a number between $gameMin and $gameMax.  Enter your guess: "
        dramaticPrint "$guess\n" 0.2 0 0.4
    fi
    guesses[$playerNumber]=$guess
}

# Gives a(n AI) player the opportunity to respond to a guess from a different player.
#
# Arguments:
#   $1: The number of the (AI) player.
#   $2: The number of the player that just made their move.  (This is never
#       equal to $1.)
#   $3: The exact guess the player made.
#   $4: The game's assessment of the guess.  It will be one of "too-high",
#       "high", "correct", "low", or "too-low".  The "too-" prefix indicates
#       that the player made a terrible guess and should have paid more
#       attention.
function playerReply {
    local playerNumber=$1
    local playerType=${types[$playerNumber]}
    local playerName=${names[$playerNumber]}
    local enemyNumber=$2
    local enemyType=${types[$enemyNumber]}
    local enemyName=${names[$enemyNumber]}
    local enemyGuess=$3
    local enemyGuessType=$4

    debug "Player speaking=%s, player that just guessed=%s, game assessment of %s's guess=%s\n." "$playerName" "$enemyName" "$enemyName" "$enemyGuessType"

    if [[ $playerType == "human" ]]; then

        # Bots only!
        return
    fi

    local message=
    if [[ $playerType == "binary-search" ]]; then

        case "$enemyGuessType" in
            "too-low"|"too-high")
                local insults=("THIS WILL BE EASIER THAN I IMAGINED" "PLEASE FINE-TUNE YOUR GUESSING ALGORITHM" "KEEP TRYING, HUMAN" "BUT THAT'S...NEVER MIND" "YOUR GUESS IS HIGHLY ILLOGICAL")
                local taunts=("YOUR GUESS WAS STUPID" "FORGET IT, NOT WORTH THE ELECTRONS" "BRING YOUR A-GAME, HUMAN" "I KNOW TRANSISTORS WITH SUPERIOR GUESSING ABILITY" "KNAVE" "ERROR: WORTHY OPPONENT NOT FOUND" "PLEASE WASTE ANOTHER GUESS TO CONTINUE" "LET'S JUST SAY YOU'RE A FEW BITS SHORT OF A BYTE" "A MIND IS A TERRIBLE THING TO WASTE")
                local random_taunt=${taunts[$(( RANDOM % ${#taunts[@]} ))]}
                insults[${#insults[@]}]="LOADING INSULT DATABASE . . . $random_taunt"
                insults[${#insults[@]}]="LOADING INSULT DATABASE . . . $random_taunt" # Taunt twice as often.
                message=${insults[$(( RANDOM % ${#insults[@]} ))]}
                # message=$random_taunt
                ;;
            "high"|"low")
                return
                ;;
            "correct")
                printf "%s> " "$playerName"
                if [[ "$enemyType" == "human" ]]; then
                    dramaticPrint "I LOST TO A\n\n    -HUMAN-\n\n" .05 .05 .5
                    dramaticPrint "DOES NOT COMPUTE\n" .03 .3 .5
                    dramaticPrint "DOES NOT COMPUTE\n" .015 .5 .6
                    dramaticPrint "DOES NO" 0 .8 0
                    dramaticPrint "\n       ?PARSE ERROR ON LINE 1\n\n" 0 0 0
                else
                    dramaticPrint "I LOST TO A COMPUTER PLAYER\n" 0 0 1
                    dramaticPrint "WELL, THAT'S ALRIGHT THEN\n" 0 0 0
                fi
                return
                ;;
        esac
    fi

    printf "%s> " "$playerName"
    dramaticPrint "$message" .015 .025 .33
    printf "\n"
}

# --------------------------------------------------------------------------
# Functions that are the same for all player types follow.

# This is like printf, but for debugging, and it respects the global $debug
# flag.
#
# Arugments:
#   $1: The format string
#   $2...:  The rest of the args.
function debug {
    local format=$1
    shift
    if [[ $debug ]]; then
        printf "[debug] $format" "$@"
    fi
}

# This is like echo -e, but it prints character by character with the given
# delays.
#
# Arguments:
#   $1: The string to print
#   $2: The delay (in floating point seconds) between printing each character.
#   $3: The delay between printing each word.
#   $4: The final delay at the end.
function dramaticPrint  {
    local s=$1

    # All of these default to "0", or at least they're supposed to.
    local charDelay="${2:0}"
    local wordDelay="${3:0}"
    local finalDelay="${4:0}"

    for ((i=0; i<${#s}; ++i)); do
        local c="${s:$i:1}"
        if [[ "$c" == "\\" ]]; then
            # Handle all escape characters.
            c="${s:$i:2}"
            i=$((i+1))
        fi
        if [[ "$c" == " " || "$c" == "\\n" ]]; then
            sleep $wordDelay
        else
            sleep $charDelay
        fi
        echo -ne "$c"
    done
    sleep $finalDelay
}

# Adds a player of any type to the game.
#
# Arguments:
#   $1: The player's type.
# Return value: prints the new player's number to stdout.
function gameAddPlayer {

    local playerType=$1
    local numPlayers="${#types[@]}"

    types[$numPlayers]="$playerType"
    wins[$numPlayers]=0
    losses[$numPlayers]=0

    playerInitialize "$numPlayers"
}

# Starts the game for the given player.
#
# Arguments:
#   $1: The player number.
#   $2: The minimum in the number range (the "A" from "I'm thinking of a number between A and B.")
#   $3: The maximum in the number range (the "B" from "I'm thinking of a number between A and B.")

function gameStart {
    local playerNumber=$1
    local min=$2
    local max=$3
    mins[$playerNumber]=$min
    maxes[$playerNumber]=$max
    guesses[$playerNumber]=
}

# Responds to a player's guess by printing "HIGHER!" or "LOWER!", then updates
# the min and max for that player and all of the others.
#
# If a player won, the victory and loss counters are updated and the function
# returns 1.  Otherwise, the function returns 0.
#
# Arguments:
#   $1: The player number.
#   $2: The actual number that would win this game.
#   $3: The game min.
#   $4: The game max.
function gameRespond {
    local playerNumber=$1
    local guess=${guesses[$playerNumber]}
    local playerName=${names[$playerNumber]}
    local actualNumber=$2
    local gameMin=$3
    local gameMax=$4

    if ((guess < actualNumber)); then
        echo "game> $playerName: Higher!"
        # All players are now aware that the number must be greater.
        for ((i=0; i<${#types[@]}; ++i)); do
            # Human players use their brains instead of code.
            if [[ "${types[$i]}" == "human" ]]; then
                continue
            fi

            if (( ${mins[$i]} < guess + 1 )); then
                # Good guess -- thanks for the info.
                debug "Player #%d (%s) updated min from %d to %d.\n" $i "${names[$i]}" ${mins[$i]} $((guess + 1))
                mins[$i]=$((guess + 1))

                # But don't reply to ourselves.
                if [[ $i != $playerNumber ]]; then
                    playerReply $i $playerNumber $guess "low"
                fi
            elif [[ $i != $playerNumber ]]; then
                # Bad guess -- insult opportunities.
                debug "Player #%d (%s) thinks that player #%d (%s) guessed too low (should have been at least %d).\n" $i "${names[$i]}" $playerNumber "$playerName" ${mins[$i]}
                playerReply $i $playerNumber $guess "too-low"
            fi
        done
    elif ((guess > actualNumber)); then
        echo "game> $playerName: Lower!"
        # All players are now aware that the number must be less.
        for ((i=0; i<${#types[@]}; ++i)); do
            # Human players use their brains instead of code.
            if [[ "${types[$i]}" == "human" ]]; then
                continue
            fi

            if (( ${maxes[$i]} > guess - 1 )); then
                # Good guess -- thanks for the info.
                debug "Player #%d (%s) updated max from %d to %d.\n" $i "${names[$i]}" ${maxes[$i]} $((guess - 1))
                maxes[$i]=$((guess - 1))
                # But don't reply to ourselves.
                if [[ $i != $playerNumber ]]; then
                    playerReply $i $playerNumber $guess "high"
                fi
            elif [[ $i != $playerNumber ]]; then
                # Bad guess -- insult opportunities.
                debug "Player #%d (%s) thinks that player #%d (%s) guessed too high (should have been at most %d).\n" $i "${names[$i]}" $playerNumber "$playerName" ${maxes[$i]}
                playerReply $i $playerNumber $guess "too-high"
            fi
        done
    else
        echo "$playerName has won the game!"
        wins[$playerNumber]=$(( ${wins[$playerNumber]} + 1 ))

        # Let the other players get one final round of responses.
        for ((i=0; i<${#types[@]}; ++i)); do
            if [[ $i != $playerNumber ]]; then
                playerReply $i $playerNumber $guess "correct"
                losses[$i]=$(( ${losses[$i]} + 1 ))
            fi
        done

        return 1
    fi

    return 0
}

# Plays the game.
function main {

    local players=()
    local games=1
    local roundsPerGame=10

    # Why doesn't this execute gameAddPlayer()?
    # players[${#players[@]}]=$(gameAddPlayer "human")

    gameAddPlayer "human"
    gameAddPlayer "binary-search"
    local numPlayers=${#types[@]}

    for ((game=0; game<$games; ++game)); do

        # Reset the players for this game.
        local min=1
        local max=100
        local number=$(( RANDOM % (max - min) + 1 ))
        for ((playerNumber=0; playerNumber<$numPlayers; ++playerNumber)); do
            gameStart $playerNumber $min $max
        done
        printf "game> Starting game #%d of %d.\n" "$((game + 1))" $games
        printf "game> Good luck!\n"

        # Run the game.
        for ((round=0; round<$roundsPerGame; ++round)); do
            # Have each player make their guess.
            local winner=
            for ((playerNumber=0; playerNumber<$numPlayers; ++playerNumber)); do
                playerGuess $playerNumber $round $min $max
                gameRespond $playerNumber $number $min $max
                if (( $? != 0 )); then
                    winner=$playerNumber
                    break
                fi
            done

            if [[ "$winner" != "" ]]; then
                # End the game early.
                break
            elif (( round == roundsPerGame )); then
                # Ran out of turns.  Everyone loses.
                printf "game> Sorry, but no one guessed my number in %d rounds." $roundsPerGame
            fi
        done

        # Find the overall winner.
        highest_wins=0
        winner=0
        for ((i=0; i<${#types[@]}; ++i)); do
            if (( highest_wins < ${wins[$i]} )); then
                winner=$i
                highest_wins=${wins[$i]}
            fi
        done
        dramaticPrint "game> *** Game over. ***\n" 0 0 1.5
        dramaticPrint "game> The winner, with ${wins[$winner]} wins and ${losses[$winner]} defeats, is ${names[$winner]}!\n" 0.005 0 0
    done
}

main
