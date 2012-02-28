require 'sqlstmt/from_query'

module SqlStmt

class Delete < FromQuery
  def initialize
    super
    @from_table = nil
  end

  def from(table)
    @from_table = table
    @tables.push(table)
    self
  end

private
  def verify_minimum_requirements
    super
    combined_table_count = @tables.size + @joins.size
    raise SqlStmt::Error, "unable to build sql - must call :from when including multiple tables" if @from_table.nil? && (combined_table_count > 1)
  end

  def build_stmt
    if @from_table
      table_clause = " #@from_table"
    else
      table_clause = ''
    end
    "DELETE#{table_clause}#{build_from_clause}"
  end
end

end
