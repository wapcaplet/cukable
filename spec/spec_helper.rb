require 'rspec'
require 'cukable/conversion'
require 'cukable/cuke'
require 'cukable/helper'

RSpec.configure do |config|
  config.include Cukable::Helper
  config.include Cukable::Conversion
end

