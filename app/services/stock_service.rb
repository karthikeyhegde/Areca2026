class StockService
  attr_accessor :params, :user, :message, :sort_column, :sort_order, :page_size, :searchable_columns
  def initialize(params,user)
     @params= params
     @user= user
     @serachable_columns = {}
  end

  def search_stockentries params
  	 searchsql = SearchUtility.stk_search_sql params
  	 StockEntry.where(searchsql).order(Arel.sql(" ondate DESC, created_at DESC ") )
  end	

  def self.update_se params
      se = StockEntry.new
      ActiveRecord::Base.transaction do
          se =  StockEntry.find(params[:id])
          if params[:stock_entry][:updated_at] != se.updated_at.to_s
            raise 'Error! :Stock Entry '+se.id.to_s+' was updated by other, Please reload the update page and try again.'
          end
          stk_num_was = se.numbers
          is_return_was = se.is_return

          se.update(params[:stock_entry])
          se =  StockEntry.find(params[:id])
          se_numbers =  (se.is_return == 1? (se.numbers * -1) : se.numbers)
          se_numbers_was =  (is_return_was == 1? (stk_num_was * -1) : stk_num_was) 
          diff = se_numbers.to_i - se_numbers_was.to_i
          if( diff != 0)
            item = se.item

            item.with_lock do
                item.current_stock = item.current_stock + diff
                item.save!
            end
            mysql_date = Utility.mysql_date se.on_date 
            sql_set =  "  UPDATE stock_entries set item_stock =  item_stock + #{diff} "
            sql_select = " SELECT * from stock_entries "
            sql_conditions = " where item_id = #{se.item_id} and ( on_date > '#{mysql_date}' OR (on_date = '#{mysql_date}' and created_at > '#{se.created_at}' ))"
            sql_lock = " FOR UPDATE"
            slect_with_lock = sql_select+sql_conditions+sql_lock
            update_sql = sql_set+sql_conditions
            ActiveRecord::Base.connection.execute(slect_with_lock)
            ActiveRecord::Base.connection.execute(update_sql)
          end  
      end
      return se
  end

  def self.add_se params
    @stock_entry = StockEntry.new(params[:stock_entry])
    ActiveRecord::Base.transaction do
    
      se_numbers =  (@stock_entry.is_return == 1? (@stock_entry.numbers * -1) : @stock_entry.numbers)
      new_item_stock = @stock_entry.item.current_stock + se_numbers
      item_to_update = Item.lock("FOR UPDATE").find(@stock_entry.item_id)
      @stock_entry.item_stock = new_item_stock
      @stock_entry.save!
      item_to_update.current_stock = new_item_stock
      item_to_update.save!
    end
    return @stock_entry

  end

  def self.delete_se id
    se = StockEntry.find(id.to_i)
    ActiveRecord::Base.transaction do
      item = se.item 
      se_numbers =  (se.is_return == 1? (se.numbers * -1) : se.numbers)
      mysql_date = Utility.mysql_date se.on_date 

      sql_set =  " UPDATE stock_entries set item_stock =  item_stock - (#{se_numbers}) "
      sql_select = " SELECT * from stock_entries "
      sql_conditions = " where item_id = #{se.item_id} and ( on_date > '#{mysql_date}' OR (on_date = '#{mysql_date}' and created_at > '#{se.created_at}' ))"
      sql_lock = " FOR UPDATE"
      slect_with_lock = sql_select+sql_conditions+sql_lock
      update_sql = sql_set+sql_conditions

      item.with_lock do
        item.current_stock = item.current_stock - se_numbers
        item.save!
      end

      ActiveRecord::Base.connection.execute(slect_with_lock)
      ActiveRecord::Base.connection.execute(update_sql)
    end  
    se.destroy!
  end

  def self.recalculate_stock item_id
    @item = Item.find(item_id)
    @default_date = MySetting.find_by_name('stock_start_date')

    mysql_date = Utility.mysql_date @default_date.value
    stockentries = StockEntry.where("on_date >=  '#{mysql_date}' and item_id = #{item_id} ").order("on_date,created_at")
    db = ActiveRecord::Base.connection
    
    stock_count = @item.starting_stock
    itm_stock = 0
    stk_numbers = 0
    stock_added_count = stock_count
    item_start_date = @item.start_date.nil? ? mysql_date : @item.start_date
    stockentries.each{|se|

      stock_added_count = stock_added_count + se.numbers
      
       Rails.logger.debug(" START ********* START  #{se.id} #{se.item_id} #{se.on_date}")
       Rails.logger.debug(" #{@item.start_date} #{se.on_date} #{Utility.mysql_date se.on_date}")
      mysql_on_date = Utility.mysql_date se.on_date
      Rails.logger.debug(" #{mysql_on_date}")
      ondatestr_txn = " on_date >=  '#{item_start_date}' and (on_date <= '#{mysql_on_date}' ) "
      sql ="select SUM(IF(buyback = 1, (number * -1) , number)) as totalnumbers  from txn_items where  item_id = #{item_id} and  "+ondatestr_txn
      txitems_res = db.execute(sql) 
      txn_numbers = ( txitems_res.first[0].nil? ? 0 : txitems_res.first[0])
      
      #for Stock Entry - include current SE also for calculation
      ondatestr_stk = " on_date >=  '#{item_start_date}' and (on_date <= '#{mysql_on_date}' )"
      sql_se = "SELECT SUM(IF(is_return = 1, (numbers * -1) , numbers)) from stock_entries WHERE item_id = #{item_id} and "+ondatestr_stk
      
      stk_res = db.execute(sql_se) 
      stk_numbers = ( stk_res.first[0].nil? ? 0 : stk_res.first[0])
      
      itm_stock = stk_numbers + stock_count - (txn_numbers)
      se.item_stock = itm_stock       
      se.save!

      p "--------&&&&--------"
      p "******-------------------------START-----------------------------*****"
      p se
      p " txn res -- #{txitems_res.first}"
      p " stk res -- #{stk_res.first}"
      p " itm_stock = stk_numbers + stock_count - (txn_numbers) --||--  #{itm_stock} = #{stk_numbers} + #{stock_count} - (#{txn_numbers}) "
      p itm_stock
      p "******--------------------------END-------   -----------------------*****"

    }
    sql_all_txn = "select SUM(IF(buyback = 1, (number * -1) , number)) as totalnumbers  from txn_items where  item_id = #{item_id} and on_date >= '#{item_start_date}'  "
    txitems_res = db.execute(sql_all_txn)
    txn_numbers = ( txitems_res.first[0].nil? ? 0 : txitems_res.first[0])

    @item.current_stock = stk_numbers - txn_numbers + @item.starting_stock
    Rails.logger.debug( " current_stock = stk_numbers - txn_numbers + @item.starting_stock--||  #{stk_numbers} - #{txn_numbers} + #{@item.starting_stock}")
    @item.save!
  end

  def self.recalculate_stock_all
     Item.all.each{|itm|
       recalculate_stock itm.id
    }
  end

  def self.recalculate_stock_with_itmes item_id_arr
    item_id_arr.each{|itm_id|
      recalculate_stock itm_id
    }
  end  


end  