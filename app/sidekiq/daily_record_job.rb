class DailyRecordJob
  include Sidekiq::Job

  def perform
    tabulate_and_store_totals
  end

  private

  def tabulate_and_store_totals
    redis = Redis.current
    daily_counts = JSON.parse(redis.get('daily_counts'))
    total_male = daily_counts.inject(0) { |sum, entry| sum + entry['male_count']}
    total_female = daily_counts.inject(0) { |sum, entry| sum + entry['female_count']}

    daily_record = DailyRecord.find_or_initialize_by(date: Date.current)
    daily_record.male_count = total_male
    daily_record.female_count = total_female

    users = User.where(created_at: Date.today.all_day)
    daily_record.male_avg_age = calculate_average_age(users.where(gender: 'male'))
    daily_record.female_avg_age = calculate_average_age(users.where(gender: 'female'))
    daily_record.save if daily_record.changed?
  end

  def calculate_average_age(users)
    total_age = users.sum(&:age)
    users_count = users.count
    users_count.zero? ? 0 : total_age.to_f / users_count
  end
end
