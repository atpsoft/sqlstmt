require 'sqlstmt/query'

module SqlStmt

class Select < Query
  force_deep_copy :joins

  def initialize
    super
    @joins = []
    @group_by = nil
    @order_by = nil
    @limit = nil
  end

  def field(*field_exprs)
    @fields.concat(field_exprs)
    self
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
  def simple_clause(keywords, value)
    if value then " #{keywords} #{value}" else '' end
  end

  def build_stmt
    select_str = @fields.join(',')
    join_clause = if @joins.empty? then '' else " #{@joins.join(' ')}" end
    group_clause = simple_clause('GROUP BY', @group_by)
    order_clause = simple_clause('ORDER BY', @order_by)
    limit_clause = simple_clause('LIMIT', @limit)
    "SELECT #{select_str} FROM #{build_table_list}#{join_clause}#{build_where_clause}#{group_clause}#{order_clause}#{limit_clause}"
  end
end

end
