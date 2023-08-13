# frozen_string_literal: true

# Mastermind game logic
class DecodingBoard
  attr_reader :state, :guesses, :max_guesses

  def self.random_code
    Array.new(4) { rand(1..6) }
  end

  def self.validate_code(code)
    if !code.is_a?(Array)
      raise 'expected an array'
    elsif code.size != 4
      raise "expected an array of 4 elements, got: #{code.size}"
    elsif code.any? { |e| !e.is_a?(Integer) }
      raise 'found type other than Integer in code array'
    elsif code.any? { |e| !e.between?(1, 6) }
      raise 'found out of range number in code array'
    end
  end

  def initialize(code, max_guesses)
    DecodingBoard.validate_code(code)
    @code = code
    @guesses = 0
    @max_guesses = max_guesses
    @state = 'playing'
    @history = []
  end

  def try_guess(guess)
    DecodingBoard.validate_code(guess)
    result = decode(guess)

    @guesses += 1
    @history << { guess: guess.dup.freeze, result: result.dup }.freeze

    if result == '****'
      @state = 'decoded'
    elsif @guesses >= @max_guesses
      @state = 'failed'
    end

    result
  end

  # Returns duplicated array of frozen hashes
  def history
    @history.dup
  end

  private

  def decode(guess)
    guess = guess.dup
    code = @code.dup

    strong_guesses = decode_strong(guess, code)
    weak_guesses = decode_weak(guess, code)

    '*' * strong_guesses + '.' * weak_guesses
  end

  # Counts correct guesses (position and code), modifies guess and code arrays
  def decode_strong(guess, code)
    guess.each_with_index.reduce(0) do |count, (code_peg, index)|
      if code_peg && code[index] == code_peg
        count += 1
        code[index] = nil
        guess[index] = nil
      end
      count
    end
  end

  # Counts correct guesses (code but not position), modifies guess and code arrays
  def decode_weak(guess, code)
    guess.compact.each.reduce(0) do |count, code_peg|
      index = code.find_index(code_peg)
      if index
        count += 1
        code[index] = nil
      end
      count
    end
  end
end

# Abstract class for player
class Player
  def create_code
    DecodingBoard.random_code
  end

  def decode(_board, _guesses_left)
    DecodingBoard.random_code
  end
end

# Console player (ask user for code and show board history to them)
class HumanPlayer < Player
  def self.ask_for_code
    input = ''
    loop do
      write 'Please enter a code of 4 digits from 1 to 6:'
      print '> '
      input = gets.match(/[1-6]{4}/).to_s

      break unless input == ''

      write 'Invalid input! Valid input could be: "1234"'
    end

    input.split('').map(&:to_i)
  end

  def create_code
    write "It's Your turn to create a secret code!"
    HumanPlayer.ask_for_code
  end

  def decode(board, guesses_left)
    write "This is Your #{board.size + 1} try. You have #{guesses_left} guesses left."

    HumanPlayer.ask_for_code
  end
end

# Computer player (generate code based on guess history)
class ComputerPlayer < Player
  def decode(board, guesses_left)
    # TODO: Super complicated decoding algorithm
    write 'Waiting for computer to generate a code...'
    sleep(1.5)
    super
  end
end

def ask(question, *choices)
  write question
  sleep(1)
  choices.each_with_index { |choice, index| write "#{index + 1}) #{choice}" }
  input = 0
  until input.between?(1, choices.size)
    print '> '
    input = gets.to_i
  end
  input
end

def print_board(board, guesses_left, offset = 4)
  # code_map = [' ', 'a', 'b', 'c', 'd', 'e', 'f']
  code_map = ['  ', '🐈', '🦄', '🐼', '🦆', '🐬', '🦀']

  # Print codemap
  print "Code map is: #{(1..6).each.map { |i| "#{i}: #{code_map[i]}  " }.join}\n"

  off = "\t" * offset
  puts "#{off}   M ^ S T E R M I N D"
  puts "#{off} ...-----=======-----..."
  puts
  board.each_with_index do |entry, index|
    guess = entry[:guess]
    result = entry[:result]
    puts "#{off} #{(index + 1).to_s.rjust(2)} | " \
      "#{guess.map { |code| code_map[code] }.join(' ')} | #{result.ljust(4)} |"
    sleep(0.05)
  end
  (0..guesses_left - 1).each do |index|
    puts "#{off} #{(index + 1 + board.size).to_s.rjust(2)} | #{Array.new(4, code_map[0]).join(' ')} |      |"
    sleep(0.05)
  end
end

def play_game(code_maker, code_guesser, max_guesses = 12)
  # Code maker creates a code
  real_code = code_maker.create_code
  board = DecodingBoard.new(real_code, max_guesses)

  # Code guesser tries to guess a code
  while board.state == 'playing'
    board_history = board.history
    guesses_left = board.max_guesses - board.guesses

    print_board(board_history, guesses_left)

    guess_code = code_guesser.decode(board_history, guesses_left)
    board.try_guess(guess_code)
  end

  write 'Game ended. This is how board looks like:'
  print_board(board.history, 0)
  write "The code was: \"#{real_code}\""
  board.state
end

def write(msg, char_time = 0.03)
  msg.split('').each do |character|
    print character
    sleep(char_time)
  end
  puts
end

write 'Welcome to MASTERMIND game!'
sleep 1
write 'Rules: First player creates a code and second player tries to guess ' \
  'it in 12 tries.'
sleep 1

choice = ask('Do you want to play against computer or against your friend?',
             'Play against computer', 'Play against friend')

if choice == 1
  write 'Ok, starting a game "Human vs Computer"...'
  sleep(1)
  choice = ask('Do you want to create code or to guess it?',
               'Create code', 'Guess code')
  if choice == 1
    result = play_game(HumanPlayer.new, ComputerPlayer.new)
    if result == 'decoded'
      write 'Computer decoded your code successfully! Try to make more advanced code next time!'
    elsif result == 'failed'
      write 'Computer did not decoded your code!'
    end
  elsif choice == 2
    play_game(ComputerPlayer.new, HumanPlayer.new)
  end
elsif choice == 2
  write 'Ok, starting a game "Human vs Human"...'
  play_game(HumanPlayer.new, HumanPlayer.new)
end

write 'Thanks for playing! :)'
