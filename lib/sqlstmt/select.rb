require 'sqlstmt/from_query'

module SqlStmt

class Select < FromQuery
  def initialize
    super
    @distinct = false
    @straight_join = false
    @into = nil
  end

  def field(*field_exprs)
    @fields.concat(field_exprs)
    self
  end

  def distinct
    @distinct = true
    self
  end

  def straight_join
    @straight_join = true
    self
  end

  def into_outfile(str)
    @into = "OUTFILE #{str}"
    self
  end

private
  def verify_minimum_requirements
    super
    raise SqlStmt::Error, "unable to build sql - must call :field" if @fields.empty?
  end

  def build_stmt
    straight_join_str = if @straight_join then 'STRAIGHT_JOIN ' else '' end
    distinct_str = if @distinct then 'DISTINCT ' else '' end
    into_str = if @into then " INTO #{@into}" else '' end
    select_str = @fields.join(',')
    "SELECT #{straight_join_str}#{distinct_str}#{select_str}#{build_from_clause}#{into_str}"
  end
end

end
