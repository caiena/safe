module SAFE
  module Rails
    class Engine < ::Rails::Engine

      paths["app/models"] << "lib/safe/rails/models"

    end
  end
end
