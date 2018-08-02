require 'sqlstmt/mysql/check'
require 'sqlstmt/mysql/build'

class SqlStmt
  def to_s
    SqlStmtLib::MysqlChecker.new(@data).run
    return SqlStmtLib::MysqlBuilder.new(@data).build_stmt
  end
  alias_method :to_sql, :to_s
end
