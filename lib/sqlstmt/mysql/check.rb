require 'sqlstmt/error'

module SqlStmtLib
extend self

class MysqlChecker
  def initialize(data)
    @data = data
  end

  def run
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

end
