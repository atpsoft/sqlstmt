require_relative 'helper'

class TestDelete < Minitest::Test
  def test_minimum_requirements
    assert_raises(SqlStmtError) { SqlStmtDelete.new.table('target').to_s }
  end

  def test_simple
    assert_equal('DELETE t FROM target t,other_table o', SqlStmtDelete.new.from('t').table('target t').table('other_table o').no_where.to_s)
    assert_equal('DELETE t,o FROM t JOIN o ON t.id=o.id', SqlStmtDelete.new.from('t').from('o').table('t').join('o','t.id=o.id').no_where.to_s)
    assert_equal('DELETE FROM target', SqlStmtDelete.new.table('target').no_where.to_s)
    assert_equal('DELETE FROM target WHERE target_id = 1', SqlStmtDelete.new.table('target').where('target_id = 1').to_s)
  end
end
