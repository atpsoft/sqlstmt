require 'sqlstmt/query'

module SqlStmt

class FromQuery < Query
  force_deep_copy :joins

  def initialize
    super
    @joins = []
    @group_by = nil
    @order_by = nil
    @limit = nil
  end

  def join(table, expr)
    @joins.push("JOIN #{table} ON #{expr}")
    self
  end

  def join_using(table, *fields)
    @joins.push("JOIN #{table} USING (#{fields.join(',')})")
    self
  end

  def left_join(table, expr)
    @joins.push("LEFT JOIN #{table} ON #{expr}")
    self
  end

  def left_join_using(table, *fields)
    @joins.push("LEFT JOIN #{table} USING (#{fields.join(',')})")
    self
  end

  def group_by(clause)
    @group_by = clause
    self
  end

  def order_by(clause)
    @order_by = clause
    self
  end

  def limit(clause)
    @limit = clause
    self
  end

private
  def verify_minimum_requirements
    super
    raise SqlStmt::Error, "unable to build sql - must call :table or :join (or one if it's variants)" if @tables.empty? && @joins.empty?
    raise SqlStmt::Error, "unable to build sql - must call :table if using :join (or one if it's variants)" if @tables.empty? && !@joins.empty?
  end

  def simple_clause(keywords, value)
    if value then " #{keywords} #{value}" else '' end
  end

  def build_from_clause
    join_clause = if @joins.empty? then '' else " #{@joins.join(' ')}" end
    group_clause = simple_clause('GROUP BY', @group_by)
    order_clause = simple_clause('ORDER BY', @order_by)
    limit_clause = simple_clause('LIMIT', @limit)
    " FROM #{build_table_list}#{join_clause}#{build_where_clause}#{group_clause}#{order_clause}#{limit_clause}"
  end
end

end
