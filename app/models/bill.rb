class Bill < ActiveRecord::Base
  # attr_accessible :title, :body
  has_many :transact
  has_many :items

end
