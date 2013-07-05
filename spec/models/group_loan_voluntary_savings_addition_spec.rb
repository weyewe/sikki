require 'spec_helper'

describe GroupLoanVoluntarySavingsAddition do
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
  end
  
  
  it 'should be in the weekly payment phase ' do
    @group_loan.is_weekly_payment_period_phase?.should be_true 
  end
  
  it 'should be allowed to create voluntary savings addition' do
    @gl_voluntary_savings_addition = GroupLoanVoluntarySavingsAddition.create  :group_loan_membership_id => @glm_1.id , 
                                              :amount => BigDecimal('500'),
                                              :employee_id => @employee.id ,
                                              :group_loan_id => @group_loan.id
                                              
    @gl_voluntary_savings_addition.should be_valid 
  end
  
  context "create voluntary savings addition" do
    before(:each) do
      @initial_voluntary_savings = @glm_1.total_voluntary_savings
      @gl_voluntary_savings_addition = GroupLoanVoluntarySavingsAddition.create  :group_loan_membership_id => @glm_1.id , 
                                                :amount =>  BigDecimal('500') ,
                                                :employee_id => @employee.id ,
                                                :group_loan_id => @group_loan.id
      @glm_1.reload 
      
    end
    
    it 'should not increase total voluntary savings' do
      @final_voluntary_savings = @glm_1.total_voluntary_savings
      diff =  @final_voluntary_savings - @initial_voluntary_savings
      diff.should == BigDecimal('0')
    end
    
    it 'should be allowed to confirm' do
      @gl_voluntary_savings_addition.confirm 
      @gl_voluntary_savings_addition.is_confirmed.should be_true 
    end
    
    context 'confirming the voluntary savings addition' do
      before(:each) do
        @initial_voluntary_savings = @glm_1.total_voluntary_savings 
        @gl_voluntary_savings_addition.confirm 
        @glm_1.reload 
        @final_voluntary_savings=  @glm_1.total_voluntary_savings 
      end
      
      it 'should increase total voluntary savings ' do 
        diff = @final_voluntary_savings - @initial_voluntary_savings
        diff.should == @gl_voluntary_savings_addition.amount 
      end
      
      it 'should create one saving_entry' do
        savings_entry =  @gl_voluntary_savings_addition.savings_entry 
        savings_entry.should be_valid 
        savings_entry.amount.should == @gl_voluntary_savings_addition.amount 
        savings_entry.direction .should ==  FUND_DIRECTION[:incoming]
      end
    end
  end
  
end
