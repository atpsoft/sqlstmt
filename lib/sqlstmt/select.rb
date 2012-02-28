require 'sqlstmt/from_query'

module SqlStmt

class Select < FromQuery
  def field(*field_exprs)
    @fields.concat(field_exprs)
    self
  end

private
  def verify_minimum_requirements
    super
    raise SqlStmt::Error, "unable to build sql - must call :field" if @fields.empty?
  end

  def build_stmt
    select_str = @fields.join(',')
    "SELECT #{select_str}#{build_from_clause}"
  end
end

end
