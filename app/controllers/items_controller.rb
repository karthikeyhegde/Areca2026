  class ItemsController < ApplicationController
  
   def index
    @items = Item.order(:name)
   end

    def show
    end

   def new
    @item = Item.new
    @form_method = 'post'
   end

   def create
    @item = Item.new(params[:item])
    @item.save!
    redirect_to :action => 'index'
   end

   def edit
    @item = Item.find(params[:id])
    @form_method = 'update'
   end

   def update
    @item = Item.find(params[:id])
    @item.update(params[:item])
    redirect_to :action => 'index'
   end

   def destroy
    redirect_to :action => 'index'
   end

   def remove
     begin
     Item.find(params[:id]).destroy
     redirect_to :action => 'index'
   rescue Exception => e
     p e.to_s
     p e.baktrace
   end 
   end

   def rep_txnitems

      @item = Item.find(params[:id])
      sdate = nil
      edate = nil

    if (params.has_key?(:sdate) && params[:sdate] != nil)
      sdate = DateTime.parse(params[:sdate]).strftime('%Y-%m-%d')
      edate = DateTime.parse(params[:edate]).strftime('%Y-%m-%d') 
    else
        if( @item.txn_items.length() >  100)
          sdate = 2.months.ago
          edate = Time.now
          params[:sdate] = DateTime.parse(sdate.to_s).strftime("%d-%m-%Y")
          params[:edate] = DateTime.parse(edate.to_s).strftime("%d-%m-%Y")

        end
    end  

      @txn_items = @item.rep_ixnitems sdate, edate
      @all_sum = 0
      @all_numbers = 0
      @txn_items.each{|s| 
        p "909090 #{s.contact_name}"
        @all_sum +=  (s.tranxn.buyback == 1 ? (-1 * s.amount.to_f) : s.amount.to_f)
        @all_numbers += ( s.tranxn.buyback == 1 ? (-1 * s.number.to_i) : s.number.to_i)
      }
      
   end 

   def filter_rep_txnitems
      rep_txnitems
      p "ALL SUM"
      p @all_numbers
      render template:  'items/rep_txnitems'
   end

   def all_search
      search_str = params[:search]
      ssearch = '%'+search_str+'%'
      @contacts = Contact.where(" LOWER (name) LIKE  LOWER (?)  OR LOWER (subname)  LIKE LOWER (?) OR LOWER (place) LIKE LOWER (?) OR LOWER (contact_type) LIKE LOWER (?)",ssearch,ssearch,ssearch,ssearch)
      @items = Item.where(" LOWER (name)  LIKE LOWER(?)",ssearch)
      @sites = Site.where(" LOWER (name) LIKE LOWER (?) OR LOWER (place) LIKE LOWER (?) ",ssearch,ssearch )
      @trs = @transaction = Tranxn.where('id = ?',params[:search].to_i)
   end 


   def aggrigated_summary
     required_params = params.slice(:site_id,:contact_id,:from_date,:to_date)
     @summary =   Item.summary required_params
     @all_sum = 0
     @summary.each{|s| @all_sum += s['t_sum'].to_f}
   end 

   def stock_entries_list
        @item = Item.find(params[:id])
        @stock_entries  = StockEntry.get_list ({'item_id' =>params[:id] }) 
        @total =  StockEntry.total  @stock_entries
   end

   def filter_stkentries
      @item = Item.find(params[:item_id])
      @stock_entries = StockEntry.get_list(params)
      @total =  StockEntry.total  @stock_entries
      render template:  'items/stock_entries_list'
   end

  def ajax_reptxn
    rep_txnitems
    respond_to do |format|
     format.js {render layout: false}
   end  
  end

  def ajax_stockentry
    @item = Item.find(params[:id].to_i)
    res = @item.stock_entries_with_total
    @item_stock_entries = res["stockentries"]
    @total = res["total"]
    respond_to do |format|
     format.js {render layout: false}
   end  
  end 

  def edit_items_all
    if @auser.role  != 'Admin' 
      redirect_to :action => 'index'
    end
   @items = Item.order(:name)
   @default_date = MySetting.find_by_name('stock_start_date')
  end 

  def quick_save_item

    starting_stock  = params[:start_stock].to_i
    item = Item.find(params[:id].to_i)
    item.start_date =  DateTime.parse(params[:start_date]).strftime('%Y-%m-%d %H:%M')
    item.starting_stock = starting_stock
    item.save!
    StockService.recalculate_stock item.id
    item = Item.find(params[:id].to_i)
    respond_to do |format|
      format.json {render :json => item.to_json}
    end
  end  

  def recalculate_stock
    begin
      StockService.recalculate_stock_all
      flash[:success] = "Success: Re-Calculated All Items Stocks"
      flash.keep(:success)
    rescue Exception => e
      flash[:error] = "Error: "+e.to_s
      flash.keep(:error)
    end  
    redirect_to :action => 'edit_items_all'
  end  

    def daily_trans
      @data_arr, @item, @total_in, @total_out,@message  = ItemService.daily_trans params
    end 

     def filter_daily_trans
        render daily_trans

     end 

     def stock_refresh
        item = Item.find(params[:id].to_i)
        StockService.recalculate_stock item.id
        redirect_to :action => 'index'
     end
  end
