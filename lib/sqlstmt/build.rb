require 'sqlstmt/error'

module SqlStmtLib
extend self

class MysqlBuilder
  def initialize(data)
    @data = data
  end

  def build_stmt
    method_name = "build_stmt_#{@data.stmt_type}"
    return send(method_name)
  end

  def build_stmt_select
    straight_join_str = @data.straight_join ? 'STRAIGHT_JOIN ' : ''
    distinct_str = @data.distinct ? 'DISTINCT ' : ''
    select_str = @data.fields.join(',')
    return "SELECT #{straight_join_str}#{distinct_str}#{select_str}#{build_from_clause}#{@data.outfile}"
  end

  def build_stmt_update
    limit_clause = simple_clause('LIMIT', @data.limit)
    return "UPDATE #{build_table_list}#{build_join_clause} SET #{build_set_clause}#{build_where_clause}#{limit_clause}"
  end

  def build_stmt_insert
    if !@data.fields.empty? && !@data.rows.empty?
      raise "unable to use INSERT SELECT and INSERT VALUES together, may only call :set or :add_row, but not both"
    end

    keyword = @data.replace ? 'REPLACE' : 'INSERT'
    value_list = @data.values.join(',')
    start_str = "#{keyword} #{@data.ignore}INTO #{@data.into_table} "
    if !@data.fields.empty?
      field_list = @data.fields.join(',')
      start_str += "(#{field_list}) "
    end

    if @data.rows.empty?
      distinct_str = @data.distinct ? 'DISTINCT ' : ''
      return "#{start_str}SELECT #{distinct_str}#{value_list}#{build_from_clause}"
    else
      raise "DISTINCT not supported when inserting values" if @data.distinct
      return "#{start_str}VALUES (#{value_list})"
    end
  end

  def build_stmt_delete
    if @data.tables_to_delete.empty?
      table_clause = ''
    else
      table_clause = ' ' + @data.tables_to_delete.join(',')
    end
    return "DELETE#{table_clause}#{build_from_clause}"
  end

  def build_from_clause
    join_clause = build_join_clause
    group_clause = simple_clause('GROUP BY', @data.group_by)
    if @data.with_rollup
      group_clause += ' WITH ROLLUP'
    end
    order_clause = simple_clause('ORDER BY', @data.order_by)
    limit_clause = simple_clause('LIMIT', @data.limit)
    having_clause = @data.having.empty? ? '' : " HAVING #{@data.having.join(' AND ')}"
    return " FROM #{build_table_list}#{join_clause}#{build_where_clause}#{group_clause}#{having_clause}#{order_clause}#{limit_clause}"
  end

  def build_set_clause
    set_exprs = []
    @data.fields.each_with_index do |field, index|
      set_exprs << "#{field} = #{@data.values[index]}"
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
    return @data.tables.map {|table| table_to_str(table) }.join(',')
  end

  def simple_clause(keywords, value)
    return value ? " #{keywords} #{value}" : ''
  end

  def build_join_clause
    if @data.joins.empty?
      return ''
    else
      return ' ' + @data.joins.map {|ary| ary.join(' ')}.uniq.join(' ')
    end
  end

  def build_where_clause
    return @data.wheres.empty? ? '' : " WHERE #{@data.wheres.join(' AND ')}"
  end
end

end

class SqlStmt
  def to_s
    verify_minimum_requirements
    return SqlStmtLib::MysqlBuilder.new(@data).build_stmt
  end
  alias_method :to_sql, :to_s

  ###### the remainder of the methods are for verifying and building the completed statement string

  def verify_minimum_requirements
    if !@data.stmt_type
      raise SqlStmtError, "unable to build sql - must call :select, :update, :insert or :delete to specify statement type"
    end
    if @data.tables.empty?
      raise SqlStmtError, "unable to build sql - must call :table"
    end

    if (@data.where_behavior == :require) && @data.wheres.empty?
      raise SqlStmtError, "unable to build sql - must call :where, :no_where, or :optional_where"
    elsif (@data.where_behavior == :exclude) && !@data.wheres.empty?
      raise SqlStmtError, "unable to build sql - :where and :no_where must not both be called, consider :optional_where instead"
    end

    if @data.stmt_type == 'select'
      raise SqlStmtError, "unable to build sql - must call :get" if @data.fields.empty?
      raise SqlStmtError, "unable to build sql - must not call :set" if !@data.values.empty?
    else
      raise SqlStmtError, "unable to build sql - must not call :get" if @data.called_get
    end

    if ['update','insert'].include?(@data.stmt_type)
      raise SqlStmtError, "unable to build sql - must call :set or :setq" if @data.values.empty?
      raise SqlStmtError, "unable to build sql - must not call :get" if @data.called_get
    end

    if @data.stmt_type == 'insert'
      raise SqlStmtError, "unable to build sql - must call :into" if @data.into_table.nil?
    end

    if @data.stmt_type == 'delete'
      raise SqlStmtError, "unable to build sql - must not call :get or :set" if !@data.fields.empty?
      if @data.tables_to_delete.empty? && ((@data.tables.size + @data.joins.size) > 1)
        raise SqlStmtError, "unable to build sql - must specify tables to delete when including multiple tables"
      end
    end
  end

end
