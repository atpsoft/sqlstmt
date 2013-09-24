require 'sqlstmt/from_query'
require 'sqlstmt/value_util'

module SqlStmt

class InsertSelect < FromQuery
  force_deep_copy :values
  include ValueUtil

  def initialize
    super
    @values = []
    @distinct = @ignore = false
    @into_table = nil
  end

  def distinct
    @distinct = true
    self
  end

  def ignore
    @ignore = true
    self
  end

  def into(table)
    @into_table = table
    self
  end

private
  def verify_minimum_requirements
    super
    raise SqlStmt::Error, "unable to build sql - must call :into" if @into_table.nil?
    raise SqlStmt::Error, "unable to build sql - must call :field or :fieldq" if @fields.empty?
  end

  def build_stmt
    distinct_str = if @distinct then 'DISTINCT ' else '' end
    ignore_str = if @ignore then 'IGNORE ' else '' end
    into_str = @fields.join(',')
    select_str = @values.join(',')
    "INSERT #{ignore_str}INTO #@into_table (#{into_str}) SELECT #{distinct_str}#{select_str}#{build_from_clause}"
  end
end

end
