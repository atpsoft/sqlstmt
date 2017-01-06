require 'sqlstmt/error'
require 'sqlstmt/to_sql'

class SqlStmt
  attr_reader :fields, :tables, :joins, :wheres
  Table = Struct.new(:str, :name, :alias, :index)

  def initialize
    @stmt_type = nil
    @tables = []
    @joins = []
    @wheres = []
    @where_behavior = :require
    @fields = []
    @values = []
    @group_by = nil
    @order_by = nil
    @limit = nil
    @having = []
    @into_table = nil
    @rows = []
    @tables_to_delete = []
    @distinct = nil
    @straight_join = nil
    @replace = nil
    @ignore = ''
    @outfile = ''
    @with_rollup = nil
    # track this explicitly to guarantee get is not used with non-select statements
    @called_get = false
  end

  def initialize_copy(orig)
    super
    @tables = @tables.dup
    @joins = @joins.dup
    @wheres = @wheres.dup
    @fields = @fields.dup
    @values = @values.dup
    @having = @having.dup
    @rows = @rows.dup
  end

  ###### pick statement type

  def select
    ensure_no_statement_type
    @stmt_type = 'select'
    return self
  end

  def update
    ensure_no_statement_type
    @stmt_type = 'update'
    return self
  end

  def insert
    ensure_no_statement_type
    @stmt_type = 'insert'
    return self
  end

  def delete(*tables)
    ensure_no_statement_type
    @stmt_type = 'delete'
    @tables_to_delete = tables
    return self
  end

  ###### common operations

  def table(table_str, use_index = nil)
    parts = table_str.split(' ')
    table_obj = Table.new(table_str, parts[0], parts[1], use_index)
    @tables << table_obj
    return self
  end

  def join(table, *exprs)
    return add_join('JOIN', table, exprs)
  end

  def left_join(table, *exprs)
    return add_join('LEFT JOIN', table, exprs)
  end

  def where(*expr)
    @wheres.concat(expr)
    return self
  end

  def no_where
    @where_behavior = :exclude
    return self
  end

  def optional_where
    @where_behavior = :optional
    return self
  end

  def get(*exprs)
    @fields.concat(exprs)
    @called_get = true
    return self
  end

  def set(field, value)
    raise "trying to include field #{field} again" if @fields.include?(field)
    # this is to support the special case of INSERT INTO table SELECT * FROM ...
    # where * specified with no matching insert field list specified
    if field
      @fields << field
    end
    value = value.is_a?(String) ? value : value.to_sql
    @values << value
    return self
  end

  def setq(field, value)
    return set(field, value.to_sql)
  end

  def group_by(expr)
    @group_by = expr
    return self
  end

  def order_by(expr)
    @order_by = expr
    return self
  end

  def limit(clause)
    @limit = clause
    return self
  end

  def having(*expr)
    @having.concat(expr)
    return self
  end

  def with_rollup
    @with_rollup = true
    return self
  end

  # used with INSERT statements only
  def into(into_table)
    @into_table = into_table
    return self
  end

  # used with INSERT VALUES statements only
  def add_row(row)
    @rows << row
  end

  def to_s
    verify_minimum_requirements
    return build_stmt
  end
  alias_method :to_sql, :to_s

  ###### less commonly used methods

  def distinct
    @distinct = true
    return self
  end

  def straight_join
    @straight_join = true
    return self
  end

  def replace
    @replace = true
    return self
  end

  def ignore
    @ignore = 'IGNORE '
    return self
  end

  def outfile(str)
    @outfile = " INTO OUTFILE #{str}"
    return self
  end

  ###### methods to analyze what the statement contains
  def includes_table?(table_to_find)
    retval = @tables.find { |table| (table.name == table_to_find) || (table.alias == table_to_find) }
    retval ||= @joins.find { |_, table, _| table_names_match?(table, table_to_find) }
    return retval
  end

private
  def ensure_no_statement_type
    if @stmt_type
      raise "statement type already set to #{@stmt_type}"
    end
  end

  def add_join(keyword, table, exprs)
    @joins << [keyword, table, "ON #{exprs.join(' AND ')}"]
    return self
  end

  def table_names_match?(fullstr, tofind)
    if tofind.index(' ') || !fullstr.index(' ')
      return fullstr == tofind
    end
    orig_name, _, tblas = fullstr.partition(' ')
    return (orig_name == tofind) || (tblas == tofind)
  end

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
