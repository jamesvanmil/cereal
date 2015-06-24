require 'bundler/setup'
require 'active_sierra_models'
require 'active_record'
require 'axlsx'
require 'yaml'

class List

  def initialize(orders)
    @order_views = orders
    @holdings = Holdings
    @usage = Stats
    @selectors_by_fund = YAML.load(File.read("config/script_configuration.yml"))["selectors_by_fund"]
  end

  def worksheet
    Axlsx::Package.new do |p|
      p.use_shared_strings = true ## This supports line breaks, per discussion here: https://github.com/randym/axlsx/issues/252
      p.workbook.add_worksheet(name: "Serial_orders") do |sheet|
        add_header(sheet)
        add_rows(sheet)
      end
      p.serialize('example.xlsx')
    end
  end

  def add_header(sheet)
    sheet.add_row(spreadsheet_keys(@order_views.first))
  end

  def add_rows(sheet)
    @order_views.each do |order_view|
      next unless order_view.record_metadata.deletion_date_gmt.nil?
      sheet.add_row(spreadsheet_values(order_view))
    end
  end
  
  def spreadsheet_keys(order_view)
    spreadsheet_mapping(order_view).collect { |row| row.keys[0]}
  end

  def spreadsheet_values(order_view)
    spreadsheet_mapping(order_view).collect { |row| row.values[0] }
  end

  def spreadsheet_mapping(order_view)
    [ 
      { order_number: "o#{order_view.record_num}a" },
      { title: order_view.bib_view.title },
      { issn1: issn_scan(order_view)[0] },
      { issn2: issn_scan(order_view)[1] },
      { online_access: holdings_array(order_view).join("\n") },
      { usage: usage_array(order_view).join("\n") },
      { format: order_view.material_type_code },
      { fund: order_view.order_record_cmf.fund },
      { selector: selector_map(order_view.order_record_cmf.fund) },
      { vendor: order_view.vendor_record_code },
      { acqusition_type: order_view.acq_type_code },
      { split?: order_view.receiving_action_code == "p" },
      { "FY#{fiscal_year(0)}".to_s => payment_total_for_fiscal_year(0, order_view) },
      { "FY#{fiscal_year(1)}".to_s => payment_total_for_fiscal_year(1, order_view) },
      { "FY#{fiscal_year(2)}".to_s => payment_total_for_fiscal_year(2, order_view) },
      { "FY#{fiscal_year(3)}".to_s => payment_total_for_fiscal_year(3, order_view) },
      { "FY#{fiscal_year(4)}".to_s => payment_total_for_fiscal_year(4, order_view) }
    ]
  end

  def selector_map(fund)
    @selectors_by_fund[fund]
  end

  def issn_scan(order_view) 
    issn_marc_field = order_view.bib_view.varfield_views.marc_tag("022")
    return [ nil , nil ] if issn_marc_field.empty?
    issns = issn_marc_field.first.field_content.scan(/\d\d\d\d-\d\d\d[\dXx]/)
    return [issns[0], issns[1]] if issns.length == 2
    return [issns[0], nil ] if issns.length == 1
    [ nil , nil ]
  end

  def usage_array(order_view)
    usage_info = []
    issn_scan(order_view).each { |issn| next if issn.nil?;  usage_info.concat(usage_for(issn)) }
    usage_info.uniq
  end
  
  def usage_for(issn)
    usage_text = []
    @usage.where(issn: issn).each do |use| 
      next if use.nil?
      usage_text.push("#{use.publisher}-#{use.platform} | #{use.total}")
    end
    @usage.where(eissn: issn).each do |use|
      next if use.nil?
      usage_text.push("#{use.publisher}-#{use.platform} | #{use.total}")
    end
    usage_text
  end

  def holdings_array(order_view)
    title_holdings = []
    issn_scan(order_view).each { |issn| next if issn.nil?;  title_holdings.concat(holdings_for(issn)) }
    title_holdings.uniq
  end

  def holdings_for(issn)
    holdings_text = []
    @holdings.where(issn: issn).each do |holding| 
      next if holding.nil?
      holdings_text.push("#{holding.startdate}-#{holding.enddate} | #{holding.resource}")
    end
    @holdings.where(eissn: issn).each do |holding|
      next if holding.nil?
      holdings_text.push("#{holding.startdate}-#{holding.enddate} | #{holding.resource}")
    end
    holdings_text
  end

  def fiscal_year(offset)
    ## offset retrieves previous fiscal years
    todays_month = Date.today.month
    todays_year = Date.today.year - offset
    return todays_year unless todays_month > 6
    return today_year + 1
  end

  def payment_total_for_fiscal_year(offset, order_view)
    year = fiscal_year(offset)
    fiscal_year_begin = Date.new(year - 1,7,1)
    fiscal_year_end = Date.new(year,6,30)
    payment_records = order_view.order_record_paids.where(paid_date_gmt: fiscal_year_begin..fiscal_year_end)
    (payment_records.collect { |payment| payment.paid_amount }).reduce(:+)
  end
end

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
    :adapter => "sqlite3",
    :database  => "cereal.db"
  )
end

=begin
  Create the database thusly:

  $ sqlite3 cereal.db
  sqlite> create table stats ( title text, publisher text, platform text, issn text, eissn text, total text);
  sqlite> .separator "\t"
  sqlite> .import usage/JR1_master_2014.csv stats
  sqlite> .quit
=end

class Stats < ActiveRecord::Base
  ActiveRecord::Base.establish_connection(
    :adapter => "sqlite3",
    :database  => "cereal.db"
  )
end
