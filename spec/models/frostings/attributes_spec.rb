RSpec.describe Muffin::Attributes do
  context "with a simple form" do
    class Nested
      attr_accessor :name

      def initialize(name:)
        self.name = name
      end
    end

    class SimpleForm < Muffin::Base
      attribute :count, Integer
      attribute :name, String
      attribute :description
      attribute :accepted?, Boolean
      attribute :with_default, default: "standard"
      attribute :tags, array: true
      attribute :categories, [String]
      attribute :nested, Nested
    end

    it "has type coercision for integers" do
      expect(SimpleForm.new(params: { count: "5" }).count).to eq 5
      expect(SimpleForm.new(params: { count: nil }).count).to be_nil
      expect(SimpleForm.new(params: { count: "z" }).count).to be_nil
      expect(SimpleForm.new(params: { count: "15z" }).count).to eq 15
      expect(SimpleForm.new(params: { count: 5 }).count).to eq 5
    end

    it "has type coercision for strings" do
      expect(SimpleForm.new(params: { name: "Klaus" }).name).to eq "Klaus"
      expect(SimpleForm.new(params: { name: 5 }).name).to eq "5"
      expect(SimpleForm.new(params: { name: :klaus }).name).to eq "klaus"
      expect(SimpleForm.new(params: { name: nil }).name).to eq nil
      expect(SimpleForm.new(params: { name: "" }).name).to eq ""
    end

    it "has type coercision for booleans" do
      expect(SimpleForm.new(params: { accepted?: true }).accepted?).to eq true
      expect(SimpleForm.new(params: { accepted?: "true" }).accepted?).to eq true
      expect(SimpleForm.new(params: { accepted?: "1" }).accepted?).to eq true
      expect(SimpleForm.new(params: { accepted?: "0" }).accepted?).to eq false
      expect(SimpleForm.new(params: { accepted?: "false" }).accepted?).to eq false
      expect(SimpleForm.new(params: { accepted?: false }).accepted?).to eq false
      expect(SimpleForm.new(params: { accepted?: nil }).accepted?).to eq nil
    end

    it "has type coercision for value classes" do
      expect(SimpleForm.new(params: { nested: { name: "Klaus" } }).nested).to be_a Nested
      expect(SimpleForm.new(params: { nested: { name: "Klaus" } }).name).to eq "Klaus"
    end

    it "respects defaults" do
      expect(SimpleForm.new(params: { with_default: "Klaus" }).with_default).to eq "Klaus"
      expect(SimpleForm.new(params: { with_default: "" }).with_default).to eq "standard"
      expect(SimpleForm.new(params: { with_default: " " }).with_default).to eq "standard"
      expect(SimpleForm.new(params: { with_default: nil }).with_default).to eq "standard"
    end

    it "supports arrays of objects" do
      expect(SimpleForm.new(params: { tags: ["test"] }).tags).to eq ["test"]
      expect(SimpleForm.new(params: { tags: nil }).tags).to eq []
      expect(SimpleForm.new(params: { tags: [1] }).tags).to eq ["1"]
      expect(SimpleForm.new(params: { tags: [[1]] }).tags).to eq ["[1]"]
    end

    it "has implicit arrays" do
      expect(SimpleForm.new(params: { categories: [1] })).to eq ["1"]
    end

    it "keeps track of assigned attributes" do
      form = SimpleForm.new
      expect(form.attributes).to include(count: nil)
      form.attributes = {}
      expect(form.attributes).to include(count: nil)
      form.attributes = { count: "2" }
      expect(form.attributes).to include(count: 2)
    end

    it "has introspection for fields" do
      expect(SimpleForm.introspect(:count).array?).to eq false
      expect(SimpleForm.introspect(:tags).array?).to eq true
      expect(SimpleForm.introspect(:categories).array?).to eq true
      expect(SimpleForm.introspect(:with_default).default).to eq "standard"
      expect(SimpleForm.introspect(:name).type).to eq String
      expect(SimpleForm.introspect(:description).type).to eq String
      expect(SimpleForm.introspect(:nested).type).to eq Nested
    end

    it "discards unknown params without raising an error" do
      expect(SimpleForm.new(params: { test: :value }).attributes.keys).not_to include :test
    end

    it "remembers the original parameters" do
      expect(SimpleForm.new(params: { name: "test" }).params).to eq(name: "test")
    end

    it "assigns the request" do
      expect(SimpleForm.new(request: OpenStruct.new(ip: "0.0.0.0")).request.ip).to eq "0.0.0.0"
    end
  end

  context "with a nested form" do
    class NestedForm < Muffin::Base
      attribute :children, default: [{ name: "Klaus" }] do
        attribute :name
        attribute :age, Integer
      end
    end

    it "sets array by default" do
      expect(SimpleForm.introspect(:children).array?).to eq true
    end

    it "assigns nested values" do
      expect(SimpleForm.new(params: { children: [name: "Hans"] }).children.first.name).to eq "Hans"
    end

    it "supports default values" do
      expect(SimpleForm.new.children.first.name).to eq "Klaus"
    end

    it "does type coecision on nested values" do
      expect(SimpleForm.new(params: { children: [age: "15"] }).children.first.age).to eq 15
    end
  end
end
