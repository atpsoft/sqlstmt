require 'sqlstmt/query'
require 'sqlstmt/value_util'

module SqlStmt

class Update < Query
  force_deep_copy :values
  include ValueUtil

  def initialize
    super
    @values = []
  end

private
  def verify_minimum_requirements
    super
    raise SqlStmt::Error, "unable to build sql - must call :table" if @tables.empty?
    raise SqlStmt::Error, "unable to build sql - must call :field or :fieldq" if @fields.empty?
  end

  def build_set_clause
    set_exprs = []
    @fields.each_with_index do |field, index|
      set_exprs.push("#{field} = #{@values[index]}")
    end
    set_exprs.join(', ')
  end

  def build_stmt
    "UPDATE #{build_table_list}#{build_join_clause} SET #{build_set_clause}#{build_where_clause}"
  end
end

end
