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

ActiveRecord::Schema.define(:version => 20130617091620) do

  create_table "group_loan_default_payments", :force => true do |t|
    t.integer  "group_loan_membership_id"
    t.decimal  "amount_to_be_shared_with_non_defaultee", :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "amount_sub_group_share",                 :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "amount_group_share",                     :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "compulsory_savings_deduction_amount",    :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "voluntary_savings_deduction_amount",     :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "standard_resolution_amount",             :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "custom_resolution_amount",               :precision => 10, :scale => 2, :default => 0.0
    t.decimal  "amount_paid",                            :precision => 10, :scale => 2, :default => 0.0
    t.datetime "created_at",                                                                             :null => false
    t.datetime "updated_at",                                                                             :null => false
  end

  create_table "group_loan_disbursements", :force => true do |t|
    t.integer  "group_loan_membership_id"
    t.integer  "group_loan_product_id"
    t.datetime "created_at",               :null => false
    t.datetime "updated_at",               :null => false
  end

  create_table "group_loan_grace_payments", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "group_loan_independent_payments", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "group_loan_memberships", :force => true do |t|
    t.integer  "member_id"
    t.integer  "group_loan_id"
    t.boolean  "is_active",                    :default => true
    t.integer  "deactivation_status"
    t.boolean  "attended_financial_education", :default => false
    t.boolean  "attended_loan_disbursement",   :default => false
    t.integer  "sub_group_loan_id"
    t.boolean  "is_defaultee",                 :default => false
    t.datetime "created_at",                                      :null => false
    t.datetime "updated_at",                                      :null => false
  end

  create_table "group_loan_products", :force => true do |t|
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

  create_table "group_loan_weekly_attendances", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "group_loan_weekly_payments", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "group_loan_weekly_responsibilities", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "group_loan_weekly_tasks", :force => true do |t|
    t.integer  "group_loan_id"
    t.integer  "week_number"
    t.boolean  "is_closed",                                             :default => false
    t.date     "collection_date"
    t.time     "collection_time_start"
    t.time     "collection_time_end"
    t.decimal  "total_amount_collected", :precision => 12, :scale => 2, :default => 0.0
    t.datetime "created_at",                                                               :null => false
    t.datetime "updated_at",                                                               :null => false
  end

  create_table "group_loans", :force => true do |t|
    t.string   "name"
    t.integer  "office_id"
    t.integer  "group_loan_product_id"
    t.integer  "phase"
    t.decimal  "total_default_amount",            :precision => 11, :scale => 2, :default => 0.0
    t.decimal  "net_income",                      :precision => 11, :scale => 2, :default => 0.0
    t.integer  "group_leader_id"
    t.integer  "default_payment_resolution_case"
    t.boolean  "is_auto_deduct_admin_fee",                                       :default => true
    t.boolean  "is_auto_deduct_initial_savings",                                 :default => true
    t.boolean  "is_compulsory_weekly_attendance",                                :default => true
    t.datetime "created_at",                                                                       :null => false
    t.datetime "updated_at",                                                                       :null => false
  end

  create_table "job_attachments", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "members", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "offices", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "sub_group_loans", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "transaction_activities", :force => true do |t|
    t.integer  "transaction_source_id"
    t.string   "transaction_source_type"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
  end

  create_table "users", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

end
