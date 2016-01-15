require 'dohutil/core_ext/force_deep_copy'
require 'sqlstmt/error'

class SqlStmtQuery
  force_deep_copy :fields, :tables, :joins, :wheres
  attr_reader :fields, :tables, :joins, :wheres

  def initialize
    @fields = []
    @tables = []
    @joins = []
    @wheres = []
    @where_behavior = :require
    @limit = nil
  end

  def table(table)
    @tables << table
    self
  end

  def join(table, *exprs)
    @joins << ['JOIN', table, "ON #{exprs.join(' AND ')}"]
    self
  end

  def optional_join(table, expr)
    unless includes_table?(table)
      join(table, expr)
    end
  end

  def left_join(table, *exprs)
    @joins << ['LEFT JOIN', table, "ON #{exprs.join(' AND ')}"]
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

  def limit(clause)
    @limit = clause
    self
  end

  def to_s
    verify_minimum_requirements
    build_stmt
  end
  alias_method :to_sql, :to_s

  def includes_table?(table_to_find)
    retval = @tables.find { |table| table_names_match?(table, table_to_find) }
    retval ||= @joins.find { |_, table, _| table_names_match?(table, table_to_find) }
    retval
  end

private
  def table_names_match?(fullstr, tofind)
    if tofind.index(' ') || !fullstr.index(' ')
      return fullstr == tofind
    end
    orig_name, _, tblas = fullstr.partition(' ')
    (orig_name == tofind) || (tblas == tofind)
  end

  def verify_minimum_requirements
    if (@where_behavior == :require) && @wheres.empty?
      raise SqlStmtError, "unable to build sql - must call :where, :no_where, or :optional_where"
    elsif (@where_behavior == :exclude) && !@wheres.empty?
      raise SqlStmtError, "unable to build sql - :where and :no_where must not both be called, consider :optional_where instead"
    end
  end

  def build_table_list
    @tables.join(',')
  end

  def simple_clause(keywords, value)
    if value then " #{keywords} #{value}" else '' end
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
