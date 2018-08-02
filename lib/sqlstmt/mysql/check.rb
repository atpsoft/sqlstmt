require 'sqlstmt/error'

module SqlStmtLib
extend self

class MysqlChecker
  def initialize(data)
    @data = data
  end

  def run
    check_basics
    check_where
    check_statement_type_specific
  end

  def check_basics
    if !@data.stmt_type
      raise SqlStmtError, "must call :select, :update, :insert or :delete"
    end
    if @data.tables.empty?
      raise SqlStmtError, "must call :table"
    end
  end

  def check_where
    if (@data.where_behavior == :require) && @data.wheres.empty?
      raise SqlStmtError, "must call :where, :no_where, or :optional_where"
    elsif (@data.where_behavior == :exclude) && !@data.wheres.empty?
      raise SqlStmtError, ":where and :no_where must not both be called, consider :optional_where instead"
    end
  end

  def check_statement_type_specific
    method_name = "check_stmt_#{@data.stmt_type}"
    send(method_name)

    if @data.stmt_type != 'select'
      raise SqlStmtError, "must not call :get on #{@data.stmt_type} statement" if @data.called_get
    end
  end

  def check_stmt_select
    raise SqlStmtError, "must call :get on select statement" if @data.fields.empty?
    raise SqlStmtError, "must not call :set on select statement" if !@data.values.empty?
  end

  def check_stmt_update
    raise SqlStmtError, "must call :set on update statement" if @data.values.empty?
  end

  def check_stmt_insert
    raise SqlStmtError, "must call :set on insert statement" if @data.values.empty?
    raise SqlStmtError, "must call :into on insert statement" if @data.into_table.nil?

    if !@data.rows.empty?
      check_stmt_insert_values
    end
  end

  def check_stmt_insert_values
    if !@data.fields.empty?
      raise SqlStmtError, "unable to use INSERT SELECT and INSERT VALUES together, must call either :set or :add_row, but not both"
    end
    if @data.distinct
      raise SqlStmtError, "DISTINCT not supported with INSERT VALUES"
    end
  end

  def check_stmt_delete
    raise SqlStmtError, "must not call :set on delete statement" if !@data.values.empty?
    if @data.tables_to_delete.empty? && ((@data.tables.size + @data.joins.size) > 1)
      raise SqlStmtError, "must specify tables to delete when including multiple tables"
    end
  end
end

end
