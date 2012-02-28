require 'sqlstmt/delete'

module SqlStmt

class TestDelete < DohTest::TestGroup
  def test_minimum_requirements
    assert_raises(SqlStmt::Error) { Delete.new.table('target').to_s }
  end

  def test_simple
    assert_equal('DELETE target FROM target,other_table', Delete.new.from('target').table('other_table').no_where.to_s)
    assert_equal('DELETE FROM target', Delete.new.table('target').no_where.to_s)
    assert_equal('DELETE FROM target WHERE target_id = 1', Delete.new.table('target').where('target_id = 1').to_s)
  end
end

end
