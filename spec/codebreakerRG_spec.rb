require 'spec_helper'

module CodebreakerRG
  
  describe CodebreakerRG do
    it 'has a version number' do
      expect(CodebreakerRG::VERSION).not_to be nil
    end

    xit 'does something useful' do
      expect(false).to eq(true)
    end
  end

  describe Game do
    let(:game) { Game.new }
    context "#new" do
      it 'set status to initialized' do
        expect(game.instance_variable_get(:@state)).to eq :initialized
      end
    end

    context "#start" do
      let(:settings) { Game::DIFF_SETTINGS[:medium] }

      before do
        game.start
      end

      it 'generates secret code' do
        expect(game.instance_variable_get(:@secret_code)).not_to be_empty
      end

      it 'used generator secret code' do
        expect(game).to receive(:generate_code)
        game.start
      end

      it 'set settings' do
        expect(game.instance_variable_get(:@user_settings)).to eq settings
      end

      it 'set attempts' do
        expect(game.instance_variable_get(:@attempts_left)).to eq settings[:attempts]
      end

      it 'set code_length' do
        expect(game.instance_variable_get(:@code_length)).to eq settings[:code_length]
      end
      
      it 'set num_range' do
        expect(game.instance_variable_get(:@num_range)).to eq settings[:num_range]
      end
      
      it 'set hints_left' do
        expect(game.instance_variable_get(:@hints_left)).to eq settings[:hints]
      end
      
      it 'set state playing' do
        expect(game.instance_variable_get(:@state)).to eq :playing
      end
    end

    context '#generate_code' do
      # let(:game) { Game.new }

      before do
        game.instance_variable_set(:@code_length, 4)
        game.instance_variable_set(:@num_range,(1..6))
        @sec_code = game.send :generate_code
      end

      it 'generates secret code' do
        expect(@sec_code).not_to be_empty
      end
      it 'save 4 numbers secret code' do
        expect(@sec_code).to have(4).items
      end
      it 'save secret code with numbers from 1 to 6' do
        expect(@sec_code).to match(/[1-6]+/)
      end
    end

    context '#submit' do
      { '1224' =>   {'1234' => [3,0], '1111' => [1,0],
                        '6522' => [1,1], '3232' => [1,1],
                        '4321' => [1,2], '5234' => [2,0]},
        '4566' =>   {'1234' => [0,1], '1111' => [0,0],
                        '6522' => [1,1], '4446' => [2,0],
                        '4566' => [4,0], '5466' => [2,2]},
        '1112' =>   {'1234' => [1,1], '1111' => [3,0],
                        '6522' => [1,0], '1223' => [1,1],
                        '1121' => [2,2], '5234' => [0,1]} }.each do |sec_code, tests|
        context "secret code is #{sec_code}" do
          before do
            game.instance_variable_set(:@state, :playing)
            game.instance_variable_set(:@secret_code, sec_code)
            game.instance_variable_set(:@code_length, 4)
          end

          tests.each do |k, v|
            it "when #{k} returns #{v}" do
              expect(game.submit(k)).to eq(v)
            end
          end
        end
      end

      [:initialized, :won, :lost].each do |state|
        it "got expection with #{state}" do
          game.instance_variable_set(:@state, state)
          expect{game.submit '1234'}.to raise_error RuntimeError, 'game not started'
        end
      end

      it 'expection if guess length not equal to code_length' do 
        game.instance_variable_set(:@state, :playing)
        game.instance_variable_set(:@code_length, 4)
        expect{game.submit '123'}.to raise_error RuntimeError, 'wrong guess length'
      end

      it 'won game'
      it 'lost game'

    end

    describe 'status methods' do
      context '#lost?' do
        it 'return true if lost' do
          game.instance_variable_set(:@state, :lost)
          expect(game).to be_lost
        end
        it 'return false if won' do
          game.instance_variable_set(:@state, :won)
          expect(game).not_to be_lost
        end
        it 'return false if playing' do
          game.instance_variable_set(:@state, :playing)
          expect(game).not_to be_lost
        end
      end
      context '#won?' do
        it 'return false if lost' do
          game.instance_variable_set(:@state, :lost)
          expect(game).not_to be_won
        end
        it 'return true if won' do
          game.instance_variable_set(:@state, :won)
          expect(game).to be_won
        end
        it 'return false if playing' do
          game.instance_variable_set(:@state, :playing)
          expect(game).not_to be_won
        end
      end
    end

    context '#play_again' do
      let(:settings) { Game::DIFF_SETTINGS[:medium] }

      it 'used start game' do
        game.instance_variable_set(:@user_settings, settings)
        game.instance_variable_set(:@state, :playing)
        expect(game).to receive(:start).with({:user_settings=>settings})
        game.play_again
      end

      [:playing, :won, :lost].each do |state|
        it "got no expection with #{state}" do
          game.instance_variable_set(:@state, state)
          game.instance_variable_set(:@user_settings, settings)
          expect{game.play_again}.not_to raise_error
        end
      end

      it "got expection with initialized" do
        game.instance_variable_set(:@state, :initialized)
        # game.instance_variable_set(:@user_settings, settings)
        expect{game.play_again}.to raise_error RuntimeError, 'game not started'
      end
    end

    context '#hint' do
      before do
        game.instance_variable_set(:@state, :playing)
        game.instance_variable_set(:@secret_code, '1234')
        game.instance_variable_set(:@hints_left, 1)
      end
      it 'got hint' do
        expect(game.hint).not_to be_empty
      end  
      it 'sec_code include hint' do
        expect('1234').to be_include game.hint
      end
      it 'decrement hint_left' do
        expect{game.hint}.to change{game.instance_variable_get(:@hints_left)}.by(-1)
      end
      it 'no more hints' do
        game.instance_variable_set(:@hints_left, 0)
        expect{game.hint}.to raise_error RuntimeError
      end
      it 'game not playing' do
        game.instance_variable_set(:@state, :initialized)
        expect{game.hint}.to raise_error RuntimeError
      end
    end

    context '#statistic' do
      [:playing, :won, :lost].each do |state|
        it "got statistic with #{state}" do
          game.instance_variable_set(:@code_length, 4)
          game.instance_variable_set(:@state, state)
          expect(game.statistic).not_to be_empty
        end
      end
      it 'empty statistic with initialized' do
        game.instance_variable_set(:@state, :initialized)
        expect(game.statistic).to eq({state: 'game not started yet'})
      end
      it "got secret code in statistic with playing" do
        game.instance_variable_set(:@code_length, 4)
        game.instance_variable_set(:@secret_code, '1234')
        game.instance_variable_set(:@state, :playing)
        expect(game.statistic[:secret_code]).to eq '****'
      end
      [:won, :lost].each do |state|
        it "got statistic with #{state}" do
          game.instance_variable_set(:@code_length, 4)
          game.instance_variable_set(:@secret_code, '1234')
          game.instance_variable_set(:@state, state)
          expect(game.statistic[:secret_code]).to eq '1234'
        end
      end

    end

    context '#save_score' do

    end
  end
end
