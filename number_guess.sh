#!/bin/bash

# PSQL variable for querying the database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Function to handle user input and guessing
function start_game() {
  # Generate a random secret number between 1 and 1000
  SECRET_NUMBER=$((RANDOM % 1000 + 1))
  NUMBER_OF_GUESSES=0

  echo "Guess the secret number between 1 and 1000:"

  while true; do
    read GUESS

    # Check if input is an integer
    if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
      echo "That is not an integer, guess again:"
      continue
    fi

    NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))

    if [[ $GUESS -lt $SECRET_NUMBER ]]; then
      echo "It's higher than that, guess again:"
    elif [[ $GUESS -gt $SECRET_NUMBER ]]; then
      echo "It's lower than that, guess again:"
    else
      # User guessed correctly
      echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
      # Update user statistics in the database
      update_user_stats "$USERNAME" "$NUMBER_OF_GUESSES"
      break
    fi
  done
}

# Function to update user statistics
function update_user_stats() {
  local USERNAME=$1
  local NUMBER_OF_GUESSES=$2
  
  # Get current stats for the user
  USER_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username = '$USERNAME'")
  IFS="|" read GAMES_PLAYED BEST_GAME <<< "$USER_DATA"

  # Increment the games played
  GAMES_PLAYED=$((GAMES_PLAYED + 1))
  
  # Determine if the current game is the best
  if [[ -z $BEST_GAME || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]; then
    BEST_GAME=$NUMBER_OF_GUESSES
  fi
  
  # Update the database with the new statistics
  $PSQL "UPDATE users SET games_played = $GAMES_PLAYED, best_game = $BEST_GAME WHERE username = '$USERNAME';"
}

# Prompt for username
echo "Enter your username:"
read USERNAME

# Check if the username exists in the database
USER_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE username = '$USERNAME'")

if [[ -z $USER_DATA ]]; then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  
  # Insert new user into the database
  INSERT_RESULT=$($PSQL "INSERT INTO users (username) VALUES ('$USERNAME')")
  
  # Start the game
  start_game
else
  # Existing user
  IFS="|" read GAMES_PLAYED BEST_GAME <<< "$USER_DATA"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  
  # Start the game
  start_game
fi
