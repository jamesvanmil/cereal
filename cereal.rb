require_relative 'lib/serial_list'
require_relative 'lib/list'
require_relative 'lib/titles'

Titles.destroy_all

SerialList.all_potential_serial_orders.each do |order_view|
  new_title = Titles.new
  new_title.assign_base_fields(order_view)
  new_title.assign_online_access
  new_title.assign_usage
  new_title.save
end

list = List.new(Titles.all)
list.worksheet; nil
