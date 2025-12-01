module SpreeMultiVendor
  class BaseJob < Spree::BaseJob
    queue_as SpreeMultiVendor.queue
  end
end
