# frozen_string_literal: true

require 'rails_helper'

# Memverse#supermemo is the SM-2 spaced-repetition step behind every review.
RSpec.describe Memverse, 'spaced repetition' do
  let(:user) { FactoryBot.create(:user) }

  # The before_create hook resets efactor/next_test, so the starting state is
  # written after creation.
  def memverse_with(attrs)
    mv = FactoryBot.create(:memverse, user: user)
    mv.update_columns({ next_test: Date.today, last_tested: Date.today - 1, status: 'Learning', attempts: 0 }.merge(attrs))
    mv.reload
  end

  describe '#supermemo' do
    # q, starting [efactor, test_interval, rep_n] => expected [efactor, test_interval, rep_n, status]
    # The efactor column keeps one decimal place, so the stored efactor is the
    # SM-2 value rounded (1.86 -> 1.9); the interval is computed before rounding.
    [
      [5, [2.0, 1,  1], [2.1,  4,  2, 'Learning']],  # second repetition is always 4 days
      [4, [2.0, 4,  2], [2.0,  8,  3, 'Learning']],  # interval * efactor
      [3, [2.0, 16, 3], [1.9,  30, 4, 'Learning']],  # 16 * 1.86 = 29.76 rounds to 30: not yet memorized
      [5, [2.0, 16, 3], [2.1,  34, 4, 'Memorized']], # crosses the 30-day threshold
      [2, [2.0, 20, 4], [1.7,  1,  1, 'Learning']],  # a failed recall restarts the sequence
      [1, [2.0, 20, 4], [1.5,  1,  1, 'Learning']],
      [0, [1.4, 20, 4], [1.3,  1,  1, 'Learning']]   # efactor never drops below 1.3
    ].each do |q, (efactor, interval, rep_n), (new_efactor, new_interval, new_rep_n, new_status)|
      context "with q=#{q} from efactor #{efactor}, interval #{interval}, rep #{rep_n}" do
        let(:mv) { memverse_with(efactor: efactor, test_interval: interval, rep_n: rep_n) }

        before { mv.supermemo(q) }

        it "moves to interval #{new_interval}, efactor #{new_efactor}, rep #{new_rep_n}, #{new_status}" do
          mv.reload
          expect(mv.test_interval).to eq(new_interval)
          expect(mv.efactor).to be_within(0.001).of(new_efactor)
          expect(mv.rep_n).to eq(new_rep_n)
          expect(mv.status).to eq(new_status)
        end

        it 'schedules the next test that many days out and records the attempt' do
          mv.reload
          expect(mv.next_test).to eq(Date.today + new_interval)
          expect(mv.last_tested).to eq(Date.today)
          expect(mv.attempts).to eq(1)
        end
      end
    end

    it 'caps the efactor at 2.5' do
      mv = memverse_with(efactor: 2.5, test_interval: 4, rep_n: 2)
      mv.supermemo(5)
      expect(mv.reload.efactor).to eq(2.5)
    end

    it "never schedules further out than the user's max_interval" do
      user.update_columns(max_interval: 10)
      mv = memverse_with(efactor: 2.0, test_interval: 16, rep_n: 3)
      mv.supermemo(5)
      expect(mv.reload.test_interval).to eq(10)
      expect(mv.next_test).to eq(Date.today + 10)
    end

    it 'returns true only when the verse has just become memorized' do
      learning  = memverse_with(efactor: 2.0, test_interval: 16, rep_n: 3)
      memorized = memverse_with(efactor: 2.0, test_interval: 40, rep_n: 5, status: 'Memorized')

      expect(learning.supermemo(5)).to be(true)
      expect(learning.supermemo(5)).to be(false)
      expect(memorized.supermemo(5)).to be(false)
    end

    it 'demotes a memorized verse back to learning when recall fails' do
      mv = memverse_with(efactor: 2.0, test_interval: 40, rep_n: 5, status: 'Memorized')
      mv.supermemo(1)
      expect(mv.reload.status).to eq('Learning')
      expect(mv.test_interval).to eq(1)
    end

    it 'leaves the schedule alone for a verse that is not yet due' do
      mv = memverse_with(efactor: 2.0, test_interval: 8, rep_n: 3, next_test: Date.tomorrow)
      mv.supermemo(5)
      mv.reload
      expect([mv.test_interval, mv.rep_n, mv.efactor]).to eq([8, 3, 2.0])
      expect(mv.attempts).to eq(1)
    end
  end

  describe '#due?' do
    it 'is due on or before today and not after' do
      expect(memverse_with(next_test: Date.today)).to be_due
      expect(memverse_with(next_test: Date.yesterday)).to be_due
      expect(memverse_with(next_test: Date.tomorrow)).not_to be_due
    end
  end

  describe '#memorized?' do
    it 'reflects the status column' do
      expect(memverse_with(status: 'Memorized')).to be_memorized
      expect(memverse_with(status: 'Learning')).not_to be_memorized
    end
  end

  describe '#toggle_status' do
    it 'parks an active verse as Pending' do
      mv = memverse_with(status: 'Learning')
      expect(mv.toggle_status).to eq('Pending')
      expect(mv.reload.status).to eq('Pending')
    end

    it 'reactivates a pending verse as Learning or Memorized based on its interval' do
      short = memverse_with(status: 'Pending', test_interval: 30)
      long  = memverse_with(status: 'Pending', test_interval: 31)
      expect(short.toggle_status).to eq('Learning')
      expect(long.toggle_status).to eq('Memorized')
    end
  end
end
