RSpec.describe Muffin::Policy do
  context "with a simple form" do
    class SimplePolicyForm < Muffin::Base
      attribute :name

      permitted? { scope == :admin }
    end

    it "knows about the scope" do
      expect(SimplePolicyForm.new(scope: :admin).scope).to eq :admin
    end

    it "tracks if an operation is permitted" do
      expect(SimplePolicyForm.new.permitted?).to eq false
      expect(SimplePolicyForm.new(scope: :admin).permitted?).to eq true
    end

    it "raises if an operation is not permitted" do
      expect { SimplePolicyForm.new.call }.to raise_error Muffin::NotPermittedError
      expect { SimplePolicyForm.new.call! }.to raise_error Muffin::NotPermittedError
    end
  end

  context "with a policy per attribute" do
    class AttributePolicyForm < Muffin::Base
      attribute :name, permit: -> { scope == :admin }
    end

    it "does not assign non permitted values" do
      form = AttributePolicyForm.new params: { name: "Klaus" }
      expect(form.params).to eq(name: "Klaus")
      expect(form.attributes).to eq({})
      expect(form.name).to be_nil
    end

    it "is still permitted when supplied with wrong attributes" do
      form = AttributePolicyForm.new params: { name: "Klaus" }
      expect(form.permitted?).to eq true
    end

    it "has introspection about permitted attributes" do
      expect(AttributePolicyForm.new.attribute_permitted?(:name)).to eq false
      expect(AttributePolicyForm.new(scope: :admin).attribute_permitted?(:name)).to eq true
    end
  end

  context "with a value policy" do
    class ValuePolicyForm < Muffin::Base
      attribute :role, permitted_values: -> { scope == :admin ? ["user", "admin"] : ["user"] }
      attribute :tags, String, array: true, permitted_values: -> { ["foo", "bar"] }
    end

    it "raises on non permitted values" do
      expect { ValuePolicyForm.new(params: { role: "admin" }) }.to raise_error Muffin::NotPermittedError
    end

    it "allows setting it for the approved user" do
      expect(ValuePolicyForm.new(params: { role: "admin" }, scope: :admin).role).to eq "admin"
    end

    it "allows setting the value via introspection" do
      expect(ValuePolicyForm.new.attribute_permitted?(:role)).to eq true
    end

    it "introspects setting a value's permission" do
      expect(ValuePolicyForm.new.attribute_value_permitted?(:role, "admin")).to eq false
      expect(ValuePolicyForm.new(scope: :admin).attribute_value_permitted?(:role, "admin")).to eq true
    end

    it "knows about permitted values" do
      expect(ValuePolicyForm.new.permitted_values(:role)).to eq ["user"]
      expect(ValuePolicyForm.new(scope: :admin).permitted_values(:role)).to eq ["user", "admin"]
    end

    it "handles permitted values for array types" do
      expect { ValuePolicyForm.new(params: { tags: ["foo"] }) }.not_to raise_error
      expect { ValuePolicyForm.new(params: { tags: ["bar"] }) }.not_to raise_error
      expect { ValuePolicyForm.new(params: { tags: ["foo", "bar"] }) }.not_to raise_error
      expect { ValuePolicyForm.new(params: { tags: ["muff"] }) }.to raise_error Muffin::NotPermittedError
      expect { ValuePolicyForm.new(params: { tags: ["foo", "muff"] }) }.to raise_error Muffin::NotPermittedError
    end
  end
end
