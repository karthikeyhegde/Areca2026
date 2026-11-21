class BalanceService
    attr_accessor :params, :user, :message, :sort_column, :sort_order, :page_size, :searchable_columns


    def self.first_wrongbalance_txn cid

     trans = Tranxn.where("contact_id = ?",c.id).order("on_date,created_at")
     trans.each{|t|
     
       t.buyback == 1? txn_amount = (t.amount * -1) : txn_amount = t.amount
       t.recieved == 0? txn_payment = (t.payment_amount * -1) : txn_payment = t.payment_amount.to_f
       cbalance = cbalance + txn_amount - txn_payment    
       return t  if ( cbalance  !=  t.contact_balance.to_f  )       	    
     }
    end 

    def self.repair_with_contact_id (cid, on_date)
        repair_for_contact(Contact.find(cid),on_date)
    end

    def self.repair_for_contact contact,on_date
        trans = Tranxn.where("contact_id = ? and on_date >= ? ",contact.id,on_date).order("on_date,created_at")
        reference_txn = Tranxn.where("contact_id = ? and on_date < ? ",contact.id,on_date).order("on_date,created_at").last
        self.recalculate_for_contact contact,trans,reference_txn.contact_balance
    end    

    def self.reapir_after_backdate_txn  txn    
         self.repair_for_contact txn.contact, txn.on_date        
    end     

    def self.recalculate_for_contact  contact, trans, starting_balance
      Rails.logger.debug(" START ********* START  ************ ===  #{contact.name} ")
      cbalance = starting_balance
      id_to_newbalance = {}

      trans.each{|a|

          a.skip_updator =true
          a.buyback == 1? txn_amount = (a.amount * -1) : txn_amount = a.amount
          a.recieved == 0? txn_payment = (a.payment_amount * -1) : txn_payment = a.payment_amount.to_f
          cbalance = cbalance + txn_amount - txn_payment

          if a.contact_balance != cbalance
            id_to_newbalance[a.id]  = cbalance
          end  

      }       
      if id_to_newbalance.length > 0
          id_str = ""
          sql = " UPDATE transactions set contact_balance = CASE "
          id_to_newbalance.each { |key,value| 
            sql << " WHEN id = #{key} THEN #{value} "
            id_str << " #{key},"
          }
          sql << " END "
          sql << " WHERE id IN (#{id_str.chop!})  "
          ActiveRecord::Base.connection.execute(sql)         
      end

      if(contact.balance != cbalance)       
        contact.balance = cbalance+contact.starting_balance
        contact.save!
      end
    end  
        
    
    ##End of CLASS
end    