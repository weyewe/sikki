require 'spec_helper'

describe GroupLoan do
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
    
    
  end
  
  
  context "all members present in financial education" do
    before(:each) do
      @group_loan.active_group_loan_memberships.each do |glm|
        glm.mark_financial_education_attendance( {
          :is_attending_financial_education => true 
        } )
      end
    end

    it 'should not allow loan disbursement attendance marking if not in loan disbursement phase' do
      @glm_1 = @group_loan.active_group_loan_memberships.first 

      @glm_1.mark_loan_disbursement_attendance( {
        :is_attending_loan_disbursement => true 
      } )

      @glm_1.errors.size.should_not == 0 
    end


    context "switching to loan disbursement phase" do 
      before(:each) do
        @group_loan.finalize_financial_education 
        @group_loan.reload
      end

      it 'should be allowed to mark loan disbursement attendance' do
        @glm_1 = @group_loan.active_group_loan_memberships.first 

        @glm_1.mark_loan_disbursement_attendance( {
          :is_attending_loan_disbursement => true 
        } )

        @glm_1.errors.size.should == 0
      end



      context "all members present in loan disbursement" do
        before(:each) do
          @glm_1 = @group_loan.active_group_loan_memberships[0]
          
          @initial_active_glm = @group_loan.active_group_loan_memberships.count 
          @initial_compulsory_savings_glm_1 = @glm_1.total_compulsory_savings 
          
          @group_loan.active_group_loan_memberships.each do |glm|
            glm.mark_loan_disbursement_attendance( {
              :is_attending_loan_disbursement => true 
            } )
          end
          @group_loan.finalize_loan_disbursement
          
          @glm_1.reload
        end
        
        it 'should allow loan disbursement finalization' do
          
          @group_loan.reload 
          @group_loan.is_loan_disbursement_finalized.should be_true 
        end
        
        it 'should preserve the active glm count' do
          @group_loan.reload
          @final_active_glm = @group_loan.active_group_loan_memberships.count 
          @initial_active_glm.should == @final_active_glm
        end
        
        it 'should create GroupLoanDisbursement for all active members after loan disbursement' do
          GroupLoanDisbursement.count.should == @group_loan.active_group_loan_memberships.count 
        end
        
        # the by product: transaction and savings 
        it 'should have created 3 transaction activities' do
          
          @glm_1.group_loan_disbursement.should be_valid 
          @glm_1.group_loan_disbursement.transaction_activities.count.should == 3 
          @glm_1.group_loan_disbursement.savings_entries.count.should == 1 
          
          
          # 3 transaction activities:
          #1. company gives the $$$
          #2. member pay the setup fee
          #3. member pays the initial compulsory savings 
        end 
        
        it 'should increase the total compulsory savings by group_loan_product.initial_savings' do
          @final_compulsory_savings_glm_1 = @glm_1.total_compulsory_savings 
          diff  = @final_compulsory_savings_glm_1 - @initial_compulsory_savings_glm_1 
          
          diff.should ==  @glm_1.group_loan_product.initial_savings
        end
        
        it "shouldnt allow group loan product change" do
          subcription = @glm_1.group_loan_subcription 
          subcription.update_object({
            :group_loan_product_id => subcription.group_loan_product_id 
          })
          
          subcription.errors.size.should_not == 0 
        end
      end
      
      
      
      # corner cases 
      context "several members are absent in loan disbursment" do
        before(:each) do
          
          @initial_active_glm = @group_loan.active_group_loan_memberships.count 
          @glm_1 = @group_loan.active_group_loan_memberships[0]
          @glm_2 = @group_loan.active_group_loan_memberships[1]
          @group_loan.active_group_loan_memberships.each do |glm|
            attendance = true 
            attendance = false  if [@glm_1.id, @glm_2.id].include?(glm.id)
            
            glm.mark_loan_disbursement_attendance( {
              :is_attending_loan_disbursement => attendance 
            } )
          end
        end
        
        it 'should allow loan disbursement finalization' do
          @group_loan.finalize_loan_disbursement
          @group_loan.reload 
          @group_loan.is_loan_disbursement_finalized.should be_true 
        end
        
        it 'should deduct the active glm count' do
          @group_loan.finalize_loan_disbursement
          @group_loan.reload
          @final_active_glm = @group_loan.active_group_loan_memberships.count 
          @final_active_glm.should == @initial_active_glm   - 2
        end
      end

      context "some members are unmarked" do
        before(:each) do
          
          @initial_active_glm = @group_loan.active_group_loan_memberships.count 
          @glm_1 = @group_loan.active_group_loan_memberships[0]
          @glm_2 = @group_loan.active_group_loan_memberships[1]
          
          @group_loan.active_group_loan_memberships.each do |glm|
            
            next   if [@glm_1.id, @glm_2.id].include?(glm.id)
            
            glm.mark_loan_disbursement_attendance( {
              :is_attending_loan_disbursement => true  
            } )
          end
        end
        
        it 'should not allow loan disbursment finalization' do
          @group_loan.finalize_loan_disbursement
          @group_loan.reload
          
          @group_loan.errors.size.should_not == 0 
          @group_loan.is_loan_disbursement_finalized.should be_false 
        end
      end 
    end
  end
  
  
  
  # ensuring that no hacketing hack happen (self-write the AJAX params)
  context "some members are absent during financial education" do
    before(:each) do
      @glm_1 = @group_loan.active_group_loan_memberships[0]
      
      @group_loan.active_group_loan_memberships.each do |glm|
        attendance  = true 
        attendance = false if @glm_1.id == glm.id 
        glm.mark_financial_education_attendance( {
          :is_attending_financial_education => attendance 
        } )
      end
      
      @group_loan.finalize_financial_education 
      @group_loan.reload
      @glm_1.reload 
    end
    
    it 'should deactivate the glm_1' do
      @glm_1.is_active.should be_false 
      @glm_1.deactivation_status.should == GROUP_LOAN_DEACTIVATION_STATUS[:financial_education_absent]
    end
    
    it 'should not allow attendance marking for deactivated member' do
      @glm_1.mark_loan_disbursement_attendance( {
        :is_attending_loan_disbursement => true 
      } )
      
      # @glm_1.errors.size.should_not == 0
      @glm_1.is_attending_loan_disbursement.should be_nil 
    end
  end
  
end
