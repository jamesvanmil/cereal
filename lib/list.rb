require 'bundler/setup'
require 'axlsx'
require 'byebug'

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
      prepare_worksheets(p)
      add_header
      add_rows
      p.serialize('example.xlsx')
    end
  end

  def prepare_worksheets(p)
    @master_worksheet = p.workbook.add_worksheet(name: 'master')
    @selector_worksheets = {}
    selectors.collect do |selector|
      @selector_worksheets[selector] = p.workbook.add_worksheet(name: selector)
    end
  end

  def add_header
    @master_worksheet << spreadsheet_keys(@titles.first)
    @selector_worksheets.values.each do |sheet|
      sheet << spreadsheet_keys(@titles.first)
    end
  end

  def add_rows(index = 2)
    @titles.each do |title|
      row = prepare_row(title, index)
      @master_worksheet << row
      unless selector_name(row).nil?
        row = row_index_for_selector(row, selector_worksheet_length(selector_name(row)))
        @selector_worksheets[selector_name(row)] << row 
      end
      index += 1
    end
  end

  def selector_name(row)
    row[5]
  end

  def prepare_row(title, index)
    spreadsheet_values(title, index)
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

  def selectors
    YAML.load(
      File.read('config/script_configuration.yml')
      )['selectors_by_fund'].values.uniq
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

  def fix_row_index_for_selector(row, index)
    row.cells[14].sub!(/#{index}/,  )
  end

  def selector_worksheet_length(name)
    @selector_worksheets[name].rows.count + 1
  end

  def row_index_for_selector(row, index)
    row[14].gsub!(%r{\d+}, "#{index}")
    row
  end
end
