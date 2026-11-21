class TranxnsController < ApplicationController
  @@available_action = ['new_sale','new_return','new_payment']
 


 def index
    begin
       trnidx = TranxnIndex.new(params,@user)
       @trs = trnidx.paginated_trs
       @sort_column = trnidx.sort_column
       @sort_order = trnidx.sort_order
       @page_size =  trnidx.page_size
       @trs_text  = trnidx.message
    rescue Exception => e
      print e.message
    end 

 end

 def show
 end

 def new
   @trans = Tranxn.new
   @form_method = 'post'
   render :action => params[:tx_type] if  @@available_action.include?(params[:tx_type])
 end

 def new_sale
 end
 
 def new_return
 end 

 def new_payment
 end 

 def edit
   @trans = Tranxn.find(params[:id])
   @contact_name = @trans.contact.name.to_s+" "+@trans.contact.subname.to_s
   @site_name = (@trans.site.blank? ?  "":@trans.site.name)
   @form_method = 'put '
 end

 def create

    begin
      txser = TranxnService.new(params,@auser)
      @trans = txser.create_quickform
      @save_success = false
      #@trans.save!
      @trs = Tranxn.all
      
      flash[:notice] = 'Transaction# '+@trans.id.to_s+' added Successfully !'
      flash.keep(:notice)

      if params[:commit] == 'Save and +New'
        @save_success = true
          respond_to do |format|
              format.js {render layout: false}
          end 
      else
        url = report_page_contact_path(:id => @trans.contact_id)
        render js: "window.location.pathname='#{url}'"
      end  

   #rescue Exception => e
   rescue ActiveRecord::RecordInvalid => e
      Rails.logger.debug( "errors")
      Rails.logger.debug( e.record.errors)
      Rails.logger.debug(e.to_s)
      @serr = e.to_s
      respond_to do |format|
       format.js {render layout: false}
      end     
    end


  end

 def update
 # begin  
     txup = TranxnUpdate.new(params,@auser)
     @trans = txup.do_update
     url = report_page_contact_path(:id => @trans.contact_id)
     render js: "window.location.pathname='#{url}'"
=begin   rescue Exception => e
      p "error-----"
     p e.to_s
     @serr = e.to_s
       respond_to do |format|
         format.js {render layout: false}

       end  
    end 
=end      
 end

 def destroy
 end

def remove
  begin
    txn = Tranxn.find(params[:id])
    cid = txn.contact_id
    txn.destroy
   flash[:notice] = 'Transaction# '+params[:id]+' deleted Successfully !'
   flash.keep(:notice)
   if(params[:show_page] == 'report_page')
     redirect_to  report_page_contact_path(:id => cid)
   else
    redirect_to :action => 'index'
   end 
   
  rescue Exception => e 
    p e.to_s
    p e.backtrace
  end  
 end

 def add_item_row
   row_no = params[:no]
   #@itmarr = Item.all.collect{|c| [c.name,c.id]}
   @itm_hsh = {}
   @items=  Item.all.each{|it|  @itm_hsh[it.id] = it.current_stock}
   @row_no = row_no.to_i + 1
   @txn_item = TxnItem.new 
   respond_to do |format|
     format.js {render layout: false}
   end
 end 

 def item_current_stock
     item_stock = Item.find(params[:id].to_i).current_stock
     respond_to do |format|
      format.json { render json: { message: "success", data: { currentStock: item_stock }  } }
    end
 end 

 def search_contact
   contacts = Contact.trns_search(params[:str])
   respond_to do |format|
      format.json {render layout: false}
   end   

 end 

 def pagination
   start_time = Time.now
   trnidx = TranxnIndex.new(params,@user)
   @trs = trnidx.paginated_trs
   end_time1 = Time.now
   @sort_column = trnidx.sort_column
   @sort_order = trnidx.sort_order
   @page_size =  trnidx.page_size
   @trs_text  = trnidx.message
   respond_to do |format|
      format.js {render layout: false}
   end 
   end_time = Time.now
   p @trs.size
   p " Total Time - "+(end_time - start_time).to_s+ "  -- "+(end_time1 - start_time).to_s
 end 

 def quick_add_form

  @trans = Tranxn.new
  @cont = Contact.all_conts
  @sites = Site.all
  @itm_hsh = {}
  @items=  Item.all.each{|it|  @itm_hsh[it.id] = it.current_stock}
   
 end 

 def filter_txn
   p "---"
   params[:from_date] = params[:from_date1]
   params[:to_date] = params[:to_date1]
   params[:from_date] = '2000-01-01' if params[:from_date].blank?
   params[:to_date] = '2100-01-01' if params[:from_date].blank?
    trnidx = TranxnIndex.new(params,@user)
    @trs = trnidx.filter_trs
    @filter = true
    respond_to do |format|
       p "PRAMS"
       p params[:commit]
      if(params[:commit] == 'Print view')
       format.js {render '_print_filter', layout: false}
      else  
         format.js {render layout: false}
      end
   end 
 end 

 
end
