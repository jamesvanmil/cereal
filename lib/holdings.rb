=begin
  Create the database thusly:

  $ sqlite3 cereal.db
  sqlite> create table holdings ( resourcetype text, title text, issn text,eissn text, startdate text, enddate text, resource text, url text);
  sqlite> .separator ","
  sqlite> .import journal_holdings.csv holdings
  sqlite> .quit
=end

class Holdings < ActiveRecord::Base
  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: 'cereal.db'
  )

  def self.holdings_for(issns)
    @holdings = []
    issns.each { |issn| get_holdings(issn) }
    @holdings.uniq
  end

  def self.get_holdings(issn)
    Holdings.where(issn: issn).each do |h|
      @holdings << "#{h.startdate}-#{h.enddate} | #{h.resource}"
    end

    Holdings.where(eissn: issn).each do |h|
      @holdings << "#{h.startdate}-#{h.enddate} | #{h.resource}"
    end
  end
end
