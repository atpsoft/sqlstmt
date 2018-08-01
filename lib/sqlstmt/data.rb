module SqlStmtLib
extend self

SqlTable = Struct.new(:str, :name, :alias, :index)

SqlData = Struct.new(
  :stmt_type,
  :tables,
  :joins,
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
  self.tables = orig.tables.dup
  self.joins = orig.joins.dup
  self.wheres = orig.wheres.dup
  self.fields = orig.fields.dup
  self.values = orig.values.dup
  self.having = orig.having.dup
  self.rows = orig.rows.dup
end

end

end
