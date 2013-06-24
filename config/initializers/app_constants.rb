GROUP_LOAN_PHASE= {
  :financial_education => 1,
  :loan_disbursement => 2 , 
  :weekly_payment => 3 , 
  :grace_period => 4 , 
  :default_resolution => 5  # on default resolution execution => compulsory savings is ported 
}

GROUP_LOAN_DEFAULT_PAYMENT_CASE = {
  :standard => 1, 
  :custom => 2 
}

GROUP_LOAN_DEACTIVATION_STATUS = {
  :financial_education_absent => 1, 
  :loan_disbursement_absent => 2 ,
  :finished_group_loan => 3 
}

GROUP_LOAN_VOLUNTARY_SAVINGS_WITHDRAWAL_CASE = {
  :normal => 1 , 
  :loan_closing => 2 
}

FUND_DIRECTION = {
  :incoming => 1,
  :outgoing => 2 
}

SAVINGS_STATUS = {
  :savings_account => 0 ,  # the base savings account. every member has it. 
  
  
  :group_loan_compulsory_savings => 10,
  :group_loan_voluntary_savings => 11
  
}

GROUP_LOAN_WEEKLY_PAYMENT_STATUS = {
  :unmarked => 1 , 
  :no_payment_declared => 2 ,
  :only_savings => 3 , 
  :full_payment => 4 
}

GROUP_LOAN_WEEKLY_ATTENDANCE_STATUS = {
  :unmarked => 1 , 
  :present => 2, 
  :absent => 3 , 
  :late => 4 
}


DEFAULT_PAYMENT_ROUND_UP_VALUE = 500

