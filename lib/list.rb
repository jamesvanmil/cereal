class List
  require_relative 'holdings'
  require_relative 'stats'
  
  require 'bundler/setup'
  require 'active_sierra_models'
  require 'axlsx'

  def initialize(orders)
    @order_views = orders
    @holdings = Holdings
    @usage = Stats
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
    {
    "aaaaa" => "Admin", "none" => "Admin", "sbind" => "Admin", "scdnt" => "Admin", "scdrm" => "Admin", "scont" => "Admin", "sghum" => "Admin", "slanf" => "Admin", "smemb" => "Admin", "sp&pa" => "Admin", "ubind" => "Admin", "uchin" => "Admin", "ucont" => "Admin", "ughum" => "Admin", "ugsos" => "Admin", "ushlr" => "Admin", "vnbio" => "Admin", "wcarl" => "Admin", "wrref" => "Admin", "xcjgs" => "Admin", "ynedt" => "Admin", "sfren" => "Arlene", "sgper" => "Arlene", "slang" => "Arlene", "sprof" => "Arlene", "sspan" => "Arlene", "ufren" => "Arlene", "uprof" => "Arlene", "uspan" => "Arlene", "vfaux" => "Arlene", "yhfru" => "Arlene", "ysivt" => "Arlene", "ssocw" => "Charlie", "scrce" => "Cheryl", "scrcl" => "Cheryl", "seduc" => "Cheryl", "ucrce" => "Cheryl", "ucrcl" => "Cheryl", "ueduc" => "Cheryl", "vcrcl" => "Cheryl", "callh" => "Clermont", "cbhum" => "Clermont", "cbind" => "Clermont", "cbiol" => "Clermont", "cblaw" => "Clermont", "cbnur" => "Clermont", "cbref" => "Clermont", "cbus" => "Clermont", "ccat" => "Clermont", "cchem" => "Clermont", "ccom" => "Clermont", "ceduc" => "Clermont", "ceng" => "Clermont", "cenvi" => "Clermont", "cgen" => "Clermont", "cgref" => "Clermont", "chist" => "Clermont", "claw" => "Clermont", "clib" => "Clermont", "cmfm" => "Clermont", "cnhum" => "Clermont", "conl" => "Clermont", "cper" => "Clermont", "cser" => "Clermont", "csoc" => "Clermont", "csref" => "Clermont", "slref" => "Debbie", "ulref" => "Debbie", "senvi" => "Holly", "sgeog" => "Holly", "sgeol" => "Holly", "smath" => "Holly", "sphys" => "Holly", "ugeol" => "Holly", "umath" => "Holly", "uphys" => "Holly", "ybalu" => "Holly", "yrich" => "Holly", "ysebu" => "Jacquie", "yseci" => "Jacquie", "ysehi" => "Jacquie", "ysems" => "Jacquie", "ysemt" => "Jacquie", "ysemu" => "Jacquie", "ysepi" => "Jacquie", "ysmgs" => "Jacquie", "ysmgu" => "Jacquie", "sdaap" => "Jen", "udaap" => "Jen", "xcars" => "Jen", "yells" => "Jim Cummins", "nbiol" => "Leslie", "nchem" => "Ted", "sbiol" => "Leslie", "schem" => "Ted", "ubiol" => "Leslie", "uchem" => "Ted", "vbiol" => "Leslie", "yoess" => "Ted", "yoesu" => "Ted", "sarch" => "Kevin", "uarch" => "Kevin", "mbdh" => "Law", "mcarm" => "Law", "mcnll" => "Law", "mcnp" => "Law", "mcont" => "Law", "mdata" => "Law", "mdins" => "Law", "mdorn" => "Law", "mform" => "Law", "mkond" => "Law", "mmorg" => "Law", "mnbav" => "Law", "mnbf" => "Law", "mnbg" => "Law", "mnbks" => "Law", "mnipp" => "Law", "morgg" => "Law", "morgs" => "Law", "mprof" => "Law", "msego" => "Law", "mspec" => "Law", "mwald" => "Law", "mwarm" => "Law", "halhm" => "Leslie", "halhs" => "Leslie", "hhbea" => "Leslie", "hhda" => "Leslie", "hhgbd" => "Leslie", "hhgif" => "Leslie", "hhgm" => "Leslie", "hhgmc" => "Leslie", "hhgms" => "Leslie", "hhgmw" => "Leslie", "hhgpa" => "Leslie", "hhgpc" => "Leslie", "hhgpd" => "Leslie", "hhgpe" => "Leslie", "hhgpe" => "Leslie", "hhgpm" => "Leslie", "hhgpr" => "Leslie", "hhgpr" => "Leslie", "hhgps" => "Leslie", "hhgps" => "Leslie", "hhgpv" => "Leslie", "hhgpw" => "Leslie", "hhhm" => "Leslie", "hhhoa" => "Leslie", "hhhra" => "Leslie", "hhhrm" => "Leslie", "hhill" => "Leslie", "hhla" => "Leslie", "hhlm" => "Leslie", "hhlos" => "Leslie", "hhrcm" => "Leslie", "hhrcs" => "Leslie", "hngc" => "Leslie", "hngd" => "Leslie", "hnge" => "Leslie", "hngs" => "Leslie", "hnles" => "Leslie", "hphd" => "Leslie", "hphs" => "Leslie", "hrepl" => "Leslie", "hygs" => "Leslie", "hyss" => "Leslie", "sdocs" => "Lorna", "udocs" => "Lorna", "ynblt" => "Lorna", "yndcu" => "Lorna", "sccm" => "Mark", "uccm" => "Mark", "vccbi" => "Mark", "vccfi" => "Mark", "vcchi" => "Mark", "vccm" => "Mark", "vcnfi" => "Mark", "xccms" => "Mark", "xccmu" => "Mark", "yagmu" => "Mark", "yclcu" => "Mark", "ngerm" => "Olya", "sgerm" => "Olya", "sslav" => "Olya", "ugerm" => "Olya", "ulang" => "Olya", "uslav" => "Olya", "vgehi" => "Olya", "yhgeu" => "Olya", "scrmj" => "Randy", "shums" => "Randy", "spsyc" => "Randy", "ssoci" => "Randy", "upsyc" => "Randy", "usoc" => "Randy", "scoma" => "Rosemary", "sengl" => "Rosemary", "sling" => "Rosemary", "sthtr" => "Rosemary", "ucoma" => "Rosemary", "uengl" => "Rosemary", "vengl" => "Rosemary", "safro" => "Sally", "santh" => "Sally", "sasia" => "Sally", "shist" => "Sally", "sjuda" => "Sally", "slata" => "Sally", "sphil" => "Sally", "spols" => "Sally", "swoms" => "Sally", "uanth" => "Sally", "uasia" => "Sally", "uhist" => "Sally", "ujuda" => "Sally", "uphil" => "Sally", "upols" => "Sally", "uwoms" => "Sally", "vjuda" => "Sally", "vlabs" => "Sally", "yflou" => "Sally", "ylecs" => "Sally", "ylecu" => "Sally", "ystru" => "Sally", "yucsu" => "Sally", "yurbs" => "Sally", "yurbu" => "Sally", "ncomp" => "Ted", "scas" => "Ted", "scomp" => "Ted", "sengr" => "Ted", "ucas" => "Ted", "uengr" => "Ted", "uucol" => "Ted", "xvals" => "Ted", "xvalt" => "Ted", "xvalu" => "Ted", "xvenu" => "Ted", "yarmu" => "Ted", "ybots" => "Ted", "ybotu" => "Ted", "ydays" => "Ted", "yters" => "Ted", "yteru" => "Ted", "yucmu" => "Ted", "rallh" => "UCBA", "rbuse" => "UCBA", "rengl" => "UCBA", "rghs" => "UCBA", "rmic" => "UCBA", "rmul" => "UCBA", "rnurs" => "UCBA", "rser" => "UCBA", "rwc" => "UCBA", "sbusa" => "Wahib", "secon" => "Wahib", "ubusa" => "Wahib", "vbaji" => "Wahib", "vbusa" => "Wahib", "vecji" => "Wahib"
    }[fund]
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
    issn_scan(order_view).each { |issn| next if issn.nil?;  title_holdings.concat(usage_for(issn)) }
    usage_info.uniq
  end
  
  def usage_for(issn)
    usage_text = []
    @usage.where(issn: issn).each do |usage| 
      next if usage.nil?
      usage_text.push("#{usage.publisher}-#{usage.platform} | #{usage.total}")
    end
    @usage.where(eissn: issn).each do |usage|
      next if usage.nil?
      usage_text.push("#{usage.publisher}-#{usage.platform} | #{usage.total}")
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
