=begin

  Create the database thusly:

  $ sqlite3 stats.db
  sqlite> create table stats ( title text, publisher text, platform text, issn text, eissn text, total text);
  sqlite> .headers on
  sqlite> .separator "\t"
  sqlite> .import usage/JR1_master_2014.csv stats

=end

class Stats < ActiveRecord::Base
  require 'active_record'

  ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :database  => "stats.db"
  )
end
