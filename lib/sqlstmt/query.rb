require 'doh/core_ext/class/force_deep_copy'
require 'sqlstmt/error'
require 'sqlstmt/to_sql'

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

  def group_by(clause)
    @group_by = clause
    self
  end

  def order_by(clause)
    @order_by = clause
    self
  end

  def limit(clause)
    @limit = clause
    self
  end

private
  def verify_minimum_requirements
    raise SqlStmt::Error, "unable to build sql - must first call :field" if @fields.empty?
    raise SqlStmt::Error, "unable to build sql - must first call :table" if @tables.empty?
    raise SqlStmt::Error, "unable to build sql - must first call :where or :no_where" if @use_wheres && @wheres.empty?
    raise SqlStmt::Error, "unable to build sql - :where and :no_where must not be called on same builder instance" if !@use_wheres && !@wheres.empty?
  end

  def build_table_list
    @tables.join(',')
  end

  def build_where_clause
    if @wheres.empty? then '' else " WHERE #{@wheres.join(' AND ')}" end
  end
end

class FieldValueQuery < Query
  force_deep_copy :values

  def initialize
    super
    @values = []
  end

  def field(field, value)
    raise "trying to include field #{field} again" if @fields.include?(field)
    @fields.push(field)
    @values.push(if value.is_a?(String) then value else value.to_sql end)
    self
  end

  def fieldq(field, value)
    field(field, value.to_sql)
  end
end

end
