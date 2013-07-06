require 'spec_helper'

describe GroupLoanBacklog do
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
  
  context "[only_savings]" do
    before(:each) do
      @glm_1 = @group_loan.active_group_loan_memberships[0]
      @initial_compulsory_savings_1 = @glm_1.total_compulsory_savings 
      @initial_voluntary_savings_1 = @glm_1.total_voluntary_savings 
      @payment_1 = nil
      @savings_amount = BigDecimal('500')
      @group_loan.active_group_loan_memberships.each do |glm|
        
        payment = GroupLoanWeeklyPayment.create_object({
          :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
          :group_loan_membership_id            => glm.id                                           ,
          :group_loan_id                       => @group_loan.id                                      ,
          :number_of_backlogs                  => 0                                                   ,
          :is_paying_current_week              => false                                                ,
          :is_only_savings                     => true                                               ,
          :is_no_payment                       => false                                               ,
          :is_only_voluntary_savings           => false ,
          :number_of_future_weeks              => 0                                                   ,
          :voluntary_savings_withdrawal_amount =>    0                                                ,
          :cash_amount                         => @savings_amount
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
    
    it 'should NOT increase the compulsory savings' do
      @final_compulsory_savings_1 = @glm_1.total_compulsory_savings 
      diff = @final_compulsory_savings_1 - @initial_compulsory_savings_1
      diff.should == BigDecimal('0')
    end
    
    it 'should increase the voluntary savings' do
      @final_voluntary_savings_1 = @glm_1.total_voluntary_savings 
      diff = @final_voluntary_savings_1 - @initial_voluntary_savings_1
      diff.should == @savings_amount
    end
    
    it 'should generate backlog, equal to the number of active_glm' do
      @group_loan.active_group_loan_memberships.count.should == GroupLoanBacklog.count 
    end
    
    it 'should produce 1 unpaid backlog for glm_1' do
      @glm_1.unpaid_backlogs.count.should == 1 
    end
    
    it 'should clear the weekly_responsibility' do
      @active_weekly_task.reload 
      @active_weekly_task.group_loan_weekly_responsibilities.where(:has_clearance => false).count.should == 0 
    end
  end
  
  context "[no_payment_declaration]" do
    before(:each) do
      @glm_1 = @group_loan.active_group_loan_memberships[0]
      @initial_compulsory_savings_1 = @glm_1.total_compulsory_savings 
      @initial_voluntary_savings_1 = @glm_1.total_voluntary_savings 
      @payment_1 = nil
      @savings_amount = BigDecimal('500')
      @group_loan.active_group_loan_memberships.each do |glm|
        
        payment = GroupLoanWeeklyPayment.create_object({
          :group_loan_weekly_task_id           => @active_weekly_task.id                              ,
          :group_loan_membership_id            => glm.id                                           ,
          :group_loan_id                       => @group_loan.id                                      ,
          :number_of_backlogs                  => 0                                                   ,
          :is_paying_current_week              => false                                                ,
          :is_only_savings                     => false                                               ,
          :is_no_payment                       => true                                               ,
          :is_only_voluntary_savings           => false ,
          :number_of_future_weeks              => 0                                                   ,
          :voluntary_savings_withdrawal_amount =>    0                                                ,
          :cash_amount                         => 0
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
    
    it 'should NOT create transaction activity for each payment' do
      @payment_1.transaction_activity.should be_nil
    end
    
    it 'should NOT increase the compulsory savings' do
      @final_compulsory_savings_1 = @glm_1.total_compulsory_savings 
      diff = @final_compulsory_savings_1 - @initial_compulsory_savings_1
      diff.should == BigDecimal('0')
    end
    
    it 'should NOT increase the voluntary savings' do
      @final_voluntary_savings_1 = @glm_1.total_voluntary_savings 
      diff = @final_voluntary_savings_1 - @initial_voluntary_savings_1
      diff.should == BigDecimal('0')
    end
    
    it 'should generate backlog, equal to the number of active_glm' do
      @group_loan.active_group_loan_memberships.count.should == GroupLoanBacklog.count 
    end
    
    it 'should produce 1 unpaid backlog for glm_1' do
      @glm_1.unpaid_backlogs.count.should == 1 
    end
    
    it 'should clear the weekly_responsibility' do
      @active_weekly_task.reload 
      @active_weekly_task.group_loan_weekly_responsibilities.where(:has_clearance => false).count.should == 0 
    end
  end
  
   
end
