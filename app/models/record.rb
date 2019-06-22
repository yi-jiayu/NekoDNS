class Record < ApplicationRecord
  self.inheritance_column = :no_inheritance

  belongs_to :domain
end
