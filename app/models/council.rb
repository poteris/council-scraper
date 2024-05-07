class Council < ApplicationRecord
  has_many :meetings
  has_many :decisions
  has_many :committees
  has_many :documents, through: :meetings
  has_many :people, class_name: 'Person'

  enum council_type: { modern_gov: 0, cmis: 1 }
end
