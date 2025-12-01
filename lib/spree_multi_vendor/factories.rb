require 'factory_bot'
require 'factory_bot_rails'

Dir[File.join(__dir__, 'factories', '**', '*.rb')].each { |file| require file }
