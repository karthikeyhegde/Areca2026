class TranxnService
  attr_accessor :params, :user
   def initialize(params,user)
     @params= params
     @user= user
   end

   def create_quickform()

   	@trans = Tranxn.new(params[:tranxn])
    @trans.created_by = @user.id

    

=begin
     contact_name = params[:txn][:contact].strip
      if !contact_name.blank? and  contact_name.length > 3
        cnt =  Contact.find(params[:tranxn][:contact_id]) if !params[:tranxn][:contact_id].blank?
        if cnt.blank? || cnt.name_subname != contact_name
            contact = Contact.new
            contact.name = contact_name
            contact.regular = 0
            contact.save!
            @trans.contact = contact
        else
          @trans.contact = cnt    
        end  
         
      end  
=end
     site_param = params[:txn][:site].strip
     if !site_param.blank? and  site_param.length > 3
       site = Site.find_by_name(site_param)
       if site == nil
         site = Site.new
         site.name = site_param
         site.save!
       end 
       @trans.site = site
       @trans.site_name = site.name
     end
     
     @trans.save!
     params[:txn_items].each{ |key,val|
     item_params = val
     unless ( item_params[:item_id].blank? || item_params[:item_id].to_i == 0) && item_params[:item_descri].blank? 
      ti = TxnItem.new(item_params)
      ti.item_name = Item.find(item_params[:item_id]).name
      Rails.logger.debug(" TAX PERCENT #{ti.tax_percentage} ")
      if( !ti.tax_percentage.nil? and  ti.tax_percentage.to_f != 0)
        input_price = ti.price_before_tax  = ti.price
        ti.price = input_price.to_f + (input_price.to_f * (ti.tax_percentage.to_f / 100))
        ti.number_price_tax_total = " #{ti.number} x #{ti.price_before_tax} + #{ti.tax_percentage}% Tax"       
      
     else
      ti.number_price_tax_total =  " #{ti.number} x #{ti.price} "
     end
      
      ti.contact_id = params[:tranxn][:contact_id]
      ti.amount = ti.calculate_amount
      ti.buyback_now = @trans.buyback
      ti.item_id = item_params[:item_id]
      
      ti.on_date = params[:tranxn][:on_date]
      ti.buyback = @trans.buyback
      @trans.txn_items << ti
      p "Trans Itens"
      p @trans.txn_items
     end 
    }
    @trans.save!
    return @trans
   end

   def quickform_ondatecheck
    on_date = params[:tranxn][:on_date]
    mysql_on_date = Utility.mysql_date on_date
    grt_ct  = Tranxn.where(" on_date > ? AND contact_id = ? ", mysql_on_date,params[:tranxn][:contact_id]  ).count

    @trans =  create_quickform

    if grt_ct > 0
      Rails.logger.debug("-----------------------***** Calling BCKJOB FOR #{@trans.id} ******--------------")
      #Call stock repair and balance repair in background
      #BalanceJob.recalculate_later(@trans.id)
      BalanceService.reapir_after_backdate_txn  @trans 
    end  

     
   end

   def Txnindex
   end 
end