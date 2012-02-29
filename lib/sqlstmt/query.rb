require 'doh/core_ext/force_deep_copy'
require 'sqlstmt/error'

module SqlStmt

class Query
  force_deep_copy :fields, :tables, :wheres

  def initialize
    @fields = []
    @tables = []
    @wheres = []
    @use_wheres = true
  end

  def table(table)
    @tables.push(table)
    self
  end

  def where(*sql)
    @wheres.concat(sql)
    self
  end

  def no_where
    @use_wheres = false
    self
  end

  def to_s
    verify_minimum_requirements
    build_stmt
  end

private
  def verify_minimum_requirements
    raise SqlStmt::Error, "unable to build sql - must call :where or :no_where" if @use_wheres && @wheres.empty?
    raise SqlStmt::Error, "unable to build sql - :where and :no_where must not both be called" if !@use_wheres && !@wheres.empty?
  end

  def build_table_list
    @tables.join(',')
  end

  def build_where_clause
    if @wheres.empty? then '' else " WHERE #{@wheres.join(' AND ')}" end
  end
end

end
