require "action_controller/metal/strong_parameters"

RSpec.describe Muffin::Rails::ControllerAdditions do
  it { is_expected.to be_a(Module) }

  let(:mock_operation) do
    Class.new do
      def initialize(hash)
        hash = HashWithIndifferentAccess.new(hash)
        @params = hash[:params]
        @request = hash[:request]
        @scope = hash[:scope]
      end

      attr_accessor :params, :request, :scope
    end
  end

  context "when included into a class" do
    let(:klass) { Class.new { include Muffin::Rails::ControllerAdditions } }
    let(:instance) { klass.new }
    let(:operation) { mock_operation }

    it "should provide an instance method #prepare" do
      expect(instance).to respond_to(:prepare)
    end

    describe "#prepare" do
      let(:operation_instance) { instance.prepare operation }

      it "takes the operation as an argument" do
        expect(instance).to respond_to(:prepare).with(1).argument
      end

      it "takes a hash as an optional argument" do
        expect(instance).to respond_to(:prepare).with(2).arguments
      end

      context "if params are not given" do
        context "if the including context responds to :params" do
          let(:klass) { Class.new { include Muffin::Rails::ControllerAdditions; attr_accessor :params, :model_name } }
          let(:params) do
            ActionController::Parameters.new({
              book_cover: {
                name: "foo",
                image: "http://bar.jpg",
                authors_attributes: [
                  { first_name: "Max", last_name: "Mustermann" },
                  { first_name: "Sabine", last_name: "Musterfrau" }
                ]
              },
              some_other_param: {
                some_value: "foo"
              }
            })
          end

          let(:instance) { klass.new.tap { |e| e.params = params } }

          context "if the operation class responds to :model_name" do
            let(:operation) { Class.new(mock_operation) { def self.model_name; "BookCover"; end } }

            it "interfers the params" do
              expect(operation_instance.params).to include("name"=>"foo", "image"=>"http://bar.jpg")
              expect(operation_instance.params["authors"]).to include("first_name"=>"Max", "last_name"=>"Mustermann")
              expect(operation_instance.params["authors"]).to include("first_name"=>"Sabine", "last_name"=>"Musterfrau")
            end
          end

          context "if the operation class does not responds to :model_name" do
            it "params are not interfered" do
              expect(operation_instance.params).to be_nil
            end
          end
        end

        context "if the including context does not responds to :params" do
          it "params are not interfered" do
            expect(operation_instance.params).to be_nil
          end
        end
      end

      context "if request is not given" do
        context "if the including context responds to :request" do
          let(:request) { Object.new }
          let(:klass) { Class.new { include Muffin::Rails::ControllerAdditions; attr_accessor :request } }
          let(:instance) { klass.new.tap { |e| e.request = request } }

          it "is used as the request" do
            expect(operation_instance.request).to be(request)
          end
        end

        context "if the including context does not respond to :request" do
          it "is not set" do
            expect(operation_instance.request).to eq(nil)
          end
        end
      end

      context "if scope is not given" do
        context "if the including context responds to :current_user" do
          let(:some_user) { Object.new }
          let(:klass) { Class.new { include Muffin::Rails::ControllerAdditions; attr_accessor :current_user } }
          let(:instance) { klass.new.tap { |e| e.current_user = some_user } }

          it "is used as the scope" do
            expect(operation_instance.scope).to be(some_user)
          end
        end

        context "if the including context does not respond to :current_user" do
          it "is not set" do
            expect(operation_instance.scope).to eq(nil)
          end
        end
      end
    end
  end
end
