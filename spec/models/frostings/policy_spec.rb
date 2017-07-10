RSpec.describe Muffin::Validation do
  context "with a simple form" do
    class Form < Muffin::Base
      attribute :name

      permitted? { scope == :admin }
    end

    it "knows about the scope" do
      expect(Form.new(scope: :admin).scope).to eq :admin
    end

    it "tracks if an operation is permitted" do
      expect(Form.new.permitted?).to eq false
      expect(Form.new(scope: :admin).permitted?).to eq true
    end

    it "raises if an operation is not permitted" do
      expect { Form.new.save }.to raise
      expect { Form.new.save! }.to raise
    end
  end

  context "with a policy per attribute" do
    class Form < Muffin::Base
      attribute :name, permit: -> { scope == :admin }
    end

    it "does not assign non permitted values" do
      form = Form.new attributes: { name: "Klaus" }
      expect(form.params).to eq(name: "Klaus")
      expect(form.attributes).to eq({})
      expect(form.name).to be_nil
    end

    it "is still permitted when supplied with wrong attributes" do
      form = Form.new attributes: { name: "Klaus" }
      expect(form.permitted?).to eq true
    end

    it "has introspection about permitted attributes" do
      expect(Form.new.attribute_permitted?(:name)).to eq false
      expect(Form.new(scope: :admin).attribute_permitted?(:name)).to eq true
    end
  end

  context "with a value policy" do
    class Form < Muffin::Base
      attribute :role, permitted_values: -> { scope == :admin ? ["user", "admin"] : ["user"] }
    end

    it "raises on non permitted values" do
      expect { Form.new(params: { role: "admin" }) }.to raise
    end

    it "allows setting it for the approved user" do
      expect(Form.new(params: { role: "admin" }, scope: :admin).role).to eq "admin"
    end

    it "allows setting the value via introspection" do
      expect(Form.new.attribute_permitted?(:role)).to eq true
    end

    it "introspects setting a value's permission" do
      expect(Form.new.attribute_value_permitted?(:role, "admin")).to eq false
      expect(Form.new(scope: :admin).attribute_value_permitted?(:role, "admin")).to eq true
    end

    it "knows about permitted values" do
      expect(Form.new.permitted_values(:role)).to eq ["user"]
      expect(Form.new(scope: :admin).permitted_values(:role)).to eq ["user", "admin"]
    end
  end
end
