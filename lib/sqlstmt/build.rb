require 'sqlstmt/error'

class SqlStmt
  def to_s
    verify_minimum_requirements
    return build_stmt
  end
  alias_method :to_sql, :to_s

  ###### the remainder of the methods are for verifying and building the completed statement string

  def verify_minimum_requirements
    if !@stmt_type
      raise SqlStmtError, "unable to build sql - must call :select, :update, :insert or :delete to specify statement type"
    end
    if @tables.empty?
      raise SqlStmtError, "unable to build sql - must call :table"
    end

    if (@where_behavior == :require) && @wheres.empty?
      raise SqlStmtError, "unable to build sql - must call :where, :no_where, or :optional_where"
    elsif (@where_behavior == :exclude) && !@wheres.empty?
      raise SqlStmtError, "unable to build sql - :where and :no_where must not both be called, consider :optional_where instead"
    end

    if @stmt_type == 'select'
      raise SqlStmtError, "unable to build sql - must call :get" if @fields.empty?
      raise SqlStmtError, "unable to build sql - must not call :set" if !@values.empty?
    else
      raise SqlStmtError, "unable to build sql - must not call :get" if @called_get
    end

    if ['update','insert'].include?(@stmt_type)
      raise SqlStmtError, "unable to build sql - must call :set or :setq" if @values.empty?
      raise SqlStmtError, "unable to build sql - must not call :get" if @called_get
    end

    if @stmt_type == 'insert'
      raise SqlStmtError, "unable to build sql - must call :into" if @into_table.nil?
    end

    if @stmt_type == 'delete'
      raise SqlStmtError, "unable to build sql - must not call :get or :set" if !@fields.empty?
      if @tables_to_delete.empty? && ((@tables.size + @joins.size) > 1)
        raise SqlStmtError, "unable to build sql - must specify tables to delete when including multiple tables"
      end
    end
  end

  def build_stmt
    method_name = "build_stmt_#{@stmt_type}"
    return send(method_name)
  end

  def build_stmt_select
    straight_join_str = @straight_join ? 'STRAIGHT_JOIN ' : ''
    distinct_str = @distinct ? 'DISTINCT ' : ''
    select_str = @fields.join(',')
    return "SELECT #{straight_join_str}#{distinct_str}#{select_str}#{build_from_clause}#{@outfile}"
  end

  def build_stmt_update
    limit_clause = simple_clause('LIMIT', @limit)
    return "UPDATE #{build_table_list}#{build_join_clause} SET #{build_set_clause}#{build_where_clause}#{limit_clause}"
  end

  def build_stmt_insert
    if !@fields.empty? && !@rows.empty?
      raise "unable to use INSERT SELECT and INSERT VALUES together, may only call :set or :add_row, but not both"
    end

    keyword = @replace ? 'REPLACE' : 'INSERT'
    value_list = @values.join(',')
    start_str = "#{keyword} #{@ignore}INTO #{@into_table} "
    if !@fields.empty?
      field_list = @fields.join(',')
      start_str += "(#{field_list}) "
    end

    if @rows.empty?
      distinct_str = @distinct ? 'DISTINCT ' : ''
      return "#{start_str}SELECT #{distinct_str}#{value_list}#{build_from_clause}"
    else
      raise "DISTINCT not supported when inserting values" if @distinct
      return "#{start_str}VALUES (#{value_list})"
    end
  end

  def build_stmt_delete
    if @tables_to_delete.empty?
      table_clause = ''
    else
      table_clause = ' ' + @tables_to_delete.join(',')
    end
    return "DELETE#{table_clause}#{build_from_clause}"
  end

  def build_from_clause
    join_clause = build_join_clause
    group_clause = simple_clause('GROUP BY', @group_by)
    if @with_rollup
      group_clause += ' WITH ROLLUP'
    end
    order_clause = simple_clause('ORDER BY', @order_by)
    limit_clause = simple_clause('LIMIT', @limit)
    having_clause = @having.empty? ? '' : " HAVING #{@having.join(' AND ')}"
    return " FROM #{build_table_list}#{join_clause}#{build_where_clause}#{group_clause}#{having_clause}#{order_clause}#{limit_clause}"
  end

  def build_set_clause
    set_exprs = []
    @fields.each_with_index do |field, index|
      set_exprs << "#{field} = #{@values[index]}"
    end
    return set_exprs.join(', ')
  end

  def table_to_str(table)
    if table.index
      return "#{table.str} USE INDEX (#{table.index})"
    end
    return table.str
  end

  def build_table_list
    return @tables.map {|table| table_to_str(table) }.join(',')
  end

  def simple_clause(keywords, value)
    return value ? " #{keywords} #{value}" : ''
  end

  def build_join_clause
    if @joins.empty?
      return ''
    else
      return ' ' + @joins.map {|ary| ary.join(' ')}.uniq.join(' ')
    end
  end

  def build_where_clause
    return @wheres.empty? ? '' : " WHERE #{@wheres.join(' AND ')}"
  end
end
