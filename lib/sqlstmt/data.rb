require 'set'

module SqlStmtLib
extend self

SqlTable = Struct.new(:str, :index)

SqlData = Struct.new(
  :stmt_type,
  :tables,
  :joins,

  # set of all table names and aliases
  # this includes ones added by a join
  :table_ids,

  :wheres,
  :where_behavior,
  :fields,
  :values,
  :group_by,
  :order_by,
  :limit,
  :having,
  :into_table,
  :rows,
  :tables_to_delete,
  :distinct,
  :straight_join,
  :replace,
  :ignore,
  :outfile,
  :with_rollup,
  :called_get,
) do
def initialize
  self.tables = []
  self.joins = []
  self.table_ids = Set.new
  self.wheres = []
  self.where_behavior = :require
  self.fields = []
  self.values = []
  self.having = []
  self.rows = []
  self.tables_to_delete = []
  self.ignore = ''
  self.outfile = ''
  self.called_get = false
end

def initialize_copy(orig)
  # without this call to super, any field that we aren't dup'ing here won't be copied
  super
  self.tables = orig.tables.dup
  self.joins = orig.joins.dup
  self.table_ids = orig.table_ids.dup
  self.wheres = orig.wheres.dup
  self.fields = orig.fields.dup
  self.values = orig.values.dup
  self.having = orig.having.dup
  self.rows = orig.rows.dup
end

end

end
