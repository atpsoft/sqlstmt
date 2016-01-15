require 'sqlstmt/query'
require 'sqlstmt/value_util'

class SqlStmtUpdate < SqlStmtQuery
  force_deep_copy :values
  include SqlStmtValueUtil

  def initialize
    super
    @values = []
  end

private
  def verify_minimum_requirements
    super
    raise SqlStmtError, "unable to build sql - must call :table" if @tables.empty?
    raise SqlStmtError, "unable to build sql - must call :field or :fieldq" if @fields.empty?
  end

  def build_set_clause
    set_exprs = []
    @fields.each_with_index do |field, index|
      set_exprs.push("#{field} = #{@values[index]}")
    end
    set_exprs.join(', ')
  end

  def build_stmt
    limit_clause = simple_clause('LIMIT', @limit)
    "UPDATE #{build_table_list}#{build_join_clause} SET #{build_set_clause}#{build_where_clause}#{limit_clause}"
  end
end
