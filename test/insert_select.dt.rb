require 'sqlstmt/insert_select'

module SqlStmt

class TestInsertSelect < DohTest::TestGroup
  def test_minimum_requirements
    assert_raises(SqlStmt::Error) { InsertSelect.new.insert_into('target').to_s }
    assert_raises(SqlStmt::Error) { InsertSelect.new.insert_into('target').no_where.to_s }
    assert_raises(SqlStmt::Error) { InsertSelect.new.insert_into('target').no_where.field('blah', 'blee').to_s }
  end

  def test_simple
    assert_equal('INSERT INTO target (blah) SELECT blee FROM source', InsertSelect.new.insert_into('target').table('source').field('blah', 'blee').no_where.to_s)
    assert_equal('INSERT INTO target (blah) SELECT blee FROM source WHERE source_id = 1', InsertSelect.new.insert_into('target').table('source').field('blah', 'blee').where('source_id = 1').to_s)
  end

  def test_dup
    shared_builder = SqlStmt::InsertSelect.new.insert_into('target')
    first_builder = shared_builder
    other_builder = shared_builder.dup

    first_builder.where('status="bad"')
    first_builder.field('created_at', 'NOW()')
    first_builder.table('some_tbl s')

    other_builder.no_where
    other_builder.field('info', 'o.info')
    other_builder.field('created_at', 'then')
    other_builder.table('other_tbl o')

    assert_equal('INSERT INTO target (created_at) SELECT NOW() FROM some_tbl s WHERE status="bad"', first_builder.to_s)
    assert_equal('INSERT INTO target (info,created_at) SELECT o.info,then FROM other_tbl o', other_builder.to_s)
  end

  def test_complex
    shared_builder = SqlStmt::InsertSelect.new.insert_into('target')
    shared_builder.table('shared_tbl')
    shared_builder.field('created_at', 'NOW()').field('duration', 5).fieldq('is_bad', 'b')

    first_builder = shared_builder
    other_builder = shared_builder.dup

    first_builder.where("status='bad'")

    other_builder.table('other_tbl o')
    other_builder.field('info', 'o.info')
    other_builder.field('data', 'o.data')
    other_builder.where('s.id=o.shared_id', "status='good'")

    assert_equal("INSERT INTO target (created_at,duration,is_bad) SELECT NOW(),5,'b' FROM shared_tbl WHERE status='bad'", first_builder.to_s)
    assert_equal("INSERT INTO target (created_at,duration,is_bad,info,data) SELECT NOW(),5,'b',o.info,o.data FROM shared_tbl,other_tbl o WHERE s.id=o.shared_id AND status='good'", other_builder.to_s)
  end
end

end
