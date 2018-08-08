require 'set'

module SqlStmtLib
extend self

FLAG_KEYWORDS = %i(distinct ignore replace straight_join with_rollup).freeze
SINGLE_VALUE_KEYWORDS = %i(group_by into limit order_by outfile).freeze

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

DATA_ARRAY_FIELDS = %i(tables joins wheres get_fields set_fields set_values having tables_to_delete).freeze

SqlData = Struct.new(
  :stmt_type,
  :tables,
  :joins,

  # set of all table names and aliases
  # this includes ones added by a join
  :table_ids,

  :wheres,
  :where_behavior,
  :get_fields,
  :set_fields,
  :set_values,
  :group_by,
  :order_by,
  :limit,
  :having,
  :into,
  :tables_to_delete,
  :distinct,
  :straight_join,
  :replace,
  :ignore,
  :outfile,
  :with_rollup,
) do
def initialize
  self.table_ids = Set.new
  self.where_behavior = :require
  DATA_ARRAY_FIELDS.each do |field|
    self[field] = []
  end
end

def initialize_copy(orig)
  # without this call to super, any field that we aren't dup'ing here won't be copied
  super
  DATA_ARRAY_FIELDS.each do |field|
    self[field] = self[field].dup
  end
  self.table_ids = orig.table_ids.dup
end

end

end
