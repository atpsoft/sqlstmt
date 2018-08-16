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

  def combine_parts(parts)
    parts.each do |str|
      str.strip!
    end
    parts.reject! do |str|
      str.nil? || str.empty?
    end
    return parts.join(' ')
  end

  def build_stmt_select
    parts = []
    parts << shared_select(@data.gets)
    if @data.outfile
      parts << "INTO OUTFILE #{@data.outfile}"
    end
    return combine_parts(parts)
  end

  def build_stmt_update
    parts = [
      'UPDATE',
      build_table_list,
      build_join_clause,
      'SET',
      build_set_clause,
      build_where_clause,
      simple_clause('LIMIT', @data.limit),
    ]
    return combine_parts(parts)
  end

  def build_stmt_insert
    parts = []
    if @data.replace
      parts << 'REPLACE'
    else
      parts << 'INSERT'
    end
    if @data.ignore
      parts << 'IGNORE'
    end
    parts << "INTO #{@data.into}"
    if !@data.set_fields.empty?
      field_list = @data.set_fields.join(',')
      parts << "(#{field_list})"
    end
    parts << shared_select(@data.set_values)
    return combine_parts(parts)
  end

  def build_stmt_delete
    parts = ['DELETE']
    if !@data.tables_to_delete.empty?
      parts << @data.tables_to_delete.join(',')
    end
    parts << build_from_clause
    return combine_parts(parts)
  end

  def shared_select(fields)
    parts = ['SELECT']
    if @data.straight_join
      parts << 'STRAIGHT_JOIN'
    end
    if @data.distinct
      parts << 'DISTINCT'
    end
    parts << fields.join(',')
    parts << build_from_clause
    return combine_parts(parts)
  end

  def build_from_clause
    parts = ['FROM']
    parts << build_table_list
    parts << build_join_clause
    parts << build_where_clause
    parts << simple_clause('GROUP BY', @data.group_by)
    if @data.with_rollup
      parts << 'WITH ROLLUP'
    end
    if !@data.havings.empty?
      parts << "HAVING #{@data.havings.join(' AND ')}"
    end
    parts << simple_clause('ORDER BY', @data.order_by)
    parts << simple_clause('LIMIT', @data.limit)
    return combine_parts(parts)
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
    return ' ' + @data.joins.map {|join| join_to_str(join)}.uniq.join(' ')
  end

  def build_where_clause
    return @data.wheres.empty? ? '' : " WHERE #{@data.wheres.join(' AND ')}"
  end
end

end
