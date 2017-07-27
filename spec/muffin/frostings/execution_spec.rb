RSpec.describe Muffin::Execution do
  context "with a simple form" do
    class ExecutionForm < Muffin::Base
      attr_reader :performed

      def perform
        @performed = true
      end
    end

    it "calls perform on call" do
      form = ExecutionForm.new
      expect(form.performed).to be_falsy
      form.call
      expect(form.performed).to eq true
    end
  end

  context "with validation" do
    class ValidatedExecutionForm < Muffin::Base
      attr_reader :performed
      attribute :name

      validates :name, presence: true

      def perform
        @performed = true
      end
    end

    it "performes after validation" do
      form = ValidatedExecutionForm.new
      expect(form.call).to be_falsy
      expect(form.performed).to be_falsy
      form.name = "Klaus"
      expect(form.call).to eq true
      expect(form.performed).to eq true
    end

    it "raises on call!" do
      expect { ValidatedExecutionForm.new.call! }.to raise_error(ActiveModel::ValidationError)
    end

    it "calls perform on call!" do
      form = ValidatedExecutionForm.new params: { name: "Klaus" }
      form.call!
      expect(form.performed).to eq true
    end
  end

  context "without a perform block" do
    class NoPerformForm < Muffin::Base
      attribute :name
      validates :name, presence: true
    end

    it "returns true on call if valid" do
      expect(NoPerformForm.new(params: { name: "Klaus" }).call).to be true
    end

    it "returns false on call if invalid" do
      expect(NoPerformForm.new.call).to be false
    end

    it "raises if invalid" do
      expect { NoPerformForm.new.call! }.to raise_error(ActiveModel::ValidationError)
    end
  end
end
