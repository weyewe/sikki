class CreateJobAttachments < ActiveRecord::Migration
  def change
    create_table :job_attachments do |t|

      t.timestamps
    end
  end
end
