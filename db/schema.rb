# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20130627062307) do

  create_table "employees", :force => true do |t|
    t.integer  "office_id"
    t.string   "name"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "group_loan_backlogs", :force => true do |t|
    t.integer  "group_loan_membership_id"
    t.integer  "group_loan_id"
    t.integer  "group_loan_weekly_responsibility_id"
    t.boolean  "is_paid",                             :default => false
    t.integer  "backlog_clearance_source_id"
    t.string   "backlog_clearance_source_type"
    t.datetime "created_at",                                             :null => false
    t.datetime "updated_at",                                             :null => false
  end

  create_table "group_loan_default_payments", :force => true do |t|
    t.integer  "group_loan_membership_id"
    t.decimal  "amount_to_be_shared_with_non_defaultee",     :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "amount_sub_group_share",                     :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "amount_group_share",                         :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "compulsory_savings_deduction_amount",        :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "voluntary_savings_deduction_amount",         :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "custom_compulsory_savings_deduction_amount", :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "custom_voluntary_savings_deduction_amount",  :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "standard_resolution_amount",                 :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "custom_resolution_amount",                   :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "amount_paid",                                :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "amount_assumed_by_office",                   :precision => 10, :scale => 2, :default => 0.0
    t.datetime "created_at",                                                                                 :null => false
    t.datetime "updated_at",                                                                                 :null => false
  end

  create_table "group_loan_disbursements", :force => true do |t|
    t.integer  "group_loan_membership_id"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  create_table "group_loan_grace_payments", :force => true do |t|
    t.integer  "group_loan_membership_id"
    t.integer  "group_loan_id"
    t.decimal  "voluntary_savings_withdrawal_amount", :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "cash_amount",                         :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "default_payment_amount",              :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "amount_paid",                         :precision => 9, :scale => 2, :default => 0.0
    t.boolean  "is_confirmed",                                                      :default => false
    t.datetime "confirmation_datetime"
    t.datetime "collection_datetime"
    t.integer  "employee_id"
    t.datetime "created_at",                                                                           :null => false
    t.datetime "updated_at",                                                                           :null => false
  end

  create_table "group_loan_independent_payments", :force => true do |t|
    t.integer  "group_loan_weekly_task_id"
    t.decimal  "voluntary_savings_withdrawal_amount", :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "cash_amount",                         :precision => 9, :scale => 2, :default => 0.0
    t.integer  "number_of_future_weeks"
    t.integer  "number_of_backlogs"
    t.integer  "group_loan_membership_id"
    t.boolean  "is_confirmed",                                                      :default => false
    t.datetime "confirmation_datetime"
    t.datetime "collection_datetime"
    t.integer  "employee_id"
    t.integer  "group_loan_id"
    t.datetime "created_at",                                                                           :null => false
    t.datetime "updated_at",                                                                           :null => false
  end

  create_table "group_loan_memberships", :force => true do |t|
    t.integer  "member_id"
    t.integer  "group_loan_id"
    t.boolean  "is_active",                                                            :default => true
    t.integer  "deactivation_status"
    t.decimal  "outstanding_grace_period_amount",        :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "total_compulsory_savings",               :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "total_voluntary_savings",                :precision => 9, :scale => 2, :default => 0.0
    t.boolean  "is_attending_financial_education"
    t.boolean  "is_attending_loan_disbursement"
    t.integer  "sub_group_loan_id"
    t.boolean  "is_defaultee",                                                         :default => false
    t.decimal  "amount_to_be_shared_with_non_defaultee", :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "closing_withdrawal_amount",              :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "closing_savings_amount",                 :precision => 9, :scale => 2, :default => 0.0
    t.datetime "created_at",                                                                              :null => false
    t.datetime "updated_at",                                                                              :null => false
  end

  create_table "group_loan_port_compulsory_savings", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "group_loan_port_voluntary_savings", :force => true do |t|
    t.integer  "group_loan_membership_id"
    t.decimal  "amount",                   :precision => 9, :scale => 2, :default => 0.0
    t.datetime "created_at",                                                              :null => false
    t.datetime "updated_at",                                                              :null => false
  end

  create_table "group_loan_products", :force => true do |t|
    t.string   "name"
    t.decimal  "principal",       :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "interest",        :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "min_savings",     :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "admin_fee",       :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "initial_savings", :precision => 9, :scale => 2, :default => 0.0
    t.integer  "total_weeks"
    t.integer  "office_id"
    t.datetime "created_at",                                                     :null => false
    t.datetime "updated_at",                                                     :null => false
  end

  create_table "group_loan_subcriptions", :force => true do |t|
    t.integer  "group_loan_membership_id"
    t.integer  "group_loan_product_id"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  create_table "group_loan_voluntary_savings_withdrawals", :force => true do |t|
    t.integer  "group_loan_membership_id"
    t.integer  "group_loan_id"
    t.integer  "employee_id"
    t.decimal  "amount",                   :precision => 9, :scale => 2, :default => 0.0
    t.boolean  "is_confirmed",                                           :default => false
    t.datetime "confirmation_datetime"
    t.datetime "created_at",                                                                :null => false
    t.datetime "updated_at",                                                                :null => false
  end

  create_table "group_loan_weekly_payments", :force => true do |t|
    t.integer  "group_loan_weekly_task_id"
    t.integer  "group_loan_membership_id"
    t.integer  "group_loan_id"
    t.boolean  "is_paying_current_week",                                            :default => true
    t.boolean  "is_only_savings",                                                   :default => false
    t.boolean  "is_no_payment",                                                     :default => false
    t.boolean  "is_only_voluntary_savings",                                         :default => false
    t.decimal  "voluntary_savings_withdrawal_amount", :precision => 9, :scale => 2, :default => 0.0
    t.decimal  "cash_amount",                         :precision => 9, :scale => 2, :default => 0.0
    t.integer  "number_of_backlogs"
    t.integer  "number_of_future_weeks"
    t.boolean  "is_confirmed",                                                      :default => false
    t.datetime "confirmation_datetime"
    t.datetime "created_at",                                                                           :null => false
    t.datetime "updated_at",                                                                           :null => false
  end

  create_table "group_loan_weekly_responsibilities", :force => true do |t|
    t.integer  "group_loan_membership_id"
    t.integer  "group_loan_weekly_task_id"
    t.integer  "attendance_status",            :default => 1
    t.text     "attendance_note"
    t.integer  "payment_status",               :default => 1
    t.string   "clearance_source_type"
    t.integer  "clearance_source_id"
    t.integer  "group_loan_weekly_payment_id"
    t.boolean  "has_clearance",                :default => false
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
  end

  create_table "group_loan_weekly_tasks", :force => true do |t|
    t.integer  "group_loan_id"
    t.integer  "week_number"
    t.datetime "collection_datetime"
    t.integer  "employee_id"
    t.boolean  "is_confirmed",                                          :default => false
    t.datetime "confirmation_datetime"
    t.decimal  "total_amount_collected", :precision => 12, :scale => 2, :default => 0.0
    t.datetime "created_at",                                                               :null => false
    t.datetime "updated_at",                                                               :null => false
  end

  create_table "group_loans", :force => true do |t|
    t.string   "name"
    t.integer  "office_id"
    t.boolean  "is_started",                                                      :default => false
    t.boolean  "is_financial_education_finalized",                                :default => false
    t.boolean  "is_loan_disbursed",                                               :default => false
    t.boolean  "is_weekly_payment_period_closed",                                 :default => false
    t.boolean  "is_grace_payment_period_closed",                                  :default => false
    t.boolean  "is_default_payment_period_closed",                                :default => false
    t.boolean  "is_closed",                                                       :default => false
    t.decimal  "total_default_amount",             :precision => 11, :scale => 2, :default => 0.0
    t.decimal  "net_income",                       :precision => 11, :scale => 2, :default => 0.0
    t.integer  "group_leader_id"
    t.integer  "default_payment_resolution_case",                                 :default => 1
    t.boolean  "is_auto_deduct_admin_fee",                                        :default => true
    t.boolean  "is_auto_deduct_initial_savings",                                  :default => true
    t.boolean  "is_compulsory_weekly_attendance",                                 :default => true
    t.datetime "created_at",                                                                         :null => false
    t.datetime "updated_at",                                                                         :null => false
  end

  create_table "job_attachments", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "members", :force => true do |t|
    t.string   "name"
    t.text     "address"
    t.integer  "office_id"
    t.string   "id_number"
    t.decimal  "total_savings_account", :precision => 12, :scale => 2, :default => 0.0
    t.datetime "created_at",                                                            :null => false
    t.datetime "updated_at",                                                            :null => false
  end

  create_table "offices", :force => true do |t|
    t.string   "name"
    t.string   "address"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "savings_account_payments", :force => true do |t|
    t.integer  "member_id"
    t.decimal  "amount",                :precision => 9, :scale => 2, :default => 0.0
    t.integer  "employee_id"
    t.boolean  "is_confirmed",                                        :default => false
    t.datetime "confirmation_datetime"
    t.datetime "created_at",                                                             :null => false
    t.datetime "updated_at",                                                             :null => false
  end

  create_table "savings_account_withdrawals", :force => true do |t|
    t.integer  "member_id"
    t.decimal  "amount",                :precision => 9, :scale => 2, :default => 0.0
    t.integer  "employee_id"
    t.boolean  "is_confirmed",                                        :default => false
    t.datetime "confirmation_datetime"
    t.datetime "created_at",                                                             :null => false
    t.datetime "updated_at",                                                             :null => false
  end

  create_table "savings_entries", :force => true do |t|
    t.integer  "savings_source_id"
    t.string   "savings_source_type"
    t.decimal  "amount",                 :precision => 9, :scale => 2, :default => 0.0
    t.integer  "savings_status"
    t.integer  "direction"
    t.integer  "financial_product_id"
    t.string   "financial_product_type"
    t.integer  "member_id"
    t.datetime "created_at",                                                            :null => false
    t.datetime "updated_at",                                                            :null => false
  end

  create_table "sub_group_loans", :force => true do |t|
    t.integer  "group_loan_id"
    t.string   "name"
    t.integer  "sub_group_leader_id"
    t.decimal  "sub_group_total_default_payment_amount",               :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "sub_group_default_payment_contribution_amount",        :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "actual_sub_group_default_payment_contribution_amount", :precision => 10, :scale => 2, :default => 0.0
    t.datetime "created_at",                                                                                           :null => false
    t.datetime "updated_at",                                                                                           :null => false
  end

  create_table "transaction_activities", :force => true do |t|
    t.integer  "transaction_source_id"
    t.string   "transaction_source_type"
    t.decimal  "cash",                    :precision => 9, :scale => 2, :default => 0.0
    t.integer  "cash_direction"
    t.decimal  "savings",                 :precision => 9, :scale => 2, :default => 0.0
    t.integer  "savings_direction"
    t.integer  "office_id"
    t.integer  "member_id"
    t.datetime "created_at",                                                             :null => false
    t.datetime "updated_at",                                                             :null => false
  end

  create_table "users", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
