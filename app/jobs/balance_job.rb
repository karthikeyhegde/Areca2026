class BalanceJob < ApplicationJob
  queue_as :default

  def recalculate(txn_id)
    Rails.logger.debug(" ------------------*********  INSIDE JOB  ID= #{txn_id} ******---------------")
    txn = Transaxtion.find(txn_id)
    BalanceService.reapir_after_backdate_txn txn
  end

end