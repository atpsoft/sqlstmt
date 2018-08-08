module SqlStmtLib
extend self

class MysqlBuilder
  def initialize(data)
    @data = data
  end

  def build_stmt
    method_name = "build_stmt_#{@data.stmt_type}"
    return send(method_name)
  end

  def build_stmt_select
    straight_join_str = @data.straight_join ? 'STRAIGHT_JOIN ' : ''
    distinct_str = @data.distinct ? 'DISTINCT ' : ''
    select_str = @data.gets.join(',')
    outfile_str = @data.outfile ? " INTO OUTFILE #{@data.outfile}" : ''
    return "SELECT #{straight_join_str}#{distinct_str}#{select_str}#{build_from_clause}#{outfile_str}"
  end

  def build_stmt_update
    limit_clause = simple_clause('LIMIT', @data.limit)
    return "UPDATE #{build_table_list}#{build_join_clause} SET #{build_set_clause}#{build_where_clause}#{limit_clause}"
  end

  def build_stmt_insert
    keyword = @data.replace ? 'REPLACE' : 'INSERT'
    value_list = @data.set_values.join(',')
    ignore_str = @data.ignore ? 'IGNORE ' : ''
    start_str = "#{keyword} #{ignore_str}INTO #{@data.into} "
    if !@data.set_fields.empty?
      field_list = @data.set_fields.join(',')
      start_str += "(#{field_list}) "
    end

    distinct_str = @data.distinct ? 'DISTINCT ' : ''
    return "#{start_str}SELECT #{distinct_str}#{value_list}#{build_from_clause}"
  end

  def build_stmt_delete
    if @data.tables_to_delete.empty?
      table_clause = ''
    else
      table_clause = ' ' + @data.tables_to_delete.join(',')
    end
    return "DELETE#{table_clause}#{build_from_clause}"
  end

  def build_from_clause
    join_clause = build_join_clause
    group_clause = simple_clause('GROUP BY', @data.group_by)
    if @data.with_rollup
      group_clause += ' WITH ROLLUP'
    end
    order_clause = simple_clause('ORDER BY', @data.order_by)
    limit_clause = simple_clause('LIMIT', @data.limit)
    having_clause = @data.havings.empty? ? '' : " HAVING #{@data.havings.join(' AND ')}"
    return " FROM #{build_table_list}#{join_clause}#{build_where_clause}#{group_clause}#{having_clause}#{order_clause}#{limit_clause}"
  end

  def build_set_clause
    set_exprs = []
    @data.set_fields.each_with_index do |field, index|
      set_exprs << "#{field} = #{@data.set_values[index]}"
    end
    return set_exprs.join(', ')
  end

  def table_to_str(table)
    if table.index
      return "#{table.str} USE INDEX (#{table.index})"
    end
    return table.str
  end

  def build_table_list
    return @data.tables.map {|table| table_to_str(table) }.join(',')
  end

  def simple_clause(keywords, value)
    return value ? " #{keywords} #{value}" : ''
  end

  def join_to_str(join)
    return [join.kwstr, join.table.str, join.on_expr].join(' ')
  end

  def build_join_clause
    if @data.joins.empty?
      return ''
    else
      # we call uniq here to be tolerant of a table being joined to multiple times in an identical fashion
      # where the intention is not actually to include the table multiple times
      # but I'm thinking we may want to reconsider, or at least warn when this happens so the source bug can be fixed
      return ' ' + @data.joins.map {|join| join_to_str(join)}.uniq.join(' ')
    end
  end

  def build_where_clause
    return @data.wheres.empty? ? '' : " WHERE #{@data.wheres.join(' AND ')}"
  end
end

end
