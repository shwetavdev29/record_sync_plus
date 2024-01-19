require "rails_helper"
require "fugit"

RSpec.describe "sidekiq-scheduler" do
  sidekiq_file = File.join(Rails.root, "config", "sidekiq.yml")
  schedule = YAML.load_file(sidekiq_file)

  describe "cron syntax" do
    schedule.each do |k, v|
      cron = v["cron"]
      it "#{k} has correct cron syntax" do
        expect { Fugit.do_parse(cron) }.not_to raise_error
      end
    end
  end

  describe "job classes" do
    schedule.each do |k, v|
      klass = v["class"]
      it "#{k} has #{klass} class in /jobs" do
        expect { klass.constantize }.not_to raise_error
      end
    end
  end

  describe "job names" do
    schedule.each do |k, v|
      klass = v["class"]
      it "#{k} has correct name" do
        expect(k).to eq(klass.underscore)
      end
    end
  end
end
