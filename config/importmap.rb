pin 'application-spree-multi-vendor', to: 'spree_multi_vendor/application.js', preload: false

pin_all_from SpreeMultiVendor::Engine.root.join('app/javascript/spree_multi_vendor/controllers'),
             under: 'spree_multi_vendor/controllers',
             to:    'spree_multi_vendor/controllers',
             preload: 'application-spree-multi-vendor'
