 class PaymentRow < ActiveRecord::Base
  
  include BaseUtils
  audited
  belongs_to :tranxn, :foreign_key => :transaction_id
  belongs_to :payment, :foreign_key => :transaction_id
  

end