require 'spec_helper'

describe GroupLoanWeeklyPayment do
  before(:each) do
    @office = Office.create_object({
      :name => "KKI Cilincing 1",
      :address => "Cilincing"
    })
    
    (1..8).each do |number|
      Member.create_object({
        :name =>  "Member #{number}",
        :address => "Address alamat #{number}" ,
        :office_id => @office.id,
        :id_number => "342432#{number}"
      })
    end
    
    @employee = Employee.create_object({
      :name => "Employee 1",
      :office_id => @office.id
    })
    
    @total_weeks_1        = 8 
    @principal_1          = BigDecimal('20000')
    @interest_1           = BigDecimal("4000")
    @compulsory_savings_1 = BigDecimal("6000")
    @admin_fee_1          = BigDecimal('10000')
    @initial_savings_1    = BigDecimal('10000')
    
    @group_loan_product_1 = GroupLoanProduct.create_object({
      :name => "Produk 1, 500 Ribu",
      :office_id          =>  @office.id,
      :total_weeks        =>  @total_weeks_1              ,
      :principal          =>  @principal_1                ,
      :interest           =>  @interest_1                 , 
      :min_savings        =>  @compulsory_savings_1       , 
      :admin_fee          =>  @admin_fee_1                , 
      :initial_savings    =>  @initial_savings_1 
    }) 
    
    @total_weeks_2        = 8 
    @principal_2          = BigDecimal('15000')
    @interest_2           = BigDecimal("5000")
    @compulsory_savings_2 = BigDecimal("4000")
    @admin_fee_2          = BigDecimal('10000')
    @initial_savings_2    = BigDecimal('5000')

    @group_loan_product_2 = GroupLoanProduct.create_object({
      :name => "Product 2, 800ribu",
      :office_id          =>  @office.id,
      :total_weeks        =>  @total_weeks_2              ,
      :principal          =>  @principal_2                ,
      :interest           =>  @interest_2                 , 
      :min_savings        =>  @compulsory_savings_2       , 
      :admin_fee          =>  @admin_fee_2                , 
      :initial_savings    =>  @initial_savings_2 
    })
    
    @group_loan = GroupLoan.create_object({
      :office_id => @office.id,
      :name                             => "Group Loan 1" ,
      :is_auto_deduct_admin_fee         => true,
      :is_auto_deduct_initial_savings   => true,
      :is_compulsory_weekly_attendance  => true
    })
    
    @sub_group_1 = SubGroupLoan.create_object({
      :group_loan_id => @group_loan.id , 
      :name => "Sub Group 1"
    })
    
    @sub_group_2 = SubGroupLoan.create_object({
      :group_loan_id => @group_loan.id , 
      :name => "Sub Group 2"
    })
    
    counter = 0
    Member.all.each do |member|
      sub_group = @sub_group_1
      sub_group = @sub_group_2 if counter%2 == 0 
      counter+=1 
      GroupLoanMembership.create_object({
        :group_loan_id => @group_loan.id,
        :sub_group_loan_id => sub_group.id ,
        :member_id => member.id 
      })
    end
    
    # select group leader + sub_group leader 
    @group_loan.set_group_leader( @group_loan.active_group_loan_memberships.first )
    @sub_group_1.set_sub_group_leader( @sub_group_1.active_group_loan_memberships.first )
    @sub_group_2.set_sub_group_leader( @sub_group_2.active_group_loan_memberships.first )
    
    @group_loan.reload
    counter = 0 
    @group_loan.active_group_loan_memberships.each do |glm|
      glp = @group_loan_product_1 
      glp = @group_loan_product_2 if counter%2 == 1
      counter +=1 
      
      GroupLoanSubcription.create_object({
        :group_loan_product_id => glp.id ,
        :group_loan_membership_id => glm.id 
      })
    end
    
    @group_loan.reload
    @group_loan.start 
    
    @group_loan.active_group_loan_memberships.each do |glm|
      glm.mark_financial_education_attendance( {
        :is_attending_financial_education => true 
      } )
    end
    @group_loan.finalize_financial_education 
    @group_loan.reload 
    @group_loan.active_group_loan_memberships.each do |glm|
      glm.mark_loan_disbursement_attendance( {
        :is_attending_loan_disbursement => true 
      } )
    end
    @group_loan.finalize_loan_disbursement
    @group_loan.reload 
    @glm_1 = @group_loan.active_group_loan_memberships[0]
    @active_weekly_task = @group_loan.active_weekly_task
  end
  
  it 'should have remaining weeks equal to the loan duration' do
    @glm_1.remaining_weeks.count.should == @group_loan.loan_duration 
  end
   
  it 'should have finalized loan disbursement and in weekly payment period' do
    @group_loan.is_loan_disbursement_finalized.should be_true 
    @group_loan.is_weekly_payment_period_phase?.should be_true 
  end
  
  it 'should have group_loan_weekly_task , equal to the number of loan duration' do
    @group_loan.group_loan_weekly_tasks.count.should == @group_loan.loan_duration
  end
  
  it 'should allow group loan weekly payment creation' do
    @glw_payment =  GroupLoanWeeklyPayment.create_object({
      :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
      :group_loan_membership_id            => @glm_1.id                                           ,
      :group_loan_id                       => @group_loan.id                                      ,
      :number_of_backlogs                  => 0                                                   ,
      :is_paying_current_week              => true                                                ,
      :is_only_savings                     => false                                               ,
      :is_no_payment                       => false                                               ,
      :is_only_voluntary_savings           => false ,
      :number_of_future_weeks              => 0                                                   ,
      :voluntary_savings_withdrawal_amount => 0                                                   ,
      :cash_amount                         => @glm_1.group_loan_product.weekly_payment_amount
    })
    
    @glw_payment.should be_valid 
  end
  
  it 'should not have cleared the current week' do
    @glm_1.has_cleared_weekly_payment?(@active_weekly_task).should be_false 
  end
  
  
  it 'should allow not allow cash or savings transaction if no_payment_declaration' do
    @glw_payment =  GroupLoanWeeklyPayment.create_object({
      :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
      :group_loan_membership_id            => @glm_1.id                                           ,
      :group_loan_id                       => @group_loan.id                                      ,
      :number_of_backlogs                  => 0                                                   ,
      :is_paying_current_week              => false                                                ,
      :is_only_savings                     => false                                               ,
      :is_no_payment                       => true                                               ,
      :is_only_voluntary_savings           => false ,
      :number_of_future_weeks              => 0                                                   ,
      :voluntary_savings_withdrawal_amount => 0                                                   ,
      :cash_amount                         => BigDecimal('500')
    })
    
    @glw_payment.should_not be_valid  
    
    
    @glw_payment =  GroupLoanWeeklyPayment.create_object({
      :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
      :group_loan_membership_id            => @glm_1.id                                           ,
      :group_loan_id                       => @group_loan.id                                      ,
      :number_of_backlogs                  => 0                                                   ,
      :is_paying_current_week              => false                                                ,
      :is_only_savings                     => false                                               ,
      :is_no_payment                       => true                                               ,
      :is_only_voluntary_savings           => false ,
      :number_of_future_weeks              => 0                                                   ,
      :voluntary_savings_withdrawal_amount => 0                                                   ,
      :cash_amount                         =>  0
    })
    
    @glw_payment.should be_valid
  end
  
  it 'should not allow savings withdrawal on no_payment declaration' do
    @savings_addition = GroupLoanVoluntarySavingsAddition.create  :group_loan_membership_id => @glm_1.id , 
                                              :amount => @glm_1.group_loan_product.weekly_payment_amount,
                                              :employee_id => @employee.id ,
                                              :group_loan_id => @group_loan.id 
    @savings_addition.confirm
    
    @glw_payment =  GroupLoanWeeklyPayment.create_object({
      :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
      :group_loan_membership_id            => @glm_1.id                                           ,
      :group_loan_id                       => @group_loan.id                                      ,
      :number_of_backlogs                  => 0                                                   ,
      :is_paying_current_week              => false                                                ,
      :is_only_savings                     => false                                               ,
      :is_no_payment                       => true                                               ,
      :is_only_voluntary_savings           => false ,
      :number_of_future_weeks              => 0                                                   ,
      :voluntary_savings_withdrawal_amount => BigDecimal('500')                                                   ,
      :cash_amount                         =>  0
    })
    
    @glw_payment.should_not be_valid
  end
  
  it 'should not allow savings withdrawal on only_savings declaration' do
    @savings_addition = GroupLoanVoluntarySavingsAddition.create  :group_loan_membership_id => @glm_1.id , 
                                              :amount => @glm_1.group_loan_product.weekly_payment_amount,
                                              :employee_id => @employee.id ,
                                              :group_loan_id => @group_loan.id 
    @savings_addition.confirm
    
    @glw_payment =  GroupLoanWeeklyPayment.create_object({
      :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
      :group_loan_membership_id            => @glm_1.id                                           ,
      :group_loan_id                       => @group_loan.id                                      ,
      :number_of_backlogs                  => 0                                                   ,
      :is_paying_current_week              => false                                                ,
      :is_only_savings                     => true                                               ,
      :is_no_payment                       => false                                               ,
      :is_only_voluntary_savings           => false ,
      :number_of_future_weeks              => 0                                                   ,
      :voluntary_savings_withdrawal_amount => BigDecimal('500')                                                   ,
      :cash_amount                         =>  0
    })
    
    @glw_payment.should_not be_valid
  end
  
  
  it "should only select one mode of current week payment" do 
    
    
    
    @glw_payment =  GroupLoanWeeklyPayment.create_object({
      :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
      :group_loan_membership_id            => @glm_1.id                                           ,
      :group_loan_id                       => @group_loan.id                                      ,
      :number_of_backlogs                  => 0                                                   ,
      :is_paying_current_week              => true                                                ,
      :is_only_savings                     => true                                               ,
      :is_no_payment                       => false                                               ,
      :is_only_voluntary_savings           => false ,
      :number_of_future_weeks              => 0                                                   ,
      :voluntary_savings_withdrawal_amount => 0                                                   ,
      :cash_amount                         => @glm_1.group_loan_product.weekly_payment_amount
    })
    
    # @glw_payment.can_only_select_one_weekly_payment_mode
    @glw_payment.all_fields_present?.should be_true 
    
    # @glw_payment.errors.size.should_not == 0 
    # @glw_payment.errors.size.should_not == 0 
    # 
    @glw_payment.should_not be_valid
    
    @glw_payment =  GroupLoanWeeklyPayment.create_object({
      :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
      :group_loan_membership_id            => @glm_1.id                                           ,
      :group_loan_id                       => @group_loan.id                                      ,
      :number_of_backlogs                  => 0                                                   ,
      :is_paying_current_week              => true                                                ,
      :is_only_savings                     => false                                               ,
      :is_no_payment                       => true                                               ,
      :is_only_voluntary_savings           => false ,
      :number_of_future_weeks              => 0                                                   ,
      :voluntary_savings_withdrawal_amount => 0                                                   ,
      :cash_amount                         => @glm_1.group_loan_product.weekly_payment_amount
    })
    
    @glw_payment.should_not be_valid
    
    @glw_payment =  GroupLoanWeeklyPayment.create_object({
      :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
      :group_loan_membership_id            => @glm_1.id                                           ,
      :group_loan_id                       => @group_loan.id                                      ,
      :number_of_backlogs                  => 0                                                   ,
      :is_paying_current_week              => false                                                ,
      :is_only_savings                     => false                                               ,
      :is_no_payment                       => true                                               ,
      :is_only_voluntary_savings           => false ,
      :number_of_future_weeks              => 0                                                   ,
      :voluntary_savings_withdrawal_amount => 0                                                   ,
      :cash_amount                         => @glm_1.group_loan_product.weekly_payment_amount
    })
    
    @glw_payment.should_not be_valid
    
    @glw_payment =  GroupLoanWeeklyPayment.create_object({
      :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
      :group_loan_membership_id            => @glm_1.id                                           ,
      :group_loan_id                       => @group_loan.id                                      ,
      :number_of_backlogs                  => 0                                                   ,
      :is_paying_current_week              => false                                                ,
      :is_only_savings                     => true                                               ,
      :is_no_payment                       => false                                               ,
      :is_only_voluntary_savings           => false ,
      :number_of_future_weeks              => 0                                                   ,
      :voluntary_savings_withdrawal_amount => 0                                                   ,
      :cash_amount                         => @glm_1.group_loan_product.weekly_payment_amount
    })
    
    @glw_payment.should be_valid
  end
  
  it 'should have valid amount of paymnet' do
    @glw_payment =  GroupLoanWeeklyPayment.create_object({
      :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
      :group_loan_membership_id            => @glm_1.id                                           ,
      :group_loan_id                       => @group_loan.id                                      ,
      :number_of_backlogs                  => 0                                                   ,
      :is_paying_current_week              => true                                                ,
      :is_only_savings                     => false                                               ,
      :is_no_payment                       => false                                               ,
      :is_only_voluntary_savings           => false ,
      :number_of_future_weeks              => 0                                                   ,
      :voluntary_savings_withdrawal_amount => 0                                                   ,
      :cash_amount                         => @glm_1.group_loan_product.weekly_payment_amount  - BigDecimal("500")
    })
    
    @glw_payment.should_not be_valid
  end
  
  it 'should not allow is_only_voluntary_savings if the current week is not cleared' do
    @glw_payment =  GroupLoanWeeklyPayment.create_object({
      :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
      :group_loan_membership_id            => @glm_1.id                                           ,
      :group_loan_id                       => @group_loan.id                                      ,
      :number_of_backlogs                  => 0                                                   ,
      :is_paying_current_week              => false                                                ,
      :is_only_savings                     => false                                               ,
      :is_no_payment                       => false                                               ,
      :is_only_voluntary_savings           => true ,
      :number_of_future_weeks              => 0                                                   ,
      :voluntary_savings_withdrawal_amount => 0                                                   ,
      :cash_amount                         => @glm_1.group_loan_product.weekly_payment_amount 
    })

    @glw_payment.should_not be_valid
  end
  
  it 'should not allow payment with voluntary savings if it is not sufficient' do
    @glw_payment =  GroupLoanWeeklyPayment.create_object({
      :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
      :group_loan_membership_id            => @glm_1.id                                           ,
      :group_loan_id                       => @group_loan.id                                      ,
      :number_of_backlogs                  => 0                                                   ,
      :is_paying_current_week              => false                                                ,
      :is_only_savings                     => false                                               ,
      :is_no_payment                       => false                                               ,
      :is_only_voluntary_savings           => true ,
      :number_of_future_weeks              => 0                                                   ,
      :voluntary_savings_withdrawal_amount => @glm_1.group_loan_product.weekly_payment_amount                                                   ,
      :cash_amount                         => 0
    })

    @glw_payment.should_not be_valid
  end
  
  context "payment using voluntary savings" do
    before(:each) do
      # add the voluntary savings (manual voluntary savings addition)
      @initial_voluntary_savings = @glm_1.total_voluntary_savings 
      @savings_addition = GroupLoanVoluntarySavingsAddition.create  :group_loan_membership_id => @glm_1.id , 
                                                :amount => @glm_1.group_loan_product.weekly_payment_amount,
                                                :employee_id => @employee.id ,
                                                :group_loan_id => @group_loan.id 
      @savings_addition.confirm 
      
      @glm_1.reload 
    end
    
    it 'should increase voluntary savings by the savings_addition amount' do
     @final_voluntary_savings = @glm_1.total_voluntary_savings 
     diff = @final_voluntary_savings - @initial_voluntary_savings
     diff.should == @savings_addition.amount 
    end
    
    it 'should be allowed to make group_loan_weekly_paymnet using savings_withdrawal ' do
      @glw_payment =  GroupLoanWeeklyPayment.create_object({
        :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
        :group_loan_membership_id            => @glm_1.id                                           ,
        :group_loan_id                       => @group_loan.id                                      ,
        :number_of_backlogs                  => 0                                                   ,
        :is_paying_current_week              => true                                                ,
        :is_only_savings                     => false                                               ,
        :is_no_payment                       => false                                               ,
        :is_only_voluntary_savings           => false ,
        :number_of_future_weeks              => 0                                                   ,
        :voluntary_savings_withdrawal_amount => @glm_1.group_loan_product.weekly_payment_amount                                                  ,
        :cash_amount                         => 0
      })

      @glw_payment.should be_valid
    end
  end
  
  context "on weekly_task confirmation, will generate the 1 transaction activity, 1 savings_entry for just enough weekly payment" do
    before(:each) do
      @glm_1 = @group_loan.active_group_loan_memberships[0]
      @initial_compulsory_savings_1 = @glm_1.total_compulsory_savings 
      @payment_1 = nil
      
      @group_loan.active_group_loan_memberships.each do |glm|
        
        payment = GroupLoanWeeklyPayment.create_object({
          :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
          :group_loan_membership_id            => glm.id                                           ,
          :group_loan_id                       => @group_loan.id                                      ,
          :number_of_backlogs                  => 0                                                   ,
          :is_paying_current_week              => true                                                ,
          :is_only_savings                     => false                                               ,
          :is_no_payment                       => false                                               ,
          :is_only_voluntary_savings           => false ,
          :number_of_future_weeks              => 0                                                   ,
          :voluntary_savings_withdrawal_amount =>    0                                                ,
          :cash_amount                         => glm.group_loan_product.weekly_payment_amount
        })
        
        @payment_1 = payment if glm.id == @glm_1.id 
        
        
        # mark attendance 
        @weekly_responsibility = glm.weekly_responsibility( @active_weekly_task ) 
        
        @weekly_responsibility.mark_member_attendance({
          :attendance_status => GROUP_LOAN_WEEKLY_ATTENDANCE_STATUS[:present] ,
          :attendance_note => "haha"
        })
      end
      
      
      
      @active_weekly_task.confirm({
        :collection_datetime => DateTime.now, 
        :employee_id => @employee.id
      })
      
      @payment_1.reload 
      @glm_1.reload 
    end
    
    it " should confirm active_weekly_task" do
      @active_weekly_task.is_confirmed.should be_true 
    end
    
    it 'should create confirmed payment' do
      @payment_1.is_confirmed.should be_true 
    end
    
    it 'should create 1 transaction activity for each payment' do
      @payment_1.transaction_activity.should_not be_nil
      @payment_1.transaction_activity.should be_valid 
      
    end
    
    it 'should increase the compulsory savings' do
      @final_compulsory_savings_1 = @glm_1.total_compulsory_savings 
      diff = @final_compulsory_savings_1 - @initial_compulsory_savings_1
      diff.should == @glm_1.group_loan_product.min_savings
    end
  end
  
  context "on weekly task confirmation, it will generate 1 transaction activity, 2 savings_entry for payment: with saving withdrawal, compulsory savings" do
    before(:each) do
      @glm_1 = @group_loan.active_group_loan_memberships[0]
      @initial_compulsory_savings_1 = @glm_1.total_compulsory_savings 
      @payment_1 = nil
      
      @voluntary_savings = BigDecimal('1000') 
      @used_voluntary_savings = BigDecimal('500')
      
      @group_loan.active_group_loan_memberships.each do |glm|
        @voluntary_savings_addition = GroupLoanVoluntarySavingsAddition.create  :group_loan_membership_id => glm.id , 
                                                  :amount => @voluntary_savings ,
                                                  :employee_id => @employee.id ,
                                                  :group_loan_id => @group_loan.id
                                                
      
        @voluntary_savings_addition.confirm 
      end
      
      @glm_1.reload 
      @group_loan.reload 
      
      @initial_voluntary_savings_1 = @glm_1.total_voluntary_savings 
      
      @group_loan.active_group_loan_memberships.each do |glm|
        
        payment = GroupLoanWeeklyPayment.create_object({
          :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
          :group_loan_membership_id            => glm.id                                           ,
          :group_loan_id                       => @group_loan.id                                      ,
          :number_of_backlogs                  => 0                                                   ,
          :is_paying_current_week              => true                                                ,
          :is_only_savings                     => false                                               ,
          :is_no_payment                       => false                                               ,
          :is_only_voluntary_savings           => false ,
          :number_of_future_weeks              => 0                                                   ,
          :voluntary_savings_withdrawal_amount =>    @used_voluntary_savings                                               ,
          :cash_amount                         => glm.group_loan_product.weekly_payment_amount - @used_voluntary_savings
        })
        
        @payment_1 = payment if glm.id == @glm_1.id 
        
        
        # mark attendance 
        @weekly_responsibility = glm.weekly_responsibility( @active_weekly_task ) 
        
        @weekly_responsibility.mark_member_attendance({
          :attendance_status => GROUP_LOAN_WEEKLY_ATTENDANCE_STATUS[:present] ,
          :attendance_note => "haha"
        })
      end
      
      
      
      @active_weekly_task.confirm({
        :collection_datetime => DateTime.now, 
        :employee_id => @employee.id
      })
      
      @payment_1.reload 
      @glm_1.reload
    end
    
    it 'should have confirmed the active weekly task ' do
      @active_weekly_task.is_confirmed.should be_true 
    end
    
    it 'should create confirmed payment' do
      @payment_1.is_confirmed.should be_true 
    end
    
    it 'should create 1 transaction activity for each payment' do
      transaction_activity = @payment_1.transaction_activity
      transaction_activity.should_not be_nil
      transaction_activity.should be_valid
      
      
      transaction_activity.transaction_source_id .should == @payment_1.id  
      transaction_activity.transaction_source_type.should == @payment_1.class.to_s
      transaction_activity.cash.should == @glm_1.group_loan_product.weekly_payment_amount - @used_voluntary_savings
      transaction_activity.cash_direction.should == FUND_DIRECTION[:incoming]
      transaction_activity.savings_direction.should == FUND_DIRECTION[:outgoing]
      transaction_activity.savings.should == @used_voluntary_savings
      transaction_activity.member_id.should == @glm_1.member_id  
    end
    
    it 'should increase the compulsory savings' do
      @final_compulsory_savings_1 = @glm_1.total_compulsory_savings 
      diff = @final_compulsory_savings_1 - @initial_compulsory_savings_1
      diff.should == @glm_1.group_loan_product.min_savings
    end
    
    it 'should create 2 savings entry' do
      @payment_1.savings_entries.count.should == 2 
    end
    
    it 'should deduct the voluntary savings' do
      
      @final_voluntary_savings_1 = @glm_1.total_voluntary_savings 
      diff = @initial_voluntary_savings_1 - @final_voluntary_savings_1 
      diff.should == @used_voluntary_savings
    end
  end
  
  context "on weekly_task_confirmation, it will generate 1 transaction activity, 3 savings entry: savings withdarawal, extra savings, and compulsory savings" do
    before(:each) do
      @glm_1 = @group_loan.active_group_loan_memberships[0]
      @initial_compulsory_savings_1 = @glm_1.total_compulsory_savings 
      @payment_1 = nil
      
      @voluntary_savings = BigDecimal('1000') 
      @used_voluntary_savings = BigDecimal('500')
      @extra_voluntary_savings = BigDecimal('100')
      
      @group_loan.active_group_loan_memberships.each do |glm|
        @voluntary_savings_addition = GroupLoanVoluntarySavingsAddition.create  :group_loan_membership_id => glm.id , 
                                                  :amount => @voluntary_savings ,
                                                  :employee_id => @employee.id ,
                                                  :group_loan_id => @group_loan.id
                                                
      
        @voluntary_savings_addition.confirm 
      end
      
      @glm_1.reload 
      @group_loan.reload 
      
      @initial_voluntary_savings_1 = @glm_1.total_voluntary_savings 
      
      @group_loan.active_group_loan_memberships.each do |glm|
        
        payment = GroupLoanWeeklyPayment.create_object({
          :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
          :group_loan_membership_id            => glm.id                                           ,
          :group_loan_id                       => @group_loan.id                                      ,
          :number_of_backlogs                  => 0                                                   ,
          :is_paying_current_week              => true                                                ,
          :is_only_savings                     => false                                               ,
          :is_no_payment                       => false                                               ,
          :is_only_voluntary_savings           => false ,
          :number_of_future_weeks              => 0                                                   ,
          :voluntary_savings_withdrawal_amount =>    @used_voluntary_savings                                               ,
          :cash_amount                         => glm.group_loan_product.weekly_payment_amount - @used_voluntary_savings + @extra_voluntary_savings
        })
        
        @payment_1 = payment if glm.id == @glm_1.id 
        
        
        # mark attendance 
        @weekly_responsibility = glm.weekly_responsibility( @active_weekly_task ) 
        
        @weekly_responsibility.mark_member_attendance({
          :attendance_status => GROUP_LOAN_WEEKLY_ATTENDANCE_STATUS[:present] ,
          :attendance_note => "haha"
        })
      end
      
      
      
      @active_weekly_task.confirm({
        :collection_datetime => DateTime.now, 
        :employee_id => @employee.id
      })
      
      @payment_1.reload 
      @glm_1.reload
    end
    
    it 'should have confirmed the active weekly task ' do
      @active_weekly_task.is_confirmed.should be_true 
    end
    
    it 'should create confirmed payment' do
      @payment_1.is_confirmed.should be_true 
    end
    
    it 'should create 1 transaction activity for each payment' do
      transaction_activity = @payment_1.transaction_activity
      transaction_activity.should_not be_nil
      transaction_activity.should be_valid
      
      
      transaction_activity.transaction_source_id .should == @payment_1.id  
      transaction_activity.transaction_source_type.should == @payment_1.class.to_s
      transaction_activity.cash.should == @glm_1.group_loan_product.weekly_payment_amount - @used_voluntary_savings + @extra_voluntary_savings
      transaction_activity.cash_direction.should == FUND_DIRECTION[:incoming]
      transaction_activity.savings_direction.should == FUND_DIRECTION[:outgoing]
      transaction_activity.savings.should == @used_voluntary_savings
      transaction_activity.member_id.should == @glm_1.member_id  
    end
    
    it 'should increase the compulsory savings' do
      @final_compulsory_savings_1 = @glm_1.total_compulsory_savings 
      diff = @final_compulsory_savings_1 - @initial_compulsory_savings_1
      diff.should == @glm_1.group_loan_product.min_savings
    end
    
    it 'should create 3 savings entry' do
      @payment_1.savings_entries.count.should == 3
    end
    
    it 'should deduct the voluntary savings' do
      @final_voluntary_savings_1 = @glm_1.total_voluntary_savings 
      diff = @initial_voluntary_savings_1 - @final_voluntary_savings_1 
      diff.should == @used_voluntary_savings - @extra_voluntary_savings
    end
  end
end
