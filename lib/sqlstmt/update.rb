require 'sqlstmt/query'

module SqlStmt

class Update < FieldValueQuery
private
  def build_set_clause
    set_exprs = []
    @fields.each_with_index do |field, index|
      set_exprs.push("#{field} = #{@values[index]}")
    end
    set_exprs.join(', ')
  end

  def build_stmt
    "UPDATE #{build_table_list} SET #{build_set_clause}#{build_where_clause}"
  end
end

end
