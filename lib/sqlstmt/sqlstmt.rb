require 'sqlstmt/data'
require 'sqlstmt/error'

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

# unless there is something better to return, all methods return self so they can be chained together
class SqlStmt
  attr_reader :data

  def initialize
    @data = SqlStmtLib::SqlData.new
  end

  def initialize_copy(_orig)
    @data = @data.dup
  end

  ###### pick statement type

  def select
    return type('select')
  end

  def update
    return type('update')
  end

  def insert
    return type('insert')
  end

  def delete(*tables)
    type('delete')
    @data.tables_to_delete = tables
    return self
  end

  def type(stmt_type)
    if @data.stmt_type
      raise SqlStmtError, "statement type already set to #{@data.stmt_type}"
    end
    @data.stmt_type = stmt_type
    return self
  end

  ###### common operations

  def table(str, use_index = nil)
    tbl_name, tbl_alias = str.split(' ')
    @data.tables << SqlStmtLib::SqlTable.new(str, tbl_name, tbl_alias, use_index)
    return self
  end

  def join(table, *exprs)
    return any_join('JOIN', table, exprs)
  end

  def left_join(table, *exprs)
    return any_join('LEFT JOIN', table, exprs)
  end

  def any_join(kwstr, table, exprs)
    @data.joins << [kwstr, table, "ON #{exprs.join(' AND ')}"]
    return self
  end

  def where(*expr)
    @data.wheres.concat(expr)
    return self
  end

  def no_where
    @data.where_behavior = :exclude
    return self
  end

  def optional_where
    @data.where_behavior = :optional
    return self
  end

  def get(*exprs)
    @data.fields.concat(exprs)
    @data.called_get = true
    return self
  end

  def set(field, value)
    raise SqlStmtError, "trying to include field #{field} again" if @data.fields.include?(field)
    # this is to support the special case of INSERT INTO table SELECT * FROM ...
    # where * specified with no matching insert field list specified
    if field
      @data.fields << field
    end
    value = value.is_a?(String) ? value : value.to_sql
    @data.values << value
    return self
  end

  def setq(field, value)
    return set(field, value.to_sql)
  end

  def group_by(expr)
    @data.group_by = expr
    return self
  end

  def order_by(expr)
    @data.order_by = expr
    return self
  end

  def limit(clause)
    @data.limit = clause
    return self
  end

  def having(*expr)
    @data.having.concat(expr)
    return self
  end

  def with_rollup
    @data.with_rollup = true
    return self
  end

  # used with INSERT statements only
  def into(into_table)
    @data.into_table = into_table
    return self
  end

  # used with INSERT VALUES statements only
  def add_row(row)
    @data.rows << row
  end

  ###### less commonly used methods

  def distinct
    @data.distinct = true
    return self
  end

  def straight_join
    @data.straight_join = true
    return self
  end

  def replace
    @data.replace = true
    return self
  end

  def ignore
    @data.ignore = 'IGNORE '
    return self
  end

  def outfile(str)
    @data.outfile = " INTO OUTFILE #{str}"
    return self
  end

  ###### methods to analyze what the statement contains
  def includes_table?(table_to_find)
    retval = @data.tables.find { |table| (table.name == table_to_find) || (table.alias == table_to_find) }
    retval ||= @data.joins.find { |_, table, _| table_names_match?(table, table_to_find) }
    return retval
  end

private


  def table_names_match?(fullstr, tofind)
    if tofind.index(' ') || !fullstr.index(' ')
      return fullstr == tofind
    end
    orig_name, _, tblas = fullstr.partition(' ')
    return (orig_name == tofind) || (tblas == tofind)
  end
end
