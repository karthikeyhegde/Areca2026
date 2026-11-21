class TranxnIndex
  attr_accessor :params, :user, :message, :sort_column, :sort_order, :page_size
   def initialize(params,user)
     @params= params
     @user= user
   end

   def paginated_trs
      @sort_column = params[:sort_colum] || 'on_date'
	  @sort_order = params[:sort_order]  || "DESC"
	  @page_size = params[:page_size] || 20

    if params[:no_of_weeks].blank? &&  params[:month_ago] != 'true'  && params[:from_date].blank? &&  params[:to_date].blank?
      return Tranxn.includes(:contact, :payment_rows, :txn_items, :site).order(Arel.sql("#{@sort_column} #{@sort_order}, transactions.created_at DESC ")).limit("30")
   end 
   
	  no_of_weeks =  params[:no_of_weeks].blank? ? 2 : params[:no_of_weeks].to_i
	  date_str = "on_date > '"+no_of_weeks.weeks.ago.strftime("%Y-%m-%d")+"' " if no_of_weeks > 1
	  @trs_text = "Showing  records from last "+no_of_weeks.to_s+" weeks ."
  
	  date_str = "on_date >  '"+1.months.ago.strftime("%Y-%m-%d")+"'" if params[:month_ago] == 'true'

	  if !params[:from_date].blank? || !params[:to_date].blank?
	    from_date = ( params[:from_date].blank? ?  '2000-01-01': DateTime.parse(params[:from_date]).strftime('%Y-%m-%d %H:%M'))
	    to_date   = ( params[:to_date].blank? ? '2100-01-01' : DateTime.parse(params[:to_date]).strftime('%Y-%m-%d %H:%M') )
	    date_str  = "on_date  between '"+from_date+"' and '"+to_date+"'"
	    @trs_text = "Showing transactions "
	    @trs_text += " from "+params[:from_date] if  !params[:from_date].blank?
	    @trs_text += " up to "+params[:to_date] if  !params[:to_date].blank?
	  end
     return Tranxn.includes(:contact, :payment_rows, :txn_items, :site).where(date_str).order(Arel.sql("#{@sort_column} #{@sort_order}, transactions.created_at DESC "))

   end

   def index_trs
   	   Tranxn.where(date_str).includes(:txn_items, :contact, :payment_rows, :site).order(Arel.sql("on_date, created_at DESC #{limit}" ))
   end

   def filter_trs
   	  p_hsh = params
   	  contact_ids = ''
      item_ids = ''
      site_ids = ''
   	  from_date = p_hsh["from_date1"]
      to_date = p_hsh["to_date1"] 
      contact_ids = p_hsh["contact_id"].join(',') if !p_hsh["contact_id"].blank?
      item_ids = p_hsh["item_id"].join(',') if !p_hsh["item_id"].blank?
      site_ids = p_hsh["site_id"].join(',') if !p_hsh["site_id"].blank?
      @sort_column = 'on_date'
      if(p_hsh["commit"] != 'Print view')

        @sort_order = "DESC"
      end
      
      txn_ids = ''
            
      f_date =  from_date.blank? ? '' : DateTime.parse(from_date).strftime('%Y-%m-%d %H:%M')  
      t_date =  to_date.blank?  ?  '' : DateTime.parse(to_date).strftime('%Y-%m-%d %H:%M') 
      
      sql = " 1 = 1 "
      sql << " and contact_id in (#{contact_ids}) " if !contact_ids.blank? && contact_ids.match(/^[0-9,"']*$/)
      sql << " and site_id in (#{site_ids}) " if !site_ids.blank? && site_ids.match(/^[0-9,"']*$/)
      sql << " and on_date >=  '#{f_date}' " if !f_date.blank?
      sql << " and on_date <= '#{t_date}' "  if !t_date.blank?
      if !item_ids.blank? && item_ids.match(/^[0-9,"']*$/)
      	txn_ids = TxnItem.select(:transaction_id).where("item_id in (#{item_ids}) ").collect{|a| a.transaction_id}
        sql << " and id in (#{txn_ids.join(',')}) " if !txn_ids.blank?
      end 	
      p "SQLL"
      p sql
     return Tranxn.includes(:contact, :payment_rows, :site, :txn_items => :item ).where(sql).order(Arel.sql("#{@sort_column} #{@sort_order}, transactions.created_at DESC " ))

   end	


end
