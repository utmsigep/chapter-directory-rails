require "test_helper"

class DistrictTest < ActiveSupport::TestCase
  test "fails when saving empty record" do
    district = District.new()
    assert_raise(ActiveRecord::RecordInvalid) { district.save! }
  end
end
