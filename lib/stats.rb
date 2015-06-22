=begin

  Create the database thusly:

  $ sqlite3 stats.db
  sqlite> create table stats ( title text, publisher text, platform text, issn text, eissn text, total text);
  sqlite> .separator "\t"
  sqlite> .import usage/JR1_master_2014.csv stats
  sqlite> .quit

=end

require 'active_record'

class Stats < ActiveRecord::Base
  ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :database  => "stats.db"
  )
end
