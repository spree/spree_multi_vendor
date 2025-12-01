import '@hotwired/turbo-rails'
import { Application } from '@hotwired/stimulus'

let application

if (typeof window.Stimulus === "undefined") {
  application = Application.start()
  application.debug = false
  window.Stimulus = application
} else {
  application = window.Stimulus
}

import SpreeMultiVendorController from 'spree_multi_vendor/controllers/spree_multi_vendor_controller' 

application.register('spree_multi_vendor', SpreeMultiVendorController)