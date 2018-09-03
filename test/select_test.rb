require_relative 'helper'

# adding this extra line so lines can match up perfectly for now with the swift implementation
class TestSelect < Minitest::Test
  def test_gradually
    sqlt = SqlStmt.new

    # keep these chained together, so we have at least one test of the return value of all the method calls
    # in ruby this isn't particular tricky or unique, but still it's good to test
    sqlt.select.type('select')
    assert_raises(SqlStmtError) { sqlt.update() }

    sqlt.table('target')
    assert_equal(['target'], sqlt.data.table_ids.to_a())
    assert_raises(SqlStmtError) { sqlt.to_s() }

    sqlt.get('blah')
    assert_raises(SqlStmtError) { sqlt.to_s() }

    sqlt.no_where()
    assert_equal('SELECT blah FROM target', sqlt.to_sql())

    sqlt.require_where()
    assert_raises(SqlStmtError) { sqlt.to_s }

    sqlt.optional_where()
    assert_equal('SELECT blah FROM target', sqlt.to_sql())

    sqlt.where('frog = 1')
    assert_equal('SELECT blah FROM target WHERE frog = 1', sqlt.to_sql())

    sqlt.join('other o', 'target.id = o.id')
    assert_equal(['target', 'other', 'o'], sqlt.data.table_ids.to_a)
    assert_equal('SELECT blah FROM target JOIN other o ON target.id = o.id WHERE frog = 1', sqlt.to_sql())
  end

  def test_misc
    tmpl = SqlStmt.new.select().table('target t').get('blah').no_where()
    assert_equal(['target', 't'], tmpl.data.table_ids.to_a())

    sqlt = tmpl.dup()
    sqlt.distinct
    assert_equal('SELECT DISTINCT blah FROM target t', sqlt.to_sql())

    sqlt = tmpl.dup()
    sqlt.left_join('other o', 't.blah_id = o.blah_id')
    assert_equal('SELECT blah FROM target t LEFT JOIN other o ON t.blah_id = o.blah_id', sqlt.to_sql())

    sqlt = tmpl.dup()
    sqlt.get('blee', 'bloo')
    assert_equal('SELECT blah,blee,bloo FROM target t', sqlt.to_sql())

    sqlt = tmpl.dup()
    sqlt.having('blah > 0')
    assert_equal('SELECT blah FROM target t HAVING blah > 0', sqlt.to_sql())
  end

  def test_tables
    assert_equal('SELECT t.blah FROM target t USE INDEX (blee)', SqlStmt.new.select().table('target t', 'blee').no_where.get('t.blah').to_sql())
  end

  def test_group_by
    sqlt = SqlStmt.new.select().table('source').get('blah').no_where.group_by('blah')
    assert_equal('SELECT blah FROM source GROUP BY blah', sqlt.to_s)
    sqlt.with_rollup
    assert_equal('SELECT blah FROM source GROUP BY blah WITH ROLLUP', sqlt.to_s)
  end

  def test_duplicate_joins
    sqlt = SqlStmt.new.select().table('source s').get('frog').no_where
    4.times { sqlt.join('other o', 's.blah_id = o.blah_id') }
    assert_equal('SELECT frog FROM source s JOIN other o ON s.blah_id = o.blah_id', sqlt.to_s)
    assert_equal('other o', sqlt.data.joins.first.table.str)
  end

  def test_join_with_multiple_conditions
    %i(join left_join).each do |method|
      sqlt = SqlStmt.new.select().table('source s').get('frog').no_where.send(method, 'other o', 'z.blee_id = o.blee_id', 'z.other_field = o.other_field')
      method_sql = method.to_s.upcase.sub('_', ' ')
      assert_equal("SELECT frog FROM source s #{method_sql} other o ON z.blee_id = o.blee_id AND z.other_field = o.other_field", sqlt.to_s)
    end
  end

  def test_includes_table
    sqlt = SqlStmt.new.select().table('target')
    assert(sqlt.includes_table?('target'))
    assert_equal(['target'], sqlt.data.table_ids.to_a)

    sqlt = SqlStmt.new.select().table('target t')
    assert(sqlt.includes_table?('target'))
    assert(sqlt.includes_table?('t'))
    assert(!sqlt.includes_table?('blah'))

    sqlt = SqlStmt.new.select().table('target AS t')
    assert(sqlt.includes_table?('target'))
    assert(sqlt.includes_table?('t'))
  end
end
