=begin

  Create the database thusly:

  $ sqlite3 holdings.db
  sqlite> create table holdings ( resourcetype text, title text, issn text,eissn text, startdate text, enddate text, resource text, url text);
  sqlite> .separator ","
  sqlite> .import journal_holdings.csv holdings

=end

require 'active_record'

class Holdings < ActiveRecord::Base
  ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :database  => "holdings.db"
  )
end
