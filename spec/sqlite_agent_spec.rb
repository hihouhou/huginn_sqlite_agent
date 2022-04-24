require 'rails_helper'
require 'huginn_agent/spec_helper'

describe Agents::SqliteAgent do
  before(:each) do
    @valid_options = Agents::SqliteAgent.new.default_options
    @checker = Agents::SqliteAgent.new(:name => "SqliteAgent", :options => @valid_options)
    @checker.user = users(:bob)
    @checker.save!
  end

  pending "add specs here"
end
