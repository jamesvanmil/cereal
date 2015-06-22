=begin

  Create the database thusly:

  $ sqlite3 holdings.db
  sqlite> create table holdings ( resourcetype text, title text, issn text,eissn text, startdate text, enddate text, resource text, url text);
  sqlite> .separator ","
  sqlite> .import journal_holdings.csv holdings

=end

class Holdings < ActiveRecord::Base
  require 'active_record'

  ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :database  => "holdings.db"
  )
end
