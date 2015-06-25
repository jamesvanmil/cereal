require 'bundler/setup'
require 'axlsx'

require_relative 'titles'

class List
  def initialize(titles)
    @titles = titles
  end

  def worksheet
    Axlsx::Package.new do |p|
      ## This supports line breaks, per discussion here: 
      ## https://github.com/randym/axlsx/issues/252
      p.use_shared_strings = true
      p.workbook.add_worksheet(name: 'Serial_orders') do |sheet|
        add_header(sheet)
        add_rows(sheet)
      end
      p.serialize('example.xlsx')
    end
  end

  def add_header(sheet)
    sheet.add_row(spreadsheet_keys(@titles.first))
  end

  def add_rows(sheet, index = 2)
    @titles.each do |title|
      sheet.add_row(spreadsheet_values(title, index))
      index += 1
    end
  end

  def spreadsheet_keys(title)
    spreadsheet_mapping(title).collect { |row| row.keys[0] }
  end

  def spreadsheet_values(title, index)
    spreadsheet_mapping(title, index).collect { |row| row.values[0] }
  end

  def spreadsheet_mapping(title, index = nil)
    [
      { order_number: title.order_number }, #A
      { vendor: title.vendor }, #B
      { acqusition_type: mapped_acqusition_type(title.acqusition_type) }, #C
      { split: title.split }, #D
      { fund: title.fund }, #E
      { selector: selector_map(title.fund) }, #F
      { format: mapped_format(title.format) }, #G
      { title: title.title }, #H
      { issn1: title.issn1 }, #I
      { issn2: title.issn2 }, #J
      { notes: '' }, #K
      { online_access: title.online_access }, #L
      { usage: title.usage }, #M
      { cost_count: '' }, #N
      { cost_per_use: "=Q#{index}/N#{index}" }, #O
      { "FY#{fiscal_year(0)}".to_s => title.fyminus0 }, #P
      { "FY#{fiscal_year(1)}".to_s => title.fyminus1 }, #Q
      { "FY#{fiscal_year(2)}".to_s => title.fyminus2 }, #R
      { "FY#{fiscal_year(3)}".to_s => title.fyminus3 }, #S
      { "FY#{fiscal_year(4)}".to_s => title.fyminus4 } #T
    ]
  end

  def selector_map(fund)
    @selectors_by_fund ||= YAML.load(
      File.read('config/script_configuration.yml')
      )['selectors_by_fund']
    @selectors_by_fund[fund]
  end

  def mapped_format(code)
    case code
    when 'c' then 'CD/DVD'
    when 'e' then 'electronic'
    when 'f' then 'film'
    when 'g' then 'maps'
    when 'i' then 'realia'
    when 'i' then 'looseleaf'
    when 'm' then 'microfilm'
    when 'n' then 'newspaper'
    when 'p' then 'print+online'
    when 'q' then 'microfiche'
    when 'u' then 'print'
    when 'v' then 'video'
    when 'x' then 'mixed format'
    when 'w' then 'score'
    when 'z' then 'other'
    else code 
    end
  end

  def mapped_acqusition_type(code)
    case code
    when 'b' then 'prepaid'
    when 'c' then 'comes with'
    when 'g' then 'gift'
    when 'p' then 'purchase'
    else code 
    end
  end

  def fiscal_year(offset)
    ## offset retrieves previous fiscal years
    todays_month = Date.today.month
    todays_year = Date.today.year - offset
    return todays_year unless todays_month > 6
    today_year + 1
  end
end
