require 'sqlstmt/to_sql'

module ValueUtil
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
