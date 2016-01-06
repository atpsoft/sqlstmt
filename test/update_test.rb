require_relative 'helper'
require 'sqlstmt/update'

module SqlStmt

class TestUpdate < Minitest::Test
  def test_minimum_requirements
    assert_raises(SqlStmt::Error) { Update.new.table('target').to_s }
    assert_raises(SqlStmt::Error) { Update.new.table('target').no_where.to_s }
  end

  def test_simple
    assert_equal('UPDATE target SET blah = blee', Update.new.table('target').field('blah', 'blee').no_where.to_s)
    assert_equal('UPDATE target SET blah = blee LIMIT 3', Update.new.table('target').field('blah', 'blee').no_where.limit(3).to_s)
    assert_equal('UPDATE target SET blah = blee WHERE target_id = 1', Update.new.table('target').field('blah', 'blee').where('target_id = 1').to_s)
  end

  def test_join
    builder = SqlStmt::Update.new.table('main m').join('other o', 'm.main_id = o.main_id')
    builder.field('blah', 3)
    builder.no_where
    assert_equal('UPDATE main m JOIN other o ON m.main_id = o.main_id SET blah = 3', builder.to_s)
  end

  def test_dup
    shared_builder = SqlStmt::Update.new.table('target')
    first_builder = shared_builder
    other_builder = shared_builder.dup

    first_builder.where('status="bad"')
    first_builder.field('created_at', 'NOW()')
    first_builder.table('some_tbl s')

    other_builder.no_where
    other_builder.field('info', 'o.info')
    other_builder.field('created_at', 'then')
    other_builder.table('other_tbl o')

    assert_equal('UPDATE target,some_tbl s SET created_at = NOW() WHERE status="bad"', first_builder.to_s)
    assert_equal('UPDATE target,other_tbl o SET info = o.info, created_at = then', other_builder.to_s)
  end

  def test_complex
    shared_builder = SqlStmt::Update.new.table('target')
    shared_builder.table('shared_tbl')
    shared_builder.field('created_at', 'NOW()').field('duration', 5).field('is_bad', 1)

    first_builder = shared_builder
    other_builder = shared_builder.dup

    first_builder.where('status="bad"')

    other_builder.table('other_tbl o')
    other_builder.field('info', 'o.info')
    other_builder.field('data', 'o.data')
    other_builder.where('s.id=o.shared_id')
    other_builder.where('status="good"')

    assert_equal('UPDATE target,shared_tbl SET created_at = NOW(), duration = 5, is_bad = 1 WHERE status="bad"', first_builder.to_s)
    assert_equal('UPDATE target,shared_tbl,other_tbl o SET created_at = NOW(), duration = 5, is_bad = 1, info = o.info, data = o.data WHERE s.id=o.shared_id AND status="good"', other_builder.to_s)
  end
end

end
