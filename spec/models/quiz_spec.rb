require 'rails_helper'

RSpec.describe Quiz, type: :model do
  describe '.knowledge_quiz_schedule' do
    it 'returns an array of schedule data with UTC times' do
      schedule = Quiz.knowledge_quiz_schedule

      expect(schedule).to be_an(Array)
      expect(schedule.length).to eq(2)

      # Check format is a hash with day and utc_time
      schedule.each do |schedule_item|
        expect(schedule_item).to be_a(Hash)
        expect(schedule_item).to have_key(:day)
        expect(schedule_item).to have_key(:utc_time)
        expect(schedule_item[:utc_time]).to match(/^\d{2}:\d{2}$/)
      end
    end

    it 'includes Tuesday and Saturday in the schedule' do
      schedule = Quiz.knowledge_quiz_schedule

      expect(schedule.any? { |s| s[:day] == 'Tuesday' }).to be true
      expect(schedule.any? { |s| s[:day] == 'Saturday' }).to be true

      # Check the UTC times are correct
      tuesday_schedule = schedule.find { |s| s[:day] == 'Tuesday' }
      saturday_schedule = schedule.find { |s| s[:day] == 'Saturday' }

      expect(tuesday_schedule[:utc_time]).to eq('17:00')
      expect(saturday_schedule[:utc_time]).to eq('23:00')
    end
  end
  
  describe '.next_knowledge_quiz_time' do
    it 'returns a Time object' do
      next_time = Quiz.next_knowledge_quiz_time
      
      expect(next_time).to be_a(Time)
    end
    
    it 'returns a future time' do
      next_time = Quiz.next_knowledge_quiz_time
      
      expect(next_time).to be > Time.current
    end
    
    it 'returns either Tuesday at 17:00 UTC or Saturday at 23:00 UTC' do
      next_time = Quiz.next_knowledge_quiz_time
      
      valid_times = [
        { wday: 2, hour: 17 }, # Tuesday at 17:00 UTC
        { wday: 6, hour: 23 }  # Saturday at 23:00 UTC
      ]
      
      time_match = valid_times.any? do |valid|
        next_time.wday == valid[:wday] && next_time.hour == valid[:hour]
      end
      
      expect(time_match).to be true
    end
  end
end