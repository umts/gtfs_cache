module GtfsCache
  Entry = Data.define(:data, :etag, :time, :expires) do
    def fresh? = [data, etag, time, expires].all?(&:present?) && expires >= Time.current
  end
end
