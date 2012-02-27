require 'sqlstmt/query'

module SqlStmt

class InsertSelect < FieldValueQuery
  def initialize
    super
    @into_table = nil
  end

  def into(table)
    @into_table = table
    self
  end

private
  def verify_minimum_requirements
    super
    raise SqlStmt::Error, "unable to build sql - must first call :into" if @into_table.nil?
  end

  def build_stmt
    into_str = @fields.join(',')
    select_str = @values.join(',')
    "INSERT INTO #@into_table (#{into_str}) SELECT #{select_str} FROM #{build_table_list}#{build_where_clause}"
  end
end

end
