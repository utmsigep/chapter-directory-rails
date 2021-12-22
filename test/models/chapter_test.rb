require "test_helper"

class ChapterTest < ActiveSupport::TestCase
  test "finds correct region" do
    chapter = Chapter.find_by(name: 'Tennessee Kappa')
    assert_equal('Region 4', chapter.region.name)
  end

  test "finds correct district" do
    chapter = Chapter.find_by(name: 'Tennessee Kappa')
    assert_equal('District 17', chapter.district.name)
  end

  test "fails when saving empty record" do
    chapter = Chapter.new()
    assert_raise(ActiveRecord::RecordInvalid) { chapter.save! }
  end
end
