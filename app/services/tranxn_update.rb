class TranxnUpdate
	attr_accessor :params, :user
	def initialize(params,user)
       @params= params
       @user= user
    end

  def do_update
   	  @trans = Tranxn.find(params[:id])
      Rails.logger.debug(" TXN ID = #{@trans.id}")
	    txn_ids = []
	    params[:txn_items].each{|key,val|
	    	id = key.to_i
        txn_ids << id
        if id.to_i < 1000 
	         ti = TxnItem.new(val)
	         ti.created_by = @user.id
           ti.item_name = Item.find(val[:item_id].to_i).name
           ti.transaction_id =  @trans.id
           ti.contact_id = @trans.contact_id
           ti.on_date = @trans.on_date
           price_tax_total_adjestments ti

	         ti.calculate_amount
	         ti.save!
           ti.buyback = params[:tranxn][:byback].to_i
	         @trans.txn_items <<   ti
	         txn_ids << ti.id
        else
           old_txi = TxnItem.find(id)  
           new_txi = TxnItem.new(val)
           first_match = first_match_detected(old_txi, new_txi)
	         if first_match
            #old_txi.item_id != val[:item_id].to_i || old_txi.price != val[:price].to_f || old_txi.number != val[:number].to_i ||  params[:tranxn][:buyback].to_i != @trans.buyback.to_i
	          price_tax_total_adjestments new_txi

             val[:updated_by] = @user.id             
	           val[:amount] = new_txi.calculate_amount
             val[:price_before_tax] = new_txi.price_before_tax 
             val[:number_price_tax_total] = new_txi.number_price_tax_total
	           val[:buyback_was] = @trans.buyback
	           val[:buyback] = params[:tranxn][:buyback].to_i
	           old_txi.update(val)          
	         end          
        end 

      } unless  params[:txn_items].blank?

      txnitms = @trans.txn_items

      txnitms.each{|txn|
        txn.destroy  if !txn_ids.include?(txn.id)
      }
     
      site_param = params[:txn][:site]

      if !site_param.blank? and  site_param.length > 3
        site = Site.find_by_name(site_param)
        if site == nil
          site = Site.new
          site.name = site_param
          site.save!
       end 
       params[:tranxn][:site_id] = site.id
     end
     @trans.skip_updator = true
     @trans.save!
     @trans.skip_updator = false
     @trans.update(params[:tranxn])
     return @trans
   end


   #** Utility Methods **
   
#  Returns the first detected condition
def first_match_detected(old_object, new_object)
    cdn_arr = []
    return cdn_arr.push("Condition: Price Changed")  if old_object&.price_before_tax != new_object&.price_before_tax
    return cdn_arr.push("Condition: Number Changed")  if old_object&.number != new_object&.number
    return cdn_arr.push("Condition: Tax Changed")   if old_object&.tax_percentage != new_object&.tax_percentage
    return cdn_arr.push("Condition: Item Changed")  if old_object&.item_id != new_object&.item_id 

    nil if cdn_arr.size == 0
end

# Returns all detected conditions
def all_matches_detected(old_object, new_object)
   cdn_arr = []
   cdn_arr.push("Condition: Price Changed")  if old_object&.price_before_tax != new_object&.price_before_tax
   cdn_arr.push("Condition: Number Changed")  if old_object&.number != new_object&.number
   cdn_arr.push("Condition: Tax Changed")   if old_object&.tax_percentage != new_object&.tax_percentage
   cdn_arr.push("Condition: Item Changed")  if old_object&.item_id != new_object&.item_id
   return  nil if cdn_arr.size == 0
   return cdn_arr
end

#Calculte Taxed and Non taxed
def price_tax_total_adjestments ti
  if( !ti.tax_percentage.nil? and  ti.tax_percentage.to_f != 0)
    input_price = ti.price_before_tax  = ti.price
    ti.price = input_price.to_f + (input_price.to_f * (ti.tax_percentage.to_f / 100))
    ti.number_price_tax_total = " #{ti.number} x #{ti.price_before_tax} + #{ti.tax_percentage}% Tax"       

  else
    ti.number_price_tax_total =  " #{ti.number} x #{ti.price} "
  end

end  

end