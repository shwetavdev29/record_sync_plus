class User < ApplicationRecord
  after_destroy :update_daily_record

  def self.ransackable_attributes(auth_object = nil)
    ["age", "created_at", "gender", "id", "location", "name", "updated_at", "uuid"]
  end

  private

  def update_daily_record
    count_column = "#{gender}_count"
    if created_at < DateTime.now
      daily_record = DailyRecord.find_by(date: created_at)
      count = daily_record.send(count_column)
      daily_record.update(count_column => count-1)
    else
      daily_counts = JSON.parse(Redis.current.get('daily_counts'))
      count = daily_counts.last[count_column]
      daily_counts.last[count_column] = count - 1
      Redis.current.set('daily_counts', JSON.dump(daily_counts))
    end
  end
end
