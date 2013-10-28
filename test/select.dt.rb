require 'sqlstmt/select'

module SqlStmt

class TestSelect < DohTest::TestGroup
  def test_includes_table
    sqlb = Select.new.table('target t')
    assert(sqlb.includes_table?('target'))
    assert(sqlb.includes_table?('t'))
    assert(!sqlb.includes_table?('blah'))
  end

  def test_minimum_requirements
    assert_raises(SqlStmt::Error) { Select.new.table('target').to_s }
    assert_raises(SqlStmt::Error) { Select.new.table('target').no_where.to_s }
    assert_raises(SqlStmt::Error) { Select.new.table('target').optional_where.to_s }
    assert_equal('SELECT blah FROM target', Select.new.table('target').optional_where.field('blah').to_s)
  end

  def test_stuff
    assert_equal('SELECT blah FROM source', Select.new.table('source').field('blah').no_where.to_s)
    assert_equal('SELECT DISTINCT blah FROM source', Select.new.table('source').field('blah').no_where.distinct.to_s)
    assert_equal('SELECT blah FROM source WHERE source_id = 1', Select.new.table('source').field('blah').where('source_id = 1').to_s)
    assert_equal('SELECT blah FROM source s', Select.new.table('source s').field('blah').no_where.to_s)
    assert_equal('SELECT blah FROM source s JOIN other o ON s.blah_id = o.blah_id', Select.new.table('source s').join('other o', 's.blah_id = o.blah_id').field('blah').no_where.to_s)
    assert_equal('SELECT blah FROM source s JOIN other o USING (blah_id)', Select.new.table('source s').join_using('other o', 'blah_id').field('blah').no_where.to_s)
    assert_equal('SELECT blah FROM source s LEFT JOIN other o ON s.blah_id = o.blah_id', Select.new.table('source s').left_join('other o', 's.blah_id = o.blah_id').field('blah').no_where.to_s)
    assert_equal('SELECT blah FROM source s LEFT JOIN other o USING (blah_id)', Select.new.table('source s').left_join_using('other o', 'blah_id').field('blah').no_where.to_s)
    assert_equal('SELECT blah,blee FROM source', Select.new.table('source').field('blah','blee').no_where.to_s)
    assert_equal('SELECT blah FROM source HAVING blee > 0', Select.new.table('source').field('blah').no_where.having('blee > 0').to_s)
  end

  def test_duplicate_joins
    base_sqlb = Select.new.table('source s').field('frog').no_where

    sqlb = base_sqlb.dup
    4.times { sqlb.join('other o', 's.blah_id = o.blah_id') }
    sqlb.optional_join('other o', 'z.blee_id = o.blee_id')
    assert_equal('SELECT frog FROM source s JOIN other o ON s.blah_id = o.blah_id', sqlb.to_s)

    sqlb = base_sqlb.dup
    sqlb.optional_join('other o', 'z.blee_id = o.blee_id')
    assert_equal('SELECT frog FROM source s JOIN other o ON z.blee_id = o.blee_id', sqlb.to_s)
  end
end

end
