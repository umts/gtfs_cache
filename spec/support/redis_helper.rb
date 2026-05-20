module RedisHelper
  extend ActiveSupport::Concern

  global_mock_redis = MockRedis.new

  included do
    let(:redis) { Redis::Namespace.new(:gtfs_cache, redis: global_mock_redis) }

    before do
      global_mock_redis.flushall
      allow(Redis).to receive(:new).and_return(global_mock_redis)
    end
  end
end
