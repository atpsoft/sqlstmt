require 'set'

module SqlStmtLib
extend self

FLAG_KEYWORDS = %i(distinct ignore replace straight_join with_rollup).freeze
SINGLE_VALUE_KEYWORDS = %i(group_by into limit offset order_by outfile).freeze
MULTI_VALUE_KEYWORDS = %i(get having where).freeze

# :str is the full original string specifying the table, like 'frog f' or 'frog AS f' or 'frog'
# :name is the full name of the table
# :alias is the alias specified for the table, or if none is specified, it's the same as :name
#   this may be the wrong approach, but for now at least, it seems the most intuitive/useful option
# :index is used to specify a "USE INDEX" clause
SqlTable = Struct.new(:str, :name, :alias, :index)

# kwstr is the keyword string, like 'JOIN' or 'LEFT JOIN'
# table is a SqlTable object, representing the table being joined to
# on_expr is the ON expression for the join
SqlJoin = Struct.new(:kwstr, :table, :on_expr)

# :table_ids is a set of all table names and aliases, including ones added by a join
SPECIAL_DATA_FIELDS = %i(stmt_type table_ids where_behavior).freeze
ARRAY_DATA_FIELDS = MULTI_VALUE_KEYWORDS.map {|keyword| "#{keyword}s".to_sym} + %i(tables joins set_fields set_values tables_to_delete).freeze

# calling uniq on this in case some fields end up in multiple categories
ALL_DATA_FIELDS = (FLAG_KEYWORDS + SINGLE_VALUE_KEYWORDS + ARRAY_DATA_FIELDS + SPECIAL_DATA_FIELDS).uniq

SqlData = Struct.new(*ALL_DATA_FIELDS) do
def initialize
  self.table_ids = Set.new
  self.where_behavior = :require
  ARRAY_DATA_FIELDS.each do |field|
    self[field] = []
  end
end

def initialize_copy(orig)
  # without this call to super, any field that we aren't dup'ing here won't be copied
  super
  ARRAY_DATA_FIELDS.each do |field|
    self[field] = self[field].dup
  end
  self.table_ids = orig.table_ids.dup
end

end

end
