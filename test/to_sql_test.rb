require_relative 'helper'

class Test_to_sql < Minitest::Test
  def test_to_sql
    assert_equal('NULL', nil.to_sql)

    assert_equal("'blah'", 'blah'.to_sql)
    assert_equal("'b\\\\lah'", "b\\lah".to_sql())
    assert_equal("'b''lah'", "b'lah".to_sql())
    assert_equal("'b\"lah'", "b\"lah".to_sql())

    assert_equal('3', 3.to_sql)
    assert_equal('10.0', BigDecimal('10').to_sql)

    assert_equal('1', true.to_sql)
    assert_equal('0', false.to_sql)

    assert_equal("'2008-09-24'", Date.new(2008,9,24).to_sql)
    assert_equal("'2008-09-24 09:30:04'", DateTime.new(2008,9,24,9,30,4).to_sql)

    assert_equal("('a','b','c')", ['a', 'b', 'c'].to_sql)
  end
end
