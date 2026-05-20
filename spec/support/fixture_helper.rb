require "pathname"

module FixtureHelper
  extend ActiveSupport::Concern

  def file_fixture(fixture_name) = Pathname.new(__dir__).join("../fixtures/files", fixture_name)
end
