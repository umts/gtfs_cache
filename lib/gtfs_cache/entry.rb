module GtfsCache
  Entry = Struct.new("Entry", :data, :expires) do
    def fresh? = expires.blank? || expires >= Time.current
  end
end
