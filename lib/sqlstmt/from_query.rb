require 'sqlstmt/query'

class SqlStmtFromQuery < SqlStmtQuery
  def initialize
    super
    @group_by = nil
    @order_by = nil
    @having = []
  end

  def group_by(clause)
    @group_by = clause
    self
  end

  def order_by(clause)
    @order_by = clause
    self
  end

  def having(*sql)
    @having.concat(sql)
    self
  end

private
  def verify_minimum_requirements
    super
    raise SqlStmtError, "unable to build sql - must call :table or :join (or one if it's variants)" if @tables.empty? && @joins.empty?
    raise SqlStmtError, "unable to build sql - must call :table if using :join (or one if it's variants)" if @tables.empty? && !@joins.empty?
  end

  def having_clause
    if @having.empty?
      ''
    else
      " HAVING #{@having.join(' AND ')}"
    end
  end

  def build_from_clause
    join_clause = build_join_clause
    group_clause = simple_clause('GROUP BY', @group_by)
    order_clause = simple_clause('ORDER BY', @order_by)
    limit_clause = simple_clause('LIMIT', @limit)
    " FROM #{build_table_list}#{join_clause}#{build_where_clause}#{group_clause}#{having_clause}#{order_clause}#{limit_clause}"
  end
end
