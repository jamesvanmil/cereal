require_relative 'serial_list' 
require_relative 'list' 

l = List.new(SerialList.all_potential_serial_orders)
l.worksheet
