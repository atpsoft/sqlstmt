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
# meaning, we allow the choice of SQL dialect to be made at any time

# unless there is something better to return, methods return self so they can be chained together
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

  ###### tables & joins

  def table(ref, use_index = nil)
    @data.tables << include_table(ref, use_index)
    return self
  end

  def join(table, *exprs)
    return any_join('JOIN', table, exprs)
  end

  def left_join(table, *exprs)
    return any_join('LEFT JOIN', table, exprs)
  end

  def any_join(kwstr, ref, exprs)
    tbl = include_table(ref)
    @data.joins << SqlStmtLib::SqlJoin.new(kwstr, tbl, "ON #{exprs.join(' AND ')}")
    return self
  end

  def includes_table?(table_to_find)
    return @data.table_ids.include?(table_to_find)
  end

  ###### where

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

  ###### fields & values

  def get(*exprs)
    @data.get_fields.concat(exprs)
    return self
  end

  # nil can be passed in for the field, in which case it won't be added
  # this is only for the special case of INSERT INTO table SELECT b.* FROM blah b WHERE ...
  # where there are no specific fields listed
  def set(field, value)
    if @data.set_fields.include?(field)
      raise SqlStmtError, "trying to set field #{field} again"
    end

    if field
      @data.set_fields << field
    end
    value = value.is_a?(String) ? value : value.to_sql
    @data.set_values << value
    return self
  end

  def setq(field, value)
    return set(field, value.to_sql)
  end

  ###### not sure how to organize the rest of these yet
  ###### for now they are sorted roughly by my perception of how general purpose they are
  ###### the ones I suspect are dialect specific are at the bottom

  # select
  def having(*expr)
    @data.having.concat(expr)
    return self
  end

  SqlStmtLib::FLAG_KEYWORDS.each do |keyword|
    define_method(keyword) do
      @data[keyword] = true
      return self
    end
  end

  SqlStmtLib::SINGLE_VALUE_KEYWORDS.each do |keyword|
    define_method(keyword) do |value|
      @data[keyword] = value
      return self
    end
  end

private
  # this is used for method calls to :table and :any_join
  def include_table(ref, use_index = nil)
    parts = ref.split(' ')
    if parts.size == 3
      parts.delete_at(1)
    end
    @data.table_ids.merge(parts)

    if parts.size == 2
      tbl_name, tbl_alias = parts
    else
      tbl_name = tbl_alias = parts.first
    end
    return SqlStmtLib::SqlTable.new(ref, tbl_name, tbl_alias, use_index)
  end
end
