class Council < ApplicationRecord
  has_many :meetings
  has_many :decisions
  has_many :committees
  has_many :meeting_documents, through: :meetings, source: :documents
  has_many :decision_documents, through: :decisions, source: :documents
  has_many :people, class_name: 'Person'

  enum council_type: { modern_gov: 0, cmis: 1 }

  def documents
    meeting_documents + decision_documents
  end
end
