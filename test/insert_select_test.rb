require_relative 'helper'

class TestInsertSelect < Minitest::Test
  def test_minimum_requirements
    assert_raises(SqlStmtError) { SqlStmt.new.insert.into('target').to_s }
    assert_raises(SqlStmtError) { SqlStmt.new.insert.into('target').no_where.to_s }
    assert_raises(SqlStmtError) { SqlStmt.new.insert.into('target').no_where.set('blah', 'blee').to_s }
  end

  def test_simple
    assert_equal('INSERT INTO target (blah) SELECT blee FROM source', SqlStmt.new.insert.into('target').table('source').set('blah', 'blee').no_where.to_s)
    assert_equal('INSERT INTO target (blah) SELECT blee FROM source WHERE source_id = 1', SqlStmt.new.insert.into('target').table('source').set('blah', 'blee').where('source_id = 1').to_s)
  end

  def test_star
    assert_equal('INSERT INTO target SELECT * FROM source', SqlStmt.new.insert.into('target').table('source').set(nil, '*').no_where.to_s)
  end

  def test_dup
    shared_builder = SqlStmt.new.insert.into('target')
    first_builder = shared_builder
    other_builder = shared_builder.dup

    first_builder.where('status="bad"')
    first_builder.set('created_at', 'NOW()')
    first_builder.table('some_tbl s')

    other_builder.no_where
    other_builder.set('info', 'o.info')
    other_builder.set('created_at', 'then')
    other_builder.table('other_tbl o')

    assert_equal('INSERT INTO target (created_at) SELECT NOW() FROM some_tbl s WHERE status="bad"', first_builder.to_s)
    assert_equal('INSERT INTO target (info,created_at) SELECT o.info,then FROM other_tbl o', other_builder.to_s)
  end

  def test_complex
    shared_builder = SqlStmt.new.insert.into('target')
    shared_builder.table('shared_tbl')
    shared_builder.set('created_at', 'NOW()').set('duration', 5).setq('is_bad', 'b')

    first_builder = shared_builder
    other_builder = shared_builder.dup

    first_builder.where("status='bad'")

    other_builder.table('other_tbl o')
    other_builder.set('info', 'o.info')
    other_builder.set('data', 'o.data')
    other_builder.where('s.id=o.shared_id', "status='good'")

    assert_equal("INSERT INTO target (created_at,duration,is_bad) SELECT NOW(),5,'b' FROM shared_tbl WHERE status='bad'", first_builder.to_s)
    assert_equal("INSERT INTO target (created_at,duration,is_bad,info,data) SELECT NOW(),5,'b',o.info,o.data FROM shared_tbl,other_tbl o WHERE s.id=o.shared_id AND status='good'", other_builder.to_s)
  end
end
