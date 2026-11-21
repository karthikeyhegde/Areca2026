class ItemSum
  attr_accessor :on_date, :stock_sum, :txn_sum, :day_number, :eod_stock


  def initialize(on_date, stock_sum, txn_sum, day_number, eod_stock)
  	  @on_date = on_date
  	  @stock_sum = stock_sum
  	  @txn_sum = txn_sum
  	  @day_number = day_number
  	  @eod_stock = eod_stock
  end
end