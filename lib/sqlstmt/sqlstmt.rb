require 'sqlstmt/error'
require 'sqlstmt/core_to_sql'

# in looking at the implementation, it could be asked:
# why are there not individual classes for each statement type?
# and indeed, it does seem a natural fit, and the first version was built that way
# however, this meant that the statement type had to be determined at object creation time
# and for some cases this was a limitation and in general went against the purposes of this library
# namely, to build the statement gradually and in no particular order, even the statement type
# for example, we might build a statement and add a where clause to it
# and some step later on would determine the statement type
# also, looking to the future of supporting other dialects of SQL, I think the same will be true there
# meaning, we don't the choice of SQL dialect to be allowed at any time
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
end
