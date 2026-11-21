class Tranxn < ActiveRecord::Base
    
  self.table_name = "transactions"

  validate :all_validation

  audited
  include BaseUtils

  attr_reader :name_subname
  attr_accessor :difference_amount, :skip_updator
 
  belongs_to :contact
  belongs_to :site, optional: true
  has_many :txn_items, :foreign_key => :transaction_id
  has_many :payment_rows , :foreign_key => :transaction_id, dependent: :destroy

  before_create :calculate_amount, :calculate_contact_balance, if: -> {skip_updator != true}
  before_create :add_update_names
  before_update :add_update_names
  before_update :calculate_amount, :rectify_amount, if: -> {skip_updator != true}
  after_create  :update_balance_changes, if: -> {skip_updator != true}
  after_update  :update_balance_changes, if: -> {skip_updator != true}
  before_destroy :destroy_balance_changes,:destroy_dependent_txitems

  scope :payments, -> { where(trans_type: 'payment') }
  

  def add_update_names
    if self.contact.nil? && self.contact_id.blank?
      contact  = Contact.find(contact_id)
      self.contact = contact
    end  
    
    self.site_name =  self.site.name if(self.site)
  end  

  def all_validation
    errors.add(:Customer, "Costumer  cannot be blank") if contact_id.blank?
    errors.add( :Date, " Date cannot be blank") if on_date.blank?
    #errors.add( :Items, " Enter value for any one of the fields , items/payment amount/hamaali/vehical charges/discount ") if ( txn_items.blank? || txn_items[0].item_id == 0) and payment_amount.to_i == 0 and amount.to_i == 0 and discount.to_i == 0 and hamaali.to_i == 0 and vehicle_charges.to_i == 0 and amount == 0

    txn_items.each{|a|
      p "item in Validations"
      p a.item
      p  a
     errors.add(:Item, "Select an item  to provide value") if a.number.to_i != 0 and a.item.blank?
     errors.add("#{a.item.name}".to_sym, " Quantity value required  for  "+a.item.name) if a.number.to_i == 0 and !a.item.blank?
     
    } 
  end  

  def name_subname
  	return (contact.blank? ? "" : contact.name_subname)
  end

  def contact_fullname
    name_subname
  end  

  def site_name
  	return (site.blank? ? "": site.name)
  end	

  def tofrom
    return self.recieved = 1 ? "Recieved ": "Paid"
  end  

  def payment_amount_s
     ( ( self.payment_amount < 0 )? (self.payment_amount * -1 ) : self.payment_amount ).to_s
  end  

  def txn_net_amount
     
  end 

  def calculate_amount
    
  	   t_amount = 0
  	   self.txn_items.each{|t|  t_amount += t.amount }
    	 t_amount += other_charges_amount unless other_charges_amount.blank?
       t_amount += hamaali unless hamaali.blank?
       t_amount += vehicle_charges unless vehicle_charges.blank?  
       t_amount -= discount unless discount.blank?
       p "CALCULATE AMOUNT"
       p t_amount.to_i
       self.amount = t_amount
  
  end


  def calculate_contact_balance
     p "CALC CONT BAL"
     buyback == 1? txn_amount = (self.amount * -1) : txn_amount = self.amount
     recieved == 0? txn_payment = (self.payment_amount * -1) : txn_payment = self.payment_amount.to_f
     
     self.contact.balance = self.contact.balance + txn_amount - (txn_payment)
     self.difference_amount = txn_amount - txn_payment

     contact.skipp_updator = true
     self.contact.save!
     contact.skipp_updator = false

     Rails.logger.debug("Inside  calculate_contact_balance  .difference_amount = #{self.difference_amount} ")
     p  self.difference_amount.to_i

     txn_erlier = Tranxn.where(" contact_id = ? and ( on_date < ? OR on_date = ? )",self.contact_id,self.on_date,self.on_date).order("on_date,created_at ASC")
     self.contact_balance = ( txn_erlier.size > 0 ? txn_erlier.last.contact_balance + self.difference_amount : self.difference_amount   )
     
  end	

  def rectify_amount
    if payment_amount_changed? || amount_changed? || buyback_changed? || recieved_changed?
     
      buyback == 1? txn_amount = (self.amount.to_f * -1) : txn_amount = self.amount.to_f
      recieved == 0? txn_payment = (self.payment_amount.to_f * -1) : txn_payment = self.payment_amount.to_f 

      self.buyback_was ==1? txn_amount_old = (self.amount_was.to_f * -1): txn_amount_old = self.amount_was.to_f
      self.recieved_was == 0? txn_payment_old = (self.payment_amount_was.to_f * -1) : txn_payment_old = self.payment_amount_was.to_f

      new_balance =  txn_amount - txn_payment
      old_balance =  txn_amount_old - txn_payment_old

      self.difference_amount = new_balance - old_balance
      self.contact_balance = self.contact_balance + self.difference_amount
     
      self.contact.balance = self.contact.balance + self.difference_amount
      self.contact.save!
    end
  end  

  def mysql_date dates
   da =  dates.to_s.split('-')
   return da[2]+'-'+da[1]+'-'+da[0]
  end  

  def mysql_date_time dt 
   arr =  dt.split(' ')
   str = ''
   str = arr[0]+" "+arr[1] if arr.size > 1

   return str
  end  

  def update_balance_changes
   Rails.logger.debug(" TRANXN  update balance changes ->  #{self.difference_amount} ") 
   p self.difference_amount.to_i
    if !self.difference_amount.blank? 
       msql_date = mysql_date(self.on_date)
       msql_create_at = mysql_date_time(self.created_at.to_s)
       p "CHECKING DATE S"
       p self.created_at.to_s
       sql = "UPDATE transactions set contact_balance = (contact_balance + (#{self.difference_amount}) ) "
       sql << "where contact_id = #{self.contact_id} and ( on_date > '#{msql_date}' OR (on_date = '#{msql_date}' and created_at > '#{msql_create_at}' )) "
       p sql
       ActiveRecord::Base.connection.execute(sql) 
    end 
  end  

  def destroy_balance_changes
    ActiveRecord::Base.transaction do
      txn_amount =  (buyback == 1? (self.amount * -1) : self.amount.to_f)
      txn_payment = ( recieved == 0?  (self.payment_amount * -1) :  self.payment_amount.to_f )
      txn_balance =  txn_amount - txn_payment
        
      msql_date = mysql_date(self.on_date)
      msql_create_at = mysql_date_time(self.created_at.to_s)
      sql = "UPDATE transactions set contact_balance = (contact_balance - (#{txn_balance}) ) "
      sql << "where contact_id = #{self.contact_id} and ( on_date > '#{msql_date}' OR (on_date = '#{msql_date}' and created_at > '#{msql_create_at}' ))  "
      p "SQL -- Destroy "
      p sql
      ActiveRecord::Base.connection.execute(sql)
      self.contact.balance = self.contact.balance - txn_balance
      self.contact.save!
    end  
      

  end  


  def destroy_dependent_txitems
     self.txn_items.each{|t|
      t.destroy
     }
  end  

  class << self



    def total_payment txn_arr
      payment = 0
     txn_arr.each{|t|
       t.recieved == 0? txn_payment = (t.payment_amount * -1) : txn_payment = t.payment_amount.to_f 
       payment += txn_payment.to_f

      }
      payment
    end  
    
    def total_amount txn_arr
      amount = 0
      txn_arr.each{|t| 

        t.buyback == 1? txn_amount = (t.amount * -1) : txn_amount = t.amount
        amount += txn_amount.to_f

      }
      return amount
    end

    def total_balance txn_arr
      balance = 0
      payment = 0
      txn_arr.each{|t|
       t.recieved == 0? txn_payment = (t.payment_amount * -1) : txn_payment = t.payment_amount.to_f 
       payment += txn_payment.to_f

      }
      amount = 0
      txn_arr.each{|t| 

        t.buyback == 1? txn_amount = (t.amount * -1) : txn_amount = t.amount
        amount += txn_amount.to_f

      }
        amount - payment
    end  

    def total_balance_v1 txn_arr
      balance = 0
      payment = 0
      txn_arr.each{|t|

       t.recieved == 0? txn_payment = (t.payment_amount * -1) : txn_payment = t.payment_amount.to_f 
       payment += txn_payment.to_f

       t.buyback == 1? txn_amount = (t.amount * -1) : txn_amount = t.amount
       amount += txn_amount.to_f

      }
      amount - payment

    end  
    

  end  

end
