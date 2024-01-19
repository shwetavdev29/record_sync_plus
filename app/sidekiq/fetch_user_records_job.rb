class FetchUserRecordsJob
  include Sidekiq::Job
  require 'net/http'

  def perform
    response = fetch_user_data
    response = JSON.parse(response.body)['results']
    users_data = distinct_users_data(response)

    response.each do |user_data|
      update_or_create_user(user_data)
    end

    store_gender_counts(users_data)
  end

  private

  def fetch_user_data
    uri = URI('https://randomuser.me/api/?results=20')
    Net::HTTP.get_response(uri)
  end

  def update_or_create_user(user_data)
    user = User.find_or_initialize_by(uuid: user_data['login']['uuid'])
    user.update(user_params(user_data))
  end

  def store_gender_counts(users_data)
    previous_data = Redis.current.get('daily_counts')

    Redis.current.set('daily_counts', compute_hourly_data(previous_data:, users_data:))
  end

  def compute_hourly_data(previous_data: nil, users_data: nil)
    male_count = users_data.count { |user| user['gender'] == 'male' }
    female_count = users_data.count { |user| user['gender'] == 'female' }
    recording_time = DateTime.now.strftime('%T')

    current_data = previous_data.present? ? JSON.parse(previous_data) : []

    current_data.push({ recording_time:, male_count:, female_count: })
    current_data.to_json
  end

  def user_params(user_data)
    {
      gender: user_data['gender'],
      name: user_data['name'],
      location: user_data['location'],
      age: user_data['dob']['age']
    }
  end

  def distinct_users_data(response)
    all_uuids = response.pluck("login").pluck("uuid")
    existing_uuids = User.where(uuid: all_uuids).pluck(:uuid)
    distinct_uuids = all_uuids - existing_uuids
    response.select { |user| distinct_uuids.include?(user.dig('login', 'uuid'))}
  end
end
