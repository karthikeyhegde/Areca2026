class ItemService
  attr_accessor :params, :user, :message, :sort_column, :sort_order, :page_size, :searchable_columns
  ItemSum = Struct.new(:on_date, :stock_sum, :txn_sum, :day_number, :eod_stock)

def initialize(params,user)
   @params= params
end

def self.daily_trans params
    
      
    params[:sdate] = 1.months.ago.strftime("%d-%m-%Y") if ( params[:sdate].blank? || (DateTime.parse(params[:sdate]) < '2021-01-01'.to_date) )
    params[:edate] = Date.today.to_s  if params[:edate].blank?

    if params[:item_id].to_i == 0
      params[:item_id] = 79  #Ultratec cement
    end  

    item_id =  params[:item_id]
   
    @item = Item.find(params[:item_id].to_i)
   
    sdate = DateTime.parse(params[:sdate]).strftime('%Y-%m-%d')  if (params.has_key?(:sdate) && !params[:sdate].blank?)
    edate = DateTime.parse(params[:edate]).strftime('%Y-%m-%d')  if (params.has_key?(:edate) && !params[:edate].blank?)


      date_str_arr = []
      date_str_arr << " on_date >= '#{sdate}' " if !sdate.blank?
      date_str_arr << " on_date <= '#{edate}' " if !edate.blank?
      date_str = date_str_arr.join(" and ") if !date_str_arr.blank?
      pre_stk = []
      pre_txn = []
      if !sdate.blank?
         pre_count_date = " on_date < '#{sdate}' and on_date >= '2021-01-01' " 
         pre_txn = TxnItem
        .select("SUM(IF(buyback = 1, (number * -1) , number)) as day_sum")
        .where("item_id = #{item_id} and (#{pre_count_date})")

        pre_stk = StockEntry
        .select("SUM(IF(is_return = 1, (numbers * -1) , numbers)) as day_sum")
        .where("item_id = #{item_id} and (#{pre_count_date}) ")
      end 
      pre_stk_sum = pre_stk.size > 0 ?  pre_stk[0]["day_sum"]:0
      pre_txn_sum = pre_txn.size > 0 ?  pre_txn[0]["day_sum"]:0

   

      @data_arr = []

      
      @pre_stock = pre_stk_sum + @item.starting_stock - pre_txn_sum

      @txn_items = TxnItem.select("on_date, SUM(IF(buyback = 1, (number * -1) , number)) as day_sum")
                   .where("item_id = #{item_id} and (#{date_str}) ")
                   .group("on_date").order("")

      @stk_items = StockEntry.select(" on_date, SUM(IF(is_return = 1, (numbers * -1) , numbers)) as day_sum")
                             .where("item_id = #{item_id} and (#{date_str}) ")
                             .group("on_date").order("on_date")
     
     stk_day_ct = 0
     txitm_day_ct = 0
      
     @txn_items.load
     @stk_items.load

     stk_mx_ct = @stk_items.size
     txitm_mx_ct = @txn_items.size

     running_stock = @pre_stock
     @total_in = 0
     @total_out = 0

     ct = 0
     txnitm_day_sum_hsh = {}
     @txn_items.each do |txn|
      Rails.logger.debug(" txnitem on date = #{txn.on_date}")
      txitm_sum = @txn_items[ct]["day_sum"]
      Rails.logger.debug(txitm_sum)
      ct += 1
      txnitm_day_sum_hsh[txn.on_date.to_s] = txitm_sum
      Rails.logger.debug(" TT HASH = > #{txnitm_day_sum_hsh}")
     end

     (sdate.to_date..edate.to_date).each do |day1|
      day = DateTime.parse(day1.to_s).strftime('%d-%m-%Y').to_date
          stk_sum  = 'nil'
          stk_numbers = 0
          txn_numbers = 0
           if( stk_day_ct < stk_mx_ct && @stk_items[stk_day_ct].on_date == day)
            stk_sum = @stk_items[stk_day_ct]["day_sum"]
            stk_day_ct += 1
            stk_numbers = stk_sum
            
           end

           txitm_sum = 'nil'
          # if( txitm_day_ct <  txitm_mx_ct && @txn_items[txitm_day_ct].on_date == day)
          #  txitm_sum = @txn_items[txitm_day_ct]["day_sum"]
          #  txitm_day_ct += 1
          #  txn_numbers = txitm_sum
          # end
           if txnitm_day_sum_hsh.has_key?(day.to_s) 
            txitm_sum = txnitm_day_sum_hsh[day.to_s]
            txn_numbers = txitm_sum
          end  
           @total_in += stk_numbers
           @total_out += txn_numbers
           daynum = stk_numbers - txn_numbers
           running_stock = running_stock + daynum 

           
           @data_arr << ItemSum.new(day, stk_sum, txitm_sum, daynum, running_stock)
          
      end
      @message = "Showing #{@data_arr.size} records #{params[:sdate]} to #{params[:edate]} "

      return @data_arr, @item, @total_in, @total_out, @message
  end    

end