RSpec.describe Muffin::Mutation do
  before(:all) do
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Schema.define(version: 1) do
      create_table :contacts do |t|
        t.string :first_name
        t.string :email
      end
    end
  end

  class Contact < ActiveRecord::Base
  end

  class ContactMutation < Muffin::Mutation
    attribute :first_name
    attribute :terms_accepted, :boolean
    attribute :email, default: "klaus@example.com"
  end

  it "assigns values from the model" do
    expect(ContactMutation.new(model: Contact.new(first_name: "Georg")).first_name).to eq "Georg"
  end

  it "creates a new record" do
    mutation = ContactMutation.new(model: Contact.new, params: { first_name: "Klaus" })
    mutation.perform
    expect(mutation.model).to have_attributes(first_name: "Klaus", email: "klaus@example.com")
    expect(mutation.model).to be_persisted
  end

  it "updates an existing record" do
    user = Contact.create! first_name: "Hans", email: "hans@example.com"
    mutation = ContactMutation.new(model: user, params: { first_name: "Klaus" })
    mutation.perform
    user.reload
    expect(user).to have_attributes(first_name: "Klaus", email: "hans@example.com")
    expect(user).to be_persisted
  end
end
