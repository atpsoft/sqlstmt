require 'dohutil/core_ext/force_deep_copy'
require 'sqlstmt/error'

module SqlStmt

class Query
  force_deep_copy :fields, :tables, :joins, :wheres
  attr_reader :fields, :tables, :joins, :wheres

  def initialize
    @fields = []
    @tables = []
    @joins = []
    @wheres = []
    @where_behavior = :require
  end

  def table(table)
    @tables << table
    self
  end

  def join(table, expr)
    @joins << ['JOIN', table, "ON #{expr}"]
    self
  end

  def optional_join(table, expr)
    unless includes_table?(table)
      join(table, expr)
    end
  end

  def join_using(table, *fields)
    @joins << ['JOIN', table, "USING (#{fields.join(',')})"]
    self
  end

  def left_join(table, expr)
    @joins << ['LEFT JOIN', table, "ON #{expr}"]
    self
  end

  def left_join_using(table, *fields)
    @joins << ['LEFT JOIN', table, "USING (#{fields.join(',')})"]
    self
  end

  def where(*sql)
    @wheres.concat(sql)
    self
  end

  def no_where
    @where_behavior = :exclude
    self
  end

  def optional_where
    @where_behavior = :optional
    self
  end

  def to_s
    verify_minimum_requirements
    build_stmt
  end

  def includes_table?(table_to_find)
    return true if @tables.include?(table_to_find)
    @joins.find do |_, table, _|
      table_to_find == table
    end
  end

private
  def verify_minimum_requirements
    if (@where_behavior == :require) && @wheres.empty?
      raise SqlStmt::Error, "unable to build sql - must call :where, :no_where, or :optional_where"
    elsif (@where_behavior == :exclude) && !@wheres.empty?
      raise SqlStmt::Error, "unable to build sql - :where and :no_where must not both be called, consider :optional_where instead"
    end
  end

  def build_table_list
    @tables.join(',')
  end

  def build_join_clause
    if @joins.empty?
      ''
    else
      ' ' + @joins.collect{|ary| ary.join(' ')}.uniq.join(' ')
    end
  end

  def build_where_clause
    if @wheres.empty? then '' else " WHERE #{@wheres.join(' AND ')}" end
  end
end

end
