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
                        :initial_savings,
                        :name 
        
  
  has_many :group_loan_subcriptions
  has_many :group_loan_memberships, :through => :group_loan_subcriptions
  
  
  validate :total_weeks_must_not_be_zero
  validate :no_negative_payment_amount 
  
  validate :allow_update_if_no_subcriptions
  
  def total_weeks_must_not_be_zero
    return  if not all_fields_present? 
    if  total_weeks <=  0 
      errors.add(:total_weeks, "Jumlah minggu cicilan harus lebih besar dari 0")
    end
  end
  
  def no_negative_payment_amount
    return  if not all_fields_present? 
    
    zero_amount = BigDecimal('0')
    
    if principal <= zero_amount
      errors.add(:principal, "Cicilan Principal  tidak boleh negative")
    end
    
    if interest <= zero_amount
      errors.add(:interest, "Bunga tidak boleh negative")
    end
    
    if min_savings <= zero_amount
      errors.add(:min_savings, "Tabungan wajib tidak boleh negative")
    end
    
    if admin_fee <= zero_amount
      errors.add(:admin_fee, "Biaya administrasi tidak boleh negative")
    end
    
    if initial_savings <= zero_amount
      errors.add(:initial_savings, "Simpanan awal tidak boleh negative")
    end
  end
  
  def allow_update_if_no_subcriptions
    return  if not all_fields_present? 
    
    if self.persisted? and self.group_loan_subcriptions.count != 0 
      self.errors.add(:generic_errors, "Sudah ada peminjaman dengan menggunakan product ini")
    end
  end
  
  def all_fields_present?
    name.present? and 
    office_id.present? and 
    total_weeks.present? and 
    principal.present?              and   
    interest.present?               and   
    min_savings.present?            and   
    admin_fee.present?              and
    initial_savings.present? 
  end
  
  
  def self.create_object(   params) 
    new_object                 = self.new 
    new_object.name            = params[:name]
    new_object.office_id       = params[:office_id]
    new_object.total_weeks     = params[:total_weeks]
    new_object.principal       = BigDecimal( params[:principal] || '0')
    new_object.interest        = BigDecimal( params[:interest        ] || '0')
    new_object.min_savings     = BigDecimal( params[:min_savings     ] || '0')
    new_object.admin_fee       = BigDecimal( params[:admin_fee       ] || '0')
    new_object.initial_savings = BigDecimal( params[:initial_savings ] || '0')
    
    
    new_object.save 
    return new_object
  end
  
  def update_object( params ) 
    
    self.name            = params[:name]
    self.total_weeks     = params[:total_weeks]
    self.principal       = BigDecimal( params[:principal] || '0')
    self.interest        = BigDecimal( params[:interest        ] || '0')
    self.min_savings     = BigDecimal( params[:min_savings     ] || '0')
    self.admin_fee       = BigDecimal( params[:admin_fee       ] || '0')
    self.initial_savings = BigDecimal( params[:initial_savings ] || '0')
    
    self.save 
    return self
  end
  
  def delete_object
    allow_update_if_no_subcriptions # validation 
    return if self.errors.size != 0 
    
    self.destroy 
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
