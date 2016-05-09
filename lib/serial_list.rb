module SerialList
  require 'bundler/setup'
  require 'active_sierra_models'

  def self.all_potential_serial_orders
    (serial_orders_by_status_code + (serial_orders_by_funds)).uniq
  end

  def self.serial_orders_by_status_code
    OrderView.where(
      order_status_code: serial_status_codes,
      ocode1: jurisdiction_codes
    ).includes(:record_metadata).where(
      'record_metadata.deletion_date_gmt' => nil)
    .limit(10)
  end

  def self.codes_from_funds
    ## We're using these to look up 
    ## orders via OrderRecordCmf, 
    ## which needs the codes as 5-digit strings
    (FundMaster.where(
      code: all_fund_list
    ).collect { |f| '%05d' % f.code_num }).uniq
  end

  def self.serial_orders_by_funds
    ## This catches all the orders against 
    ## serial funds with a monograph status code
    OrderView.joins(:order_record_cmf).where(
      order_record_cmf: { fund_code: codes_from_funds }
    ).where(
      order_status_code: monograph_status_codes,
      ocode1: jurisdiction_codes
    ).includes(:record_metadata).where(
      'record_metadata.deletion_date_gmt' => nil)
    .limit(10)
  end

  def self.serial_status_codes
    %w(c f d e g)
  end

  def self.monograph_status_codes
    %w(a o q)
  end

  def self.jurisdiction_codes
    %w(u h)
  end

  def self.all_fund_list
    (YAML::load(File.open('config/script_configuration.yml')))['serial_funds']
  end
end
