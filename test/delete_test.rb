require_relative 'helper'
require 'sqlstmt/delete'

class TestDelete < Minitest::Test
  def test_minimum_requirements
    assert_raises(SqlStmt::Error) { Delete.new.table('target').to_s }
  end

  def test_simple
    assert_equal('DELETE t FROM target t,other_table o', Delete.new.from('t').table('target t').table('other_table o').no_where.to_s)
    assert_equal('DELETE t,o FROM t JOIN o ON t.id=o.id', Delete.new.from('t').from('o').table('t').join('o','t.id=o.id').no_where.to_s)
    assert_equal('DELETE FROM target', Delete.new.table('target').no_where.to_s)
    assert_equal('DELETE FROM target WHERE target_id = 1', Delete.new.table('target').where('target_id = 1').to_s)
  end
end
