require 'spec_helper'

describe SAFE::Configuration do

  it "has defaults set" do
    subject.safefile = SAFEFILE
    expect(subject.redis_url).to eq("redis://localhost:6379")
    expect(subject.concurrency).to eq(5)
    expect(subject.namespace).to eq('safe')
    expect(subject.safefile).to eq(SAFEFILE.realpath)
  end

  describe "#configure" do
    it "allows setting options through a block" do
      SAFE.configure do |config|
        config.redis_url = "redis://localhost"
        config.concurrency = 25
        config.job_delay   = 3
      end

      expect(SAFE.configuration.redis_url).to eq("redis://localhost")
      expect(SAFE.configuration.concurrency).to eq(25)
      expect(SAFE.configuration.job_delay).to eq(3)
    end
  end
end
