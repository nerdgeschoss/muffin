RSpec.describe Muffin::Execution do
  context "with a simple form" do
    class SimpleForm < Muffin::Base
      attr_reader :performed

      def perform
        @performed = true
      end
    end

    it "calls perform on call" do
      form = SimpleForm.new
      expect(form.performed).to be_falsy
      form.call
      expect(form.performed).to eq true
    end
  end

  context "with validation" do
    class ValidatedForm < Muffin::Base
      attr_reader :performed
      attribute :name

      validates :name, presence: true

      def perform
        @performed = true
      end
    end

    it "performes after validation" do
      form = ValidatedForm.new
      expect(form.call).to be_falsy
      expect(form.performed).to be_falsy
      form.name = "Klaus"
      expect(form.call).to eq true
      expect(form.performed).to eq true
    end

    it "raises on call!" do
      expect { ValidatedForm.new.call! }.to raise_error(ActiveModel::ValidationError)
    end

    it "calls perform on call!" do
      form = ValidatedForm.new params: { name: "Klaus" }
      form.call!
      expect(form.performed).to eq true
    end
  end
end
