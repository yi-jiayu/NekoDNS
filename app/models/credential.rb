class Credential < ApplicationRecord
  belongs_to :user
  validates_presence_of :name, :arn
end