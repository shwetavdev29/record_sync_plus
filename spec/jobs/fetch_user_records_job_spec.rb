require 'rails_helper'

RSpec.describe FetchUserRecordsJob, type: :job do
  describe '#perform' do
    let(:job) { FetchUserRecordsJob.new }

    it 'fetches user data and processes it' do
      allow(Net::HTTP).to receive(:get_response).and_return(double('response', body: '{"results": []}'))

      expect(job).to receive(:distinct_users_data).and_call_original
      expect(job).to receive(:update_or_create_user).exactly(0).times
      expect(job).to receive(:store_gender_counts).and_call_original

      job.perform
    end
  end

  describe '#compute_hourly_data' do
    let(:job) { FetchUserRecordsJob.new }

    it 'computes hourly data correctly' do
      previous_data = '[{"recording_time":"12:00:00","male_count":5,"female_count":3}]'
      users_data = [
        { 'gender' => 'male' },
        { 'gender' => 'female' },
        { 'gender' => 'male' },
        # Add more users as needed
      ]

      result = job.send(:compute_hourly_data, previous_data: previous_data, users_data: users_data)
      expected_result = '[{"recording_time":"12:00:00","male_count":5,"female_count":3}, {"recording_time":"' +
                        DateTime.now.strftime('%T') + '","male_count":2,"female_count":1}]'

      # Parse and serialize both strings to normalize spacing
      parsed_result = JSON.parse(result)
      parsed_expected_result = JSON.parse(expected_result)

      expect(parsed_result).to eq(parsed_expected_result)
    end
  end
end
