class PaymentsController < ApplicationController
  def index
    sort_column = params[:sort_colum] || "on_date"
    sort_order = params[:sort_order] || "DESC"
    page_size = params[:page_size] || 20
    offset = params[:offset] || 0
    @payments = Payment.order("#{sort_column} #{sort_order}, created_at DESC LIMIT #{page_size}  offset #{offset} ")
  end

  def show
    @payment = Payment.find(params[:id].to_i)
  end

  def new
    @payment = Payment.new
    @site_name = ""
    @cont = Contact.all_conts
    @sites = Site.all
  end

  def create
    begin
      @p = Payment.new(params[:payment])
      params[:payment_rows].each { |key, val|
        pr = PaymentRow.new(val)
        @p.payment_rows << pr
      }

      @p.assign_amount
      @p.payment_rows = []
      @p.save!
       params[:payment_rows].each { |key, val|
          pr = PaymentRow.new(val)
          @p.payment_rows << pr
      }
      @p.save!
      flash[:success] = "Payment Added Successfully"
      @payments = Payment.all
      #render js: "window.location.pathname='#{transactions_path}'"
      url = report_page_contact_path(:id => @p.contact_id)
      render js: "window.location.pathname='#{url}'"
    rescue Exception => e
      @trans = @p
      #@serr = @e.to_s
      p e.to_s
      p e.st
      # respond_to do |format|
      #  format.js {render layout: false}
      #end
    end
  end

  def edit
    @payment = Payment.find(params[:id].to_i)
    @site_name = (@payment.site.blank? ? "" : @payment.site.name)
    @cont = Contact.all_conts
    @sites = Site.all
  end

  def update
    @payment = Payment.find(params[:id].to_i)
    payrow_ids = []
    params[:payment_rows].each { |key, val|
      id = key.to_i
      payrow_ids << id

      if id < 1000
        pr = PaymentRow.new(val)
        pr.created_by = @auser.id
        pr.save!
        @payment.payment_rows << pr
      else
        val[:updated_by] = @auser.id
        old_pr = PaymentRow.find(key)
        old_pr.update(val)
      end
    } unless params[:payment_rows].blank?

    @payment.payment_rows.each { |p|
      p.destroy if !payrow_ids.include?(p.id)
    }

    @payment.assign_amount
    @payment.save!
    @payment.update(params[:payment])
    flash[:notice] = "Payment #{@payment.id} has been updated "
    @trs = Payment.all
    render js: "window.location.pathname='#{payments_path}'"
  end

  def remove
    @payment = Payment.find(params[:id].to_i)
    @payment.destroy
    redirect_to :action => "index"
  end

  def add_payment_row
    @row_no = params[:row_no].to_i + 1
    @payment_row = PaymentRow.new(:transaction_id => params[:transaction_id])
    respond_to do |format|
      format.js { render layout: false }
    end
  end

  def filter
    @subtext_msg = ''
    if(params[:sdate].blank? && params[:edate].blank? && ( params[:contact_id].blank? || params[:contact_id].to_i == 0 ) )
      @payments = Payment.includes(:contact,:payment_rows).order("#{sort_column} #{sort_order}, on_date DESC LIMIT #{50}")
      @subtext_msg = "Showing last #{@payments.size} payments"
      return
    end  

    if(params[:sdate].blank? && !params[:edate].blank?)
      params[:sdate] = Date.parse(params[:edate]) - 30.days
    end

    if(params[:edate].blank? && !params[:sdate].blank?)
      params[:edate] = Date.parse(params[:sdate]) + 30.days
    end

     where_str = []
     if(!params[:sdate].blank?)

       sdate = DateTime.parse(params[:sdate].to_s).strftime('%Y-%m-%d')
       where_str << " on_date >= '#{sdate}' "
       @subtext_msg += " from #{params[:sdate]}"
     end   

     if(!params[:edate].blank?)
       edate = DateTime.parse(params[:edate].to_s).strftime('%Y-%m-%d')
       where_str << " on_date <= '#{edate}' " 
       @subtext_msg += " till #{params[:edate]}"
     end

     if ( !params[:contact_id].blank? && params[:contact_id].to_i != 0)
       ctid = params[:contact_id].to_i
       where_str << " contact_id = #{ctid} "
       @contact = Contact.find(ctid)
       @subtext_msg += " for #{@contact.name_subname}"
       p "wherestr #{where_str}"
     end 

     where_sql = where_str.join(' and ')
     
     @payments = Payment.includes(:contact,:payment_rows).where(where_sql).order(' on_date desc')
     @subtext_msg = "Showing #{@payments.size} payment records"+@subtext_msg
     render template:  'payments/index'
  end  
end
