RSpec.describe Muffin::Attributes do
  context "with a simple form" do
    class Nested
      attr_accessor :name

      def initialize(name: nil)
        self.name = name
      end

      class Type
        def deserialize(value)
          value && Nested.new(value)
        end
      end
    end

    class SimpleForm < Muffin::Base
      attribute :count, :integer
      attribute :amount, :float
      attribute :name, :string
      attribute :description
      attribute :accepted, :boolean
      attribute :with_default, default: "standard"
      attribute :tags, array: true
      attribute :categories, [:string]
      attribute :nested, Nested::Type
      attribute :total, :decimal
      attribute :symbol, :symbol
      attribute :hash, :hash
      attribute :date, :date
      attribute :date_time, :datetime
      attribute :model, :any
    end

    it "has type coercision for integers" do
      expect(SimpleForm.new(params: { count: "5" }).count).to be_an Integer
      expect(SimpleForm.new(params: { count: "5" }).count).to eq 5
      expect(SimpleForm.new(params: { count: nil }).count).to be_nil
      expect(SimpleForm.new(params: { count: "" }).count).to eq nil
      expect(SimpleForm.new(params: { count: "z" }).count).to eq 0
      expect(SimpleForm.new(params: { count: "15z" }).count).to eq 15
      expect(SimpleForm.new(params: { count: 5 }).count).to eq 5
    end

    it "has type coercision for floats" do
      expect(SimpleForm.new(params: { amount: "5" }).amount).to be_a Float
      expect(SimpleForm.new(params: { amount: "5" }).amount).to eq 5.0
      expect(SimpleForm.new(params: { amount: "5.1" }).amount).to eq 5.1
      expect(SimpleForm.new(params: { amount: nil }).amount).to be_nil
      expect(SimpleForm.new(params: { amount: "z" }).amount).to eq 0.0
      expect(SimpleForm.new(params: { amount: "15.0z" }).amount).to eq 15.0
      expect(SimpleForm.new(params: { amount: 5 }).amount).to eq 5.0
    end

    it "has type coercision for strings" do
      expect(SimpleForm.new(params: { name: "Klaus" }).name).to be_a String
      expect(SimpleForm.new(params: { name: "Klaus" }).name).to eq "Klaus"
      expect(SimpleForm.new(params: { name: 5 }).name).to eq "5"
      expect(SimpleForm.new(params: { name: :klaus }).name).to eq "klaus"
      expect(SimpleForm.new(params: { name: nil }).name).to eq nil
      expect(SimpleForm.new(params: { name: "" }).name).to eq ""
    end

    it "has type coercision for booleans" do
      expect(SimpleForm.new(params: { accepted: true }).accepted).to eq true
      expect(SimpleForm.new(params: { accepted: "true" }).accepted).to eq true
      expect(SimpleForm.new(params: { accepted: "1" }).accepted).to eq true
      expect(SimpleForm.new(params: { accepted: "0" }).accepted).to eq false
      expect(SimpleForm.new(params: { accepted: "false" }).accepted).to eq false
      expect(SimpleForm.new(params: { accepted: false }).accepted).to eq false
      expect(SimpleForm.new(params: { accepted: nil }).accepted).to eq nil
    end

    it "has type coercision for value classes" do
      expect(SimpleForm.new(params: {}).nested).to be_nil
      expect(SimpleForm.new(params: { nested: { name: "Klaus" } }).nested).to be_a Nested
      expect(SimpleForm.new(params: { nested: { name: "Klaus" } }).nested.name).to eq "Klaus"
    end

    it "has type coercision for big decimals" do
      expect(SimpleForm.new(params: { total: "5" }).total).to be_an BigDecimal
      expect(SimpleForm.new(params: { total: "5" }).total).to eq(BigDecimal(5))
      expect(SimpleForm.new(params: { total: nil }).total).to be_nil
      expect(SimpleForm.new(params: { total: "" }).total).to be_nil
      expect(SimpleForm.new(params: { count: "z" }).count).to eq(BigDecimal(0))
      expect(SimpleForm.new(params: { count: "5z" }).count).to eq(BigDecimal(5))
      expect(SimpleForm.new(params: { count: 5 }).count).to eq(BigDecimal(5))
    end

    it "has type coercision for symbols" do
      expect(SimpleForm.new(params: { symbol: "foo" }).symbol).to be_an Symbol
      expect(SimpleForm.new(params: { symbol: "foo" }).symbol).to eq(:foo)
      expect(SimpleForm.new(params: { symbol: 5 }).symbol).to eq(:"5")
      expect(SimpleForm.new(params: { symbol: :foo }).symbol).to eq(:foo)
      expect(SimpleForm.new(params: { symbol: nil }).symbol).to be_nil
      expect(SimpleForm.new(params: { symbol: "" }).symbol).to eq(:"")
    end

    it "supports Hash as a type" do
      expect(SimpleForm.new(params: { hash: { foo: "bar" } }).hash).to eq(foo: "bar")
    end

    it "has type coercision for date" do
      expect(SimpleForm.new(params: { date: "2001-02-03" }).date).to be_a Date
      expect(SimpleForm.new(params: { date: "2001-02-03" }).date).to eq Date.parse("2001-02-03")
      expect(SimpleForm.new(params: { date: "" }).date).to eq nil
      expect(SimpleForm.new(params: { date: nil }).date).to eq nil
      expect(SimpleForm.new(params: { date: Date.parse("2001-02-03") }).date).to be_a Date
    end

    it "has type coercision for date_time" do
      Time.zone = "Europe/Berlin"
      expect(SimpleForm.new(params: { date_time: "2001-02-03T04:05:06" }).date_time).to be_a DateTime
      expect(SimpleForm.new(params: { date_time: "2001-02-03T04:05:06" }).date_time).to eq DateTime.parse("2001-02-03T04:05:06+01:00")
      expect(SimpleForm.new(params: { date_time: "2001-02-03T04:05:06+02:00" }).date_time).to eq "2001-02-03T04:05:06+02:00".to_datetime
      expect(SimpleForm.new(params: { date_time: nil }).date_time).to eq nil
      expect(SimpleForm.new(params: { date_time: "" }).date_time).to eq nil
      expect(SimpleForm.new(params: { date_time: DateTime.parse("2001-02-03T04:05:06") }).date_time).to be_a DateTime
      expect(SimpleForm.new(params: { date_time: DateTime.parse("2001-02-03T04:05:06+01:00") }).date_time).to eq "2001-02-03T04:05:06+01:00".to_datetime
    end

    it "ignores types for any" do
      expect(SimpleForm.new(params: { model: 5 }).model).to eq 5
      expect(SimpleForm.new(params: { model: DateTime.current }).model).to be_a DateTime
    end

    it "respects defaults" do
      expect(SimpleForm.new(params: { with_default: "Klaus" }).with_default).to eq "Klaus"
      expect(SimpleForm.new(params: { with_default: "" }).with_default).to eq ""
      expect(SimpleForm.new(params: { with_default: " " }).with_default).to eq " "
      expect(SimpleForm.new(params: { with_default: nil }).with_default).to eq "standard"
    end

    it "supports arrays of objects" do
      expect(SimpleForm.new(params: { tags: ["test"] }).tags).to eq ["test"]
      expect(SimpleForm.new(params: { tags: nil }).tags).to eq []
      expect(SimpleForm.new(params: { tags: [1] }).tags).to eq ["1"]
      expect(SimpleForm.new(params: { tags: [[1]] }).tags).to eq ["[1]"]
    end

    it "has implicit arrays" do
      expect(SimpleForm.new(params: { categories: [1] }).categories).to eq ["1"]
    end

    it "keeps track of assigned attributes" do
      form = SimpleForm.new
      expect(form.attributes).to include(count: nil)
      form.attributes = {}
      expect(form.attributes).to include(count: nil)
      form.attributes = { count: "2" }
      expect(form.attributes).to include(count: 2)
      form.count = 3
      expect(form.attributes).to include(count: 3)
    end

    it "has introspection for fields" do
      expect(SimpleForm.introspect(:count).array?).to eq false
      expect(SimpleForm.introspect(:tags).array?).to eq true
      expect(SimpleForm.introspect(:categories).array?).to eq true
      expect(SimpleForm.introspect(:with_default).default).to eq "standard"
      expect(SimpleForm.introspect(:name).type).to eq :string
      expect(SimpleForm.introspect(:description).type).to eq :string
      expect(SimpleForm.introspect(:nested).type).to eq Nested::Type
    end

    it "discards unknown params without raising an error" do
      expect(SimpleForm.new(params: { test: :value }).attributes.keys).not_to include :test
    end

    it "remembers the original parameters" do
      expect(SimpleForm.new(params: { name: "test" }).params).to eq(name: "test")
    end

    it "assigns the request" do
      Request = Struct.new(:ip)
      expect(SimpleForm.new(request: Request.new("0.0.0.0")).request.ip).to eq "0.0.0.0"
    end
  end

  context "with custom attribute assignment" do
    class CustomForm < Muffin::Base
      attr_reader :assign_called
      attribute :name

      def assign_attributes
        @assign_called = true
      end
    end

    it "overrides the assign call" do
      form = CustomForm.new params: { name: "Klaus" }
      expect(form.assign_called).to eq true
      expect(form.name).to be_nil
    end
  end

  context "with a nested form" do
    class NestedForm < Muffin::Base
      attribute :children, default: [{ name: "Klaus" }] do
        attribute :name
        attribute :age, :integer
      end
    end

    it "sets array by default" do
      expect(NestedForm.introspect(:children).array?).to eq true
    end

    it "creates subclasses for nested attributes" do
      expect(NestedForm::Children.introspect(:age).type).to eq :integer
    end

    it "assigns nested values" do
      expect(NestedForm.new(params: { children: [name: "Hans"] }).children.first.name).to eq "Hans"
    end

    it "supports default values" do
      expect(NestedForm.new.children.first.name).to eq "Klaus"
    end

    it "does type coecision on nested values" do
      expect(NestedForm.new(params: { children: [age: "15"] }).children.first.age).to eq 15
    end
  end
end
