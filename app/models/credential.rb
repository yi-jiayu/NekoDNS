class Credential < ApplicationRecord
  belongs_to :user
  validates_presence_of :name, :arn

  class AccessDenied < StandardError
  end
end
