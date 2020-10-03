# frozen_string_literal: true

# Mastermind game logic
class DecodingBoard
  attr_reader :state
  attr_reader :guesses
  attr_reader :max_guesses

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
    @history << { guess: guess.dup.freeze, result: result.clone }

    if result == '****'
      @state = 'decoded'
    elsif @guesses >= @max_guesses
      @state = 'failed'
    end

    result
  end

  # return duplicated array of hashes
  def history
    @history.map do |entry|
      { guess: entry[:guess].dup, result: entry[:result].dup }
    end
  end

  private

  def decode(guess)
    strong_guesses = []
    weak_guesses = []

    guess.each_with_index do |code_peg, index|
      if @code[index] == code_peg
        strong_guesses << '*'
      elsif @code.include?(code_peg)
        weak_guesses << '.'
      end
    end

    (strong_guesses + weak_guesses).join
  end
end

# Abstract class for player
class Player
  def create_code
    DecodingBoard.random_code
  end

  def decode(board)
    DecodingBoard.random_code
  end
end

# Console player (ask user for code and show board history to them)
class HumanPlayer < Player
  def create_code
    # TODO: Ask User to create a code
  end

  def decode(board)
    # TODO: Ask User to guess a code
    puts 'Board history:'
    p board
    gets
    super
  end
end

# Computer player (generate code based on guess history)
class ComputerPlayer < Player
  def decode(board)
    # Super complicated decoding algorithm
  end
end

def play_game(code_maker, code_guesser, max_guesses)
  # Code maker creates a code
  real_code = code_maker.create_code
  board = DecodingBoard.new(real_code, max_guesses)

  # Code guesser tries to guess a code
  while board.state == 'playing'
    guess_code = code_guesser.decode(board.history)
    result = board.try_guess(guess_code)
  end
end

play_game(Player.new, HumanPlayer.new, 12)
