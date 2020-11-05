module SAFE
  class Configuration
    attr_accessor :concurrency, :namespace, :redis_url, :ttl, :job_delay,
      :silent_fail, :error_monitor, :monitor_callback

    def self.from_json(json)
      new(SAFE::JSON.decode(json, symbolize_keys: true))
    end

    def initialize(hash = {})
      self.concurrency      = hash.fetch(:concurrency, 5)
      self.namespace        = hash.fetch(:namespace, 'safe')
      self.redis_url        = hash.fetch(:redis_url, 'redis://localhost:6379')
      self.safefile         = hash.fetch(:safefile, 'Safefile')
      self.ttl              = hash.fetch(:ttl, -1)
      self.job_delay        = hash.fetch(:job_delay, 0)
      self.silent_fail      = hash.fetch(:silent_fail, false)
      self.error_monitor    = hash.fetch(:error_monitor, false)
      self.monitor_callback = hash.fetch(:monitor_callback, false)
    end

    def safefile=(path)
      @safefile = Pathname(path)
    end

    def safefile
      @safefile.realpath if @safefile.exist?
    end

    def to_hash
      {
        concurrency: concurrency,
        namespace:   namespace,
        redis_url:   redis_url,
        ttl:         ttl,
        job_delay:   job_delay
      }
    end

    def to_json
      SAFE::JSON.encode(to_hash)
    end
  end
end
