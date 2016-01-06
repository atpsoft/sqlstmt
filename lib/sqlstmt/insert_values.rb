require 'sqlstmt/from_query'
require 'sqlstmt/value_util'

module SqlStmt

class InsertValues < FromQuery
  force_deep_copy :values
  include ValueUtil

  def initialize
    super
    @values = []
    @into_table = nil
    no_where
  end

  def into(table)
    @into_table = table
    table(table)
    self
  end

private
  def verify_minimum_requirements
    super
    raise SqlStmtError, "unable to build sql - must call :into" if @into_table.nil?
    raise SqlStmtError, "unable to build sql - must call :field or :fieldq" if @fields.empty?
  end

  def build_stmt
    into_str = @fields.join(',')
    values_str = @values.join(',')
    "INSERT INTO #@into_table (#{into_str}) VALUES (#{values_str})"
  end
end

end
