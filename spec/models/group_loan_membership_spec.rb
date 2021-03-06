require 'spec_helper'

describe GroupLoanMembership do
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
    
    # create the second group loan 
    @group_loan_2 = GroupLoan.create_object({
      :office_id => @office.id,
      :name                             => "Group Loan 2" ,
      :is_auto_deduct_admin_fee         => true,
      :is_auto_deduct_initial_savings   => true,
      :is_compulsory_weekly_attendance  => true
    })
    
    
  end
  
  it 'should have created members' do
    Member.count.should == 8 
  end
    
  it 'should not allow member to be a member of another group_loan if he is still an active member of group_loan' do
    @member_1 = Member.first 
    @glm_double = GroupLoanMembership.create_object({
      :group_loan_id => @group_loan_2.id,
      :sub_group_loan_id => nil ,
      :member_id => @member_1.id 
    })
    
    @glm_double.should_not be_valid 
  end
  
  it 'should not allow double group_loan membership of the same member and group_loan' do
    @member_1 = Member.first 
    new_glm = GroupLoanMembership.create_object({
      :group_loan_id => @group_loan.id,
      :sub_group_loan_id => nil ,
      :member_id => @member_1.id 
    })
    
    new_glm.should_not be_valid 
  end
  
  it 'should allow update' do
    first_member = Member.first
    first_member.save 
    first_member.errors.size.should == 0 
  end
  
  
  context "group loan has started" do
    before(:each) do
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
    end
    
    it 'should have been started' do
      @group_loan.is_started.should be_true 
    end
  
    it 'should be able to change sub group' do
      @first_glm = GroupLoanMembership.first 
      
      sub_group = @sub_group_1 
      if @first_glm.sub_group_loan_id == sub_group.id 
        sub_group = @sub_group_2
      end
      
      @first_glm.update_object({
        :group_loan_id => @first_glm.group_loan_id,
        :sub_group_loan_id => sub_group.id  ,
        :member_id => @first_glm.member_id  
      })
      
      @first_glm.should be_valid 
      
      
    end
    
    context "past financial_education phase" do
      before(:each) do
        # finalize the financial education + add marker 
      end
      
      it 'should be able to change sub group' do
        @first_glm = GroupLoanMembership.first 

        sub_group = @sub_group_1 
        if @first_glm.sub_group_loan_id == sub_group.id 
          sub_group = @sub_group_2
        end

        @first_glm.update_object({
          :group_loan_id => @first_glm.group_loan_id,
          :sub_group_loan_id => sub_group.id  ,
          :member_id => @first_glm.member_id  
        })

        @first_glm.should be_valid 


      end
      
      context "past loan disbursement phase" do 
        it 'should not be able to change sub_group'
        
        it 'should not be able to assign group_leader to inactive member' 
        it 'should not be able to assign sub_group_leader to inactive member'
      end
    end
  end
  

 
end
