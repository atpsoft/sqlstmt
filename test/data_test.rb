require 'minitest/autorun'
require 'sqlstmt/data'

class TestData < Minitest::Test
  def test_deep_copy_of_arrays
    orig = SqlStmtLib::SqlData.new
    orig.tables << 1
    assert_equal([1], orig.tables)

    copy = orig.dup
    assert_equal([1], copy.tables)

    copy.tables << 2
    assert_equal([1, 2], copy.tables)
    assert_equal([1], orig.tables)
  end
end
