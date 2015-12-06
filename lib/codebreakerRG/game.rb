module CodebreakerRG
  class Game
    DIFF_SETTINGS = { easy: {attempts: 20, code_length: 4, num_range: (1..6), hints: 1},
                      medium: {attempts: 15, code_length: 4, num_range: (1..6), hints: 1},
                      hard: {attempts: 10, code_length: 4, num_range: (0..9), hints: 1}}

    def initialize
      @state = :initialized
      @statistics = []
    end

    def start diff_level: :medium, user_settings: {}
      if user_settings.empty?
        settings = DIFF_SETTINGS[diff_level]
        @settings = diff_level
        @user_settings = {}
      else
        settings = user_settings
        @settings = :user_settings
        @user_settings = settings
      end
      @attempts_left = settings[:attempts]
      @code_length = settings[:code_length]
      @num_range = settings[:num_range]
      @hints_left = settings[:hints]
      @hint = ''
      @score = 0
      @secret_code = generate_code
      @state = :playing
      collect_statistics first: true
    end

    def submit guess
      fail(RuntimeError, 'game not started') unless @state == :playing
      fail(RuntimeError, 'wrong guess length') unless guess.length == @code_length
      sec_code = String.new(@secret_code)
      guess_copy = String.new(guess)
      answer = [plus_counts(sec_code, guess_copy), minus_counts(sec_code, guess_copy)]
      check_lost
      collect_statistics curr_submit: [guess, answer]
      answer
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
      collect_statistics
      @hint
    end

    def play_again
      fail(RuntimeError, 'game not started yet') if @state == :initialized
      if @settings == :user_settings
        start user_settings: @user_settings
      else
        start diff_level: @settings
      end
    end

    def statistics all_stats: false
      return {state: 'game not started yet'} if @state == :initialized
      if all_stats
        ret_stats = @statistics
      else
        ret_stats = [@statistics.last]
      end
      ret_stats.inject([]) do |res, el|
        if el[:settings] == :user_settings
          settings = el[:user_settings]
        else
          settings = DIFF_SETTINGS[el[:settings]]
        end
        res <<  {
                  attempts_left: el[:attempts_left],
                  code_length: settings[:code_length],
                  num_range: settings[:num_range],
                  user_settings: el[:user_settings],
                  hints_left: el[:hints_left],
                  hint: el[:hint],
                  secret_code: el[:state] == :playing ? '*' * settings[:code_length] : el[:secret_code],
                  state: if el[:state] == :playing
                          'playing game'
                        elsif el[:state] == :won
                          'player win the game'
                        elsif el[:state] == :lost
                          'player lost the game'
                        elsif el[:state] == :initialized
                          'game not started yet'
                        else
                          ''
                        end
                }
      end
      # {
      #   attempts_left: @attempts_left,
      #   code_length: @code_length,
      #   num_range: @num_range,
      #   hints_left: @hints_left,
      #   hint: @hint,
      #   secret_code: @state == :playing ? '*' * @code_length : @secret_code,
      #   state: if @state == :playing
      #           'playing game'
      #         elsif @state == :won
      #           'player win the game'
      #         elsif @state == :lost
      #           'player lost the game'
      #         elsif @state == :initialized
      #           'game not started yet'
      #         else
      #           ''
      #         end
      # }
    end

    def collect_statistics first: false, curr_submit: []
      return {state: 'game not started yet'} if @state == :initialized
      if first
        curr_stat = {submits: []}
      else 
        curr_stat = @statistics.last
      end
      temp_hash = {
                    attempts_left: @attempts_left,
                    settings: @settings,
                    user_settings: @user_settings,
                    hints_left: @hints_left,
                    hint: @hint,
                    secret_code: @secret_code,
                    state: @state,
                    score: @score
                  }
      curr_stat.merge temp_hash
      curr_stat[:submits] << curr_submit unless curr_submit.empty?
    end

    private

      def generate_code
        sec_code = ''
        @code_length.times{ sec_code << @num_range.to_a.sample.to_s}
        sec_code
      end

      def plus_counts sec_code, guess
        if @sec_code == guess
          game_win
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

      def game_win
        @state = :won
        @score = 100
      end

      def check_lost
        if !game_win && @attempts_left == 0
          state = :lost 
          @score = 0
        end
      end

  end
end