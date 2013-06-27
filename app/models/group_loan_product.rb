class GroupLoanProduct < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :office 
  has_many :group_loan_subcriptions  
  
  validates_presence_of :office_id, 
                        :total_weeks, 
                        :principal,
                        :interest,
                        :min_savings,
                        :admin_fee, 
                        :initial_savings
        
  
  has_many :group_loan_subcriptions
  has_many :group_loan_memberships, :through => :group_loan_subcriptions
  
  
  validate :total_weeks_must_not_be_zero
  validate :no_negative_payment_amount 
  
  def total_weeks_must_not_be_zero
    if total_weeks.present? and total_weeks <=  0 
      errors.add(:total_weeks, "Jumlah minggu cicilan harus lebih besar dari 0")
    end
  end
  
  def no_negative_payment_amount
    zero_amount = BigDecimal('0')
    if principal.present? and principal <= zero_amount
      errors.add(:principal, "Cicilan Principal  tidak boleh negative")
    end
    
    if interest.present? and interest <= zero_amount
      errors.add(:interest, "Bunga tidak boleh negative")
    end
    
    if min_savings.present? and min_savings <= zero_amount
      errors.add(:min_savings, "Tabungan wajib tidak boleh negative")
    end
    
    if admin_fee.present? and admin_fee <= zero_amount
      errors.add(:admin_fee, "Biaya administrasi tidak boleh negative")
    end
    
    if initial_savings.present? and initial_savings <= zero_amount
      errors.add(:initial_savings, "Simpanan awal tidak boleh negative")
    end
  end
  
  def self.create_object(   params) 
    new_object = self.new 
    new_object.office_id         = params[:office_id]
    new_object.total_weeks       = params[:total_weeks]
    new_object.principal         = BigDecimal( params[:principal] || '0')
    new_object.interest          = BigDecimal( params[:interest        ] || '0')
    new_object.min_savings       = BigDecimal( params[:min_savings     ] || '0')
    new_object.admin_fee         = BigDecimal( params[:admin_fee       ] || '0')
    new_object.initial_savings   = BigDecimal( params[:initial_savings ] || '0')
    
    
    new_object.save 
    return new_object
  end
  
  def self.update_object( params ) 
    return nil if self.group_loan_subcriptions.count != 0
    
    self.total_weeks       = params[:total_weeks]
    self.principal         = BigDecimal( params[:principal] || '0')
    self.interest          = BigDecimal( params[:interest        ] || '0')
    self.min_savings       = BigDecimal( params[:min_savings     ] || '0')
    self.admin_fee         = BigDecimal( params[:admin_fee       ] || '0')
    self.initial_savings   = BigDecimal( params[:initial_savings ] || '0')
    
    
    self.save 
    return self
  end
  
  def disbursed_principal
    principal * total_weeks 
  end
  
  
  def weekly_payment_amount
    principal + interest  + min_savings
  end
  
  def grace_period_weekly_payment_amount
    principal + interest 
  end
  
  
end
