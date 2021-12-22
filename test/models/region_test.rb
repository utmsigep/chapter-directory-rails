require "test_helper"

class RegionTest < ActiveSupport::TestCase
  test "fails when saving empty record" do
    region = Region.new()
    assert_raise(ActiveRecord::RecordInvalid) { region.save! }
  end
end
