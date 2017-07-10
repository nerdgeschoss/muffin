RSpec.describe Muffin::Validation do
  context "with a simple form" do
    class SimpleForm < Muffin::Base
      attribute :name
      attribute :description

      validates :name, presence: true
    end

    it "lists required attributes" do
      expect(SimpleForm.new.required_attributes).to eq [:name]
    end

    it "validates content" do
      expect(SimpleForm.new(params: { name: "Klaus" }).valid?).to eq true
      expect(SimpleForm.new(params: { name: "" }).valid?).to eq false
    end

    it "returns validation errors" do
      form = SimpleForm.new(params: { name: "" })
      form.valid?
      expect(form.errors.count).to eq 1
    end
  end
end
