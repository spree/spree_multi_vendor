require 'spec_helper'

module Spree
  module Admin
    class ExampleResourcesController < Spree::Admin::ResourceController
      def new
        super
        head :ok
      end

      def model_class
        Spree::ShippingMethod
      end
    end
  end
end

RSpec.describe Spree::Admin::ExampleResourcesController, type: :controller do
  stub_authorization!

  let(:vendor) { create(:vendor) }
  let(:admin_user) { create(:vendor_user, vendor: vendor) }

  after(:all) do
    Rails.application.reload_routes!
  end

  before do
    Spree::Core::Engine.routes.draw do
      namespace :admin do
        resources :example_resources
      end
    end
  end

  describe '#new' do
    subject { get :new }

    it 'assigns a vendor to the resource' do
      subject
      expect(assigns(:object).vendor).to eq(vendor)
    end
  end
end
