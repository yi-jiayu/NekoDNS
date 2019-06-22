class Domain < ApplicationRecord
  belongs_to :user
  has_many :records

  def ready?
    has_soa_record = Record.exists?(domain: self, type: 'SOA')
    has_ns_record = Record.exists?(domain: self, type: 'NS')
    has_soa_record && has_ns_record
  end
end
