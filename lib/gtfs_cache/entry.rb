module GtfsCache
  Entry = Data.define(:data, :expires) do
    def fresh? = expires.blank? || expires >= Time.current
  end
end
