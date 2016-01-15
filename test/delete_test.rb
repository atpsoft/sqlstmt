require_relative 'helper'

class TestDelete < Minitest::Test
  def test_minimum_requirements
    assert_raises(SqlStmtError) { SqlStmt.new.delete.table('target').to_s }
  end

  def test_simple
    assert_equal('DELETE t FROM target t,other_table o', SqlStmt.new.delete('t').table('target t').table('other_table o').no_where.to_s)
    assert_equal('DELETE t,o FROM t JOIN o ON t.id=o.id', SqlStmt.new.delete('t', 'o').table('t').join('o','t.id=o.id').no_where.to_s)
    assert_equal('DELETE FROM target', SqlStmt.new.delete.table('target').no_where.to_s)
    assert_equal('DELETE FROM target WHERE target_id = 1', SqlStmt.new.delete.table('target').where('target_id = 1').to_s)
  end
end
