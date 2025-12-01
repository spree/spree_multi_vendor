module SpreeMultiVendor
  module OrderMailerDecorator
    def splitted_order_confirm_email(order, resend = false)
      @order = order.respond_to?(:id) ? order : Spree::Order.find(order)
      current_store = @order.store
      subject = (resend ? "[#{Spree.t(:resend).upcase}] " : '')
      subject += "#{current_store.name} #{Spree.t('order_mailer.confirm_email.subject')} ##{@order.number}"
      mail(to: @order.email, from: from_address, subject: subject, store_url: current_store.url_or_custom_domain, reply_to: reply_to_address)
    end

    def vendor_order_confirm_email
      @order = params[:order]
      @store = @order.store
      @url = Spree::Core::Engine.routes.url_helpers.edit_admin_order_url(@order, host: @store.url)

      mail(to: params[:recipient].email, from: from_address, subject: 'New Order Received', reply_to: reply_to_address)
    end
  end
end

Spree::OrderMailer.prepend(SpreeMultiVendor::OrderMailerDecorator)
