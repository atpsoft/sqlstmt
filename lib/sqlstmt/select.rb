require 'sqlstmt/from_query'

module SqlStmt

class Select < FromQuery
  def field(*field_exprs)
    @fields.concat(field_exprs)
    self
  end

  def distinct
    @distinct = true
    self
  end

  def into(str)
    @into = str
    self
  end

private
  def verify_minimum_requirements
    super
    raise SqlStmt::Error, "unable to build sql - must call :field" if @fields.empty?
  end

  def build_stmt
    distinct_str = if @distinct then 'DISTINCT ' else '' end
    into_str = if @into then " INTO #{@into}" else '' end
    select_str = @fields.join(',')
    "SELECT #{distinct_str}#{select_str}#{build_from_clause}#{into_str}"
  end
end

end
