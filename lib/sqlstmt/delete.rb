require 'sqlstmt/from_query'

module SqlStmt

class Delete < FromQuery
  force_deep_copy :from_tables

  def initialize
    super
    @from_tables = []
  end

  def from(table)
    @from_tables << table
    self
  end

private
  def verify_minimum_requirements
    super
    combined_table_count = @tables.size + @joins.size
    raise SqlStmt::Error, "unable to build sql - must call :from when including multiple tables" if @from_tables.empty? && (combined_table_count > 1)
  end

  def build_stmt
    if @from_tables.empty?
      table_clause = ''
    else
      table_clause = ' ' + @from_tables.join(',')
    end
    "DELETE#{table_clause}#{build_from_clause}"
  end
end

end
