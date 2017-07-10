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
      expect(form.performed).to eq false
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
      form = SimpleForm.new
      expect(form.call).to eq false
      expect(form.performed).to eq false
      form.name = "Klaus"
      expect(form.call).to eq true
      expect(form.performed).to eq true
    end

    it "raises on call!" do
      expect { SimpleForm.new.call! }.to raise
    end

    it "calls perform on call!" do
      form = SimpleForm.new params: { name: "Klaus" }
      form.call!
      expect(form.performed).to eq true
    end
  end
end
