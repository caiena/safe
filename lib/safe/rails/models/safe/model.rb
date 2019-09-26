module SAFE
  class Model < ActiveRecord::Base

    self.abstract_class = true

    def self.table_name_prefix
      'safe_'
    end

  end
end
