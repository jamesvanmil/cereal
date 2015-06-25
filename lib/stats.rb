=begin
  Create the database thusly:

  $ sqlite3 cereal.db
  sqlite> create table stats ( title text, publisher text, platform text, issn text, eissn text, total text);
  sqlite> .separator "\t"
  sqlite> .import usage/JR1_master_2014.csv stats
  sqlite> .quit
=end
require 'active_record'

class Stats < ActiveRecord::Base
  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: 'cereal.db'
  )

  def self.usage_for(issns)
    @usage = []
    issns.each { |issn| get_usage(issn) }
    @usage.uniq
  end

  def self.get_usage(issn)
    Stats.where(issn: issn).each do |use|
      @usage << "#{use.platform}: #{use.total}"
    end

    Stats.where(eissn: issn).each do |use|
      @usage << "#{use.platform}: #{use.total}"
    end
  end
end
