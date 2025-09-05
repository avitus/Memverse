require 'rails_helper'

RSpec.describe Quiz, type: :model do
  describe '.knowledge_quiz_schedule' do
    it 'returns an array of schedule times in Pacific timezone' do
      schedule = Quiz.knowledge_quiz_schedule
      
      expect(schedule).to be_an(Array)
      expect(schedule.length).to eq(2)
      
      # Check format includes day and time
      schedule.each do |time_str|
        expect(time_str).to match(/^(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)s at \d{1,2}(am|pm) \(P[SD]T\)$/)
      end
    end
    
    it 'includes Tuesday and Saturday in the schedule' do
      schedule = Quiz.knowledge_quiz_schedule
      
      expect(schedule.any? { |s| s.include?('Tuesday') }).to be true
      expect(schedule.any? { |s| s.include?('Saturday') }).to be true
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