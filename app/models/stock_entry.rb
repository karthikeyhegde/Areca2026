
class StockEntry < ActiveRecord::Base
  include BaseUtils
  audited

    attr_accessor :diff, :itm_stk_was
    belongs_to :item
    belongs_to    :contact
    

    before_save :calc_entry_stock
 #   after_save  :calc_item_current_stock
 #   after_update :update_calc_stock
 #   before_update :validate_intigrity
 #   after_destroy :destroy_stock_update
  
   def validate_intigrity
     if self.updated_at_was != self.updated_at
       raise 'Stock Entry was altered by other before your updation, Please reload the page and try again.'
     end
     self.updated_at = nil
   end


    def name_subname
      return (contact.blank? ? "" : contact.name_subname)
    end  

    
    def calc_item_current_stock
      se_numbers =  (is_return == 1? (self.numbers * -1) : self.numbers)
   	  self.item.current_stock = self.item.current_stock + se_numbers
   	  self.item.save!
    end

    def calc_entry_stock
       itm_stk_was = self.item_stock
       se_numbers =  (is_return == 1? (self.numbers * -1) : self.numbers)	
   	   self.item_stock = self.item.current_stock + se_numbers	   
    end	

    def update_calc_stock  
        se_numbers =  (is_return == 1? (self.numbers * -1) : self.numbers)
        p " SE Numbers - #{se_numbers}"
	      se_numbers_was =  (self.is_return_was == 1? (self.numbers_was * -1) : self.numbers_was) 
        p " SE Numbers WAS - #{se_numbers_was}"
        diff = se_numbers.to_i - se_numbers_was.to_i
        p " diff - #{diff}"
	   	  stock_update diff  if diff != 0
    end	

    def destroy_stock_update
      stock_upadate(self.numbers * -1)
    end  

    def stock_upadate diff
	    self.item.current_stock = self.item.current_stock + diff
   	  self.item.save!
   	  mysql_date = Utility.mysql_date on_date 
      sql =  "  UPDATE stock_entries set item_stock =  item_stock + #{diff} "
      sql << " where item_id = #{self.item_id} and ( on_date > '#{mysql_date}' OR (on_date = '#{mysql_date}' and created_at > '#{self.created_at}' ))"
      p " sql updatin- #{sql}"
      ActiveRecord::Base.connection.execute(sql)
    end	

    def self.total stockentries
      total = 0
      stockentries.each{|se| total += (se.is_return == 1? (se.numbers * -1) : se.numbers)}
      return total
    end

    def self.get_list p_hsh
      from_date = p_hsh["from_date"]
      to_date = p_hsh["to_date"] 
      contact_id = p_hsh["contact_id"]
      item_id = p_hsh["item_id"]
      site_id = p_hsh["site_id"]
      @sort_column = 'on_date'
      @sort_order = "DESC"
            
      f_date =  from_date.blank? ? '' : DateTime.parse(from_date).strftime('%Y-%m-%d %H:%M')  
      t_date =  to_date.blank?  ?  '' : DateTime.parse(to_date).strftime('%Y-%m-%d %H:%M') 
      
      sql = " 1 = 1 "
      sql << " and contact_id = #{contact_id.to_i} " if contact_id.to_i != 0
      sql << " and site_id = #{site_id.to_i} " if site_id.to_i != 0
      sql << " and item_id = #{item_id.to_i} " if item_id.to_i != 0
      sql << " and on_date >=  '#{f_date}' " if !f_date.blank?
      sql << " and on_date <= '#{t_date}' "  if !t_date.blank?
      StockEntry.includes(:contact,:item).where(sql).order(Arel.sql("#{@sort_column} #{@sort_order}, created_at DESC ") )

    end 




end	