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

      it "takes :params as an option keyword argument" do
        expect(instance).to respond_to(:prepare).with(1).and_keywords(:params)
      end

      it "takes :request as an option keyword argument" do
        expect(instance).to respond_to(:prepare).with(1).and_keywords(:request)
      end

      it "takes :scope as an option keyword argument" do
        expect(instance).to respond_to(:prepare).with(1).and_keywords(:scope)
      end

      context "if params are not given" do
        context "if the including context responds to :params" do
          let(:klass) do
            Class.new do
              include Muffin::Rails::ControllerAdditions
              attr_accessor :params
            end
          end
          let(:params) do
            ActionController::Parameters.new(
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
            )
          end
          let(:instance) { klass.new.tap { |e| e.params = params } }

          context "if the operation class responds to :model_name" do
            let(:operation) do
              Class.new(mock_operation) do
                def self.model_name
                  "BookCover"
                end
              end
            end

            it "interfers the params" do
              expect(operation_instance.params).to include("name" => "foo", "image" => "http://bar.jpg")
              expect(operation_instance.params["authors"]).to include("first_name" => "Max", "last_name" => "Mustermann")
              expect(operation_instance.params["authors"]).to include("first_name" => "Sabine", "last_name" => "Musterfrau")
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
          let(:klass) do
            Class.new do
              include Muffin::Rails::ControllerAdditions
              attr_accessor :request
            end
          end
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
        context "if the including context responds to Muffin::Rails::SCOPE_ACCESSOR" do
          let(:scope) { Object.new }
          let(:klass) do
            Class.new do
              include Muffin::Rails::ControllerAdditions
              attr_accessor Muffin::Rails::SCOPE_ACCESSOR.to_sym
            end
          end
          let(:instance) { klass.new.tap { |e| e.send("#{Muffin::Rails::SCOPE_ACCESSOR}=", scope) } }

          it "is used as the scope" do
            expect(operation_instance.scope).to be(scope)
          end
        end

        context "if the including context responds to :current_user" do
          let(:some_user) { Object.new }
          let(:klass) do
            Class.new do
              include Muffin::Rails::ControllerAdditions
              attr_accessor :current_user
            end
          end
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
