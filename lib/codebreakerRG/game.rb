module CodebreakerRG
  class Game
    DIFF_SETTINGS = { easy: {attempts: 20, code_length: 4, num_range: (1..6), hints: 1},
                      medium: {attempts: 15, code_length: 4, num_range: (1..6), hints: 1},
                      hard: {attempts: 10, code_length: 4, num_range: (0..9), hints: 1}}

    def initialize
      @state = :initialized
    end

    def start diff_level: :medium, user_settings: {}
      if user_settings.empty?
        settings = DIFF_SETTINGS[diff_level]
      else
        settings = user_settings
      end
      @user_settings = settings
      @attempts_left = settings[:attempts]
      @code_length = settings[:code_length]
      @num_range = settings[:num_range]
      @hints_left = settings[:hints]
      @hint = ''
      @secret_code = generate_code
      @state = :playing
    end

    def submit guess
      fail(RuntimeError, 'game not started') unless @state == :playing
      fail(RuntimeError, 'wrong guess length') unless guess.length == @code_length
      sec_code = String.new(@secret_code)
      guess_copy = String.new(guess)
      [plus_counts(sec_code, guess_copy), minus_counts(sec_code, guess_copy)]
    end

    def won?
      @state == :won
    end

    def lost?
      @state == :lost
    end

    def hint
      fail(RuntimeError, 'game not started') unless @state == :playing
      fail(RuntimeError, 'No more hints') if @hints_left == 0
      @hints_left -= 1
      @hint = @secret_code.chars.sample.to_s
      @hint
    end

    def play_again
      fail(RuntimeError, 'game not started yet') if @state == :initialized
      start user_settings: @user_settings
    end

    def statistic
      return {state: 'game not started yet'} if @state == :initialized
      {
        attempts_left: @attempts_left,
        code_length: @code_length,
        num_range: @num_range,
        hints_left: @hints_left,
        hint: @hint,
        secret_code: @state == :playing ? '*' * @code_length : @secret_code,
        state: if @state == :playing
                'playing game'
              elsif @state == :won
                'player win the game'
              elsif @state == :lost
                'player lost the game'
              elsif @state == :initialized
                'game not started yet'
              else
                ''
              end
      }
    end

    private

      def generate_code
        sec_code = ''
        @code_length.times{ sec_code << @num_range.to_a.sample.to_s}
        sec_code
      end

      def plus_counts sec_code, guess
        if @sec_code == guess
          @state = :won
          code_length
        else
          sec_code.chars.each_index do |i| 
            if sec_code[i] == guess[i] 
              sec_code[i] = '+'
              guess[i] = '+'
            end
          end
          plus_count = sec_code.count '+'
          sec_code.gsub! '+',''
          guess.sub! '+',''
          plus_count
        end
      end

      def minus_counts sec_code, guess
        sec_code.chars.each_index do |i| 
          ind = guess.index sec_code[i] 
          if ind
            sec_code[i] = '-'
            guess[ind] = '-'
          end
        end
        sec_code.count('-')
      end

  end
end