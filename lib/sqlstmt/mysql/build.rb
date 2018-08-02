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
    select_str = @data.fields.join(',')
    return "SELECT #{straight_join_str}#{distinct_str}#{select_str}#{build_from_clause}#{@data.outfile}"
  end

  def build_stmt_update
    limit_clause = simple_clause('LIMIT', @data.limit)
    return "UPDATE #{build_table_list}#{build_join_clause} SET #{build_set_clause}#{build_where_clause}#{limit_clause}"
  end

  def build_stmt_insert
    keyword = @data.replace ? 'REPLACE' : 'INSERT'
    value_list = @data.values.join(',')
    start_str = "#{keyword} #{@data.ignore}INTO #{@data.into_table} "
    if !@data.fields.empty?
      field_list = @data.fields.join(',')
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
    having_clause = @data.having.empty? ? '' : " HAVING #{@data.having.join(' AND ')}"
    return " FROM #{build_table_list}#{join_clause}#{build_where_clause}#{group_clause}#{having_clause}#{order_clause}#{limit_clause}"
  end

  def build_set_clause
    set_exprs = []
    @data.fields.each_with_index do |field, index|
      set_exprs << "#{field} = #{@data.values[index]}"
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

  def build_join_clause
    if @data.joins.empty?
      return ''
    else
      return ' ' + @data.joins.map {|ary| ary.join(' ')}.uniq.join(' ')
    end
  end

  def build_where_clause
    return @data.wheres.empty? ? '' : " WHERE #{@data.wheres.join(' AND ')}"
  end
end

end
