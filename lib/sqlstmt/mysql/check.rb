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
      raise SqlStmtError, "must not call :get on #{@data.stmt_type} statement" if !@data.get_fields.empty?
    end
  end

  def check_stmt_select
    raise SqlStmtError, "must call :get on select statement" if @data.get_fields.empty?
    raise SqlStmtError, "must not call :set on select statement" if !@data.set_values.empty?
  end

  def check_stmt_update
    raise SqlStmtError, "must call :set on update statement" if @data.set_values.empty?
  end

  def check_stmt_insert
    raise SqlStmtError, "must call :set on insert statement" if @data.set_values.empty?
    raise SqlStmtError, "must call :into on insert statement" if @data.into_table.nil?
  end

  def check_stmt_delete
    raise SqlStmtError, "must not call :set on delete statement" if !@data.set_values.empty?
    if @data.tables_to_delete.empty? && ((@data.tables.size + @data.joins.size) > 1)
      raise SqlStmtError, "must specify tables to delete when including multiple tables"
    end
  end
end

end
