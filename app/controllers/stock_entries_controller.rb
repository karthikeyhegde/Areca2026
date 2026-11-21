class StockEntriesController < ApplicationController


 def index
  @sort_column = params[:sort_colum] || 'on_date'
  @sort_order = params[:sort_order]  || "DESC"
  @page_size = params[:page_size] || 20

  
  no_of_weeks =  params[:no_of_weeks].blank? ? 52 : params[:no_of_weeks].to_i
  date_str = "on_date > '"+no_of_weeks.weeks.ago.strftime("%Y-%m-%d")+"' " 
  @trs_text = "Showing  Stock Entries from last "+no_of_weeks.to_s+" weeks ."
  
  if !params[:from_date].blank? || !params[:to_date].blank?
    from_date = ( params[:from_date].blank? ?  '2000-01-01': DateTime.parse(params[:from_date]).strftime('%Y-%m-%d %H:%M'))
    to_date   = ( params[:to_date].blank? ? '2100-01-01' : DateTime.parse(params[:to_date]).strftime('%Y-%m-%d %H:%M') )
    puts "-- AA from "+from_date+"  -to "+to_date
    date_str  = "on_date  between '"+from_date+"' and '"+to_date+"'"
    @trs_text = "Showing Stock Entries "
    @trs_text += " from "+params[:from_date] if  !params[:from_date].blank?
    @trs_text += " up to "+params[:to_date] if  !params[:to_date].blank?
  end
  @offset = params[:offset] || 0
  @total = StockEntry.count
  @stock_entries = StockEntry.includes(:contact,:item).where(date_str).order(Arel.sql("#{@sort_column} #{@sort_order}, created_at DESC ") )
  
 end

 def show
 end

 def new
  @stock_entry = StockEntry.new
  @contacts = Contact.where('supplier = 1')
  @form_method = 'post'
 end

 def create
   begin
   # @stock_entry = StockEntry.new(params[:stock_entry])
    #@stock_entry.save!
    @stock_entry = StockService.add_se params
    flash[:notice] = 'StockEntry #'+@stock_entry.id.to_s+' added Successfully !'
    flash.keep(:notice)
   rescue Exception => e
     p e.to_s
     p e.backtrace
   end 
   url = stock_entries_path
   render js: "window.location.pathname='#{url}'"
 end

 def edit
   @stock_entry=  StockEntry.find(params[:id])
   @form_method = 'patch'
   @contacts = Contact.where('supplier = 1')
 end

 def update
   begin
    @stock_entry = StockService.update_se params
    flash[:notice]  = 'StockEntry #'+@stock_entry.id.to_s+' updated Successfully !'
    flash.keep(:notice)
    redirect_to :action => 'index'
   rescue Exception => e
    p "Error: "+e.to_s
    flash[:error] = e.to_s
    flash.keep(:error)
    redirect_to :action => 'edit'
   end 

 end

 def destroy
   redirect_to :action => 'index'
 end

 def remove
    begin
      StockService.delete_se params[:id]
      flash[:notice]  = 'StockEntry #'+params[:id]+' DELETED successfully !'
      flash.keep(:notice)
    rescue Exception => e
      p e.to_s
      flash[:error] ="Error: #{params[:id]} NOT DELETED: "+e.to_s 
      flash.keep(:error)
    end    
    redirect_to :action => 'index'
 end

 def contact_stock
   @stock_entries = StockEntry.where("contact_id = ?",params[:id].to_i)
   @contact = Contact.find(params[:id].to_i)
   @show_val = 'stks'
   @report = Report.new()
   render :template => 'contacts/report_page'

 end 

 def pagination
    p_hash = {}
    p_hash['item_id'] = params['item_id'].to_i if !params['item_id'].blank?
    p_hash['contact_id'] = params['contact_id'].to_i if !params['contact_id'].blank?
    p_hash['site_id'] = params['site_id'].to_i if !params['site_id'].blank?
    p_hash['from_date'] = params['from_date'] if !params['from_date'].blank?
    p_hash['to_date'] = params['to_date'] if !params['to_date'].blank?

    if !params[:no_of_weeks].blank?
     no_of_weeks =  params[:no_of_weeks].to_i
      p_hash['from_date'] = no_of_weeks.weeks.ago.strftime("%Y-%m-%d")
    end  

    @stock_entries = StockEntry.get_list(p_hash)
    respond_to do |format|
      format.js {render layout: false}
   end

 end 

end	