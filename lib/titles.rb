=begin
  Create the database thusly:

  $ sqlite3 cereal.db
  sqlite> create table titles ( id integer primary key, order_number text, title text, issn1 text, issn2 text, online_access text, usage text, format text, fund text, vendor text, acqusition_type, text, split text, fyminus0 text, fyminus1 text,  fyminus2 text,  fyminus3 text,  fyminus4 text )
  sqlite> .quit
=end

require_relative 'holdings'
require_relative 'stats'

class Titles < ActiveRecord::Base
  ActiveRecord::Base.establish_connection(
    adapter: 'sqlite3',
    database: 'cereal.db'
  )

  def assign_base_fields(order_view)
    @bib_view ||= order_view.bib_view
    self.order_number = "o#{order_view.record_num}a"
    self.title = order_view.bib_view.title
    self.issn1 = issn_scan[0]
    self.issn2 = issn_scan[1]
    self.format = order_view.material_type_code
    self.fund = order_view.order_record_cmf.fund
    self.vendor = order_view.vendor_record_code
    self.acqusition_type = order_view.acq_type_code
    self.split = order_view.receiving_action_code == 'p'
    self.fyminus0 = payment_total_for_fiscal_year(0, order_view)
    self.fyminus1 = payment_total_for_fiscal_year(1, order_view)
    self.fyminus2 = payment_total_for_fiscal_year(2, order_view)
    self.fyminus3 = payment_total_for_fiscal_year(3, order_view)
    self.fyminus4 = payment_total_for_fiscal_year(4, order_view)
  end

  def assign_online_access
    holdings = Holdings.holdings_for(issns)
    self.online_access = holdings.join("\n")  unless holdings.nil?
  end

  def assign_usage
    usage = Stats.usage_for(issns)
    self.usage = usage.join("\n")
  end

  def issns
    [self.issn1, self.issn2]
  end

  private

  def issn_scan
    issn_marc_field = @bib_view.varfield_views.marc_tag('022')
    return [nil, nil] if issn_marc_field.empty?
    issns = issn_marc_field.first.field_content.scan(/\d\d\d\d-\d\d\d[\dXx]/)
    return [issns[0], issns[1]] if issns.length == 2
    return [issns[0], nil] if issns.length == 1
    [nil, nil]
  end

  def payment_total_for_fiscal_year(offset, order_view)
    year = fiscal_year(offset)
    fiscal_year_begin = Date.new(year - 1, 7, 1)
    fiscal_year_end = Date.new(year, 6, 30)
    payment_records = order_view.order_record_paids.where(
      paid_date_gmt: fiscal_year_begin..fiscal_year_end)
    (payment_records.collect { |payment| payment.paid_amount }).reduce(:+)
  end

  def fiscal_year(offset)
    ## offset retrieves previous fiscal years
    todays_month = Date.today.month
    todays_year = Date.today.year - offset
    return todays_year unless todays_month > 6
    today_year + 1
  end
end
