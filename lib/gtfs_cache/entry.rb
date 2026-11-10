module GtfsCache
  Entry = Data.define(:data, :expires) do
    def fresh? = expires.present? && expires >= Time.current
  end
end
