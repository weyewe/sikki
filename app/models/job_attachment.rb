class JobAttachment < ActiveRecord::Base
  # attr_accessible :title, :body
  belongs_to :office
  belongs_to :user 
end
