require_relative 'lib/serial_list' 
require_relative 'lib/list' 

l = List.new(SerialList.all_potential_serial_orders)
l.worksheet
