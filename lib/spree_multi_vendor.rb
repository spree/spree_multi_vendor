require 'spree_core'
require 'spree_extension'
require 'spree_multi_vendor/engine'
require 'spree_multi_vendor/version'
require 'spree_multi_vendor/configuration'

module SpreeMultiVendor
  mattr_accessor :queue

  def self.queue
    @@queue ||= Spree.queues.default
  end
end
