require 'rails_helper'

RSpec.describe DailyRecordJob, type: :job do
  describe '#perform' do
    it 'calls tabulate_and_store_totals' do
      allow_any_instance_of(DailyRecordJob).to receive(:tabulate_and_store_totals)
    end
  end

  describe '#tabulate_and_store_totals' do
    let(:redis_double) { instance_double(Redis, get: '[{ "recording_time": "' + DateTime.now.strftime('%T') + '", "male_count": 10, "female_count": 10 }]') }
    let(:users_relation) { instance_double(ActiveRecord::Relation) }
    let(:daily_record_instance) { instance_double(DailyRecord, save: true, changed?: true) }

    before do
      allow(Redis).to receive(:new).and_return(redis_double)
      allow(User).to receive(:where).with(created_at: Date.today.all_day).and_return(users_relation)
      allow(daily_record_instance).to receive(:male_count=)
      allow(daily_record_instance).to receive(:female_count=)
      allow(daily_record_instance).to receive(:male_avg_age=)
      allow(daily_record_instance).to receive(:female_avg_age=)
      allow(users_relation).to receive(:where).with(gender: 'male').and_return(users_relation)
      allow(users_relation).to receive(:where).with(gender: 'female').and_return(users_relation)
      allow(users_relation).to receive(:count).and_return(10)
      allow(users_relation).to receive(:sum).and_return(20)
      allow(DailyRecord).to receive(:find_or_initialize_by).and_return(daily_record_instance)
      allow(Redis).to receive(:current).and_return(redis_double)
    end

    it 'updates DailyRecord and Redis with correct values' do
      DailyRecordJob.new.send(:tabulate_and_store_totals)

      expect(DailyRecord).to have_received(:find_or_initialize_by).with(date: Date.current)
      expect(daily_record_instance).to have_received(:male_count=).with(10)
      expect(daily_record_instance).to have_received(:female_count=).with(10)
      expect(daily_record_instance).to have_received(:save)
    end
  end
end
