require "active_record"

RSpec.describe "Nested validations" do
  before(:all) do
    class UserForm < Muffin::Base
      attribute :name, String

      attribute :comments do
        attribute :text, String
        validates :text, presence: true

        attribute :tags do
          attribute :label, String
          validates :label, presence: true
        end
      end

      validates :name, presence: true
    end
  end

  let(:params) do
    {
      name: "Max",
      comments: [
        {
          text: "comment1_text",
          tags: [{ label: "comment1_tag1_label" }]
        }
      ]
    }
  end

  let(:form) do
    UserForm.new(params: params)
  end

  it "should pass if there are no errors" do
    expect(form).to be_valid
  end

  context "if there are failing (nested) validations" do
    let(:params) do
      {
        name: "Max",
        comments: [
          {
            text: nil,
            tags: [{ label: "comment1_tag1_label" }]
          }
        ]
      }
    end

    it "should fail" do
      expect(form).to be_invalid
    end
  end

  context "if there are failing (deeply nested) validations" do
    let(:params) do
      {
        name: "Max",
        comments: [
          {
            text: "comment1_text",
            tags: [{ label: nil }, { label: "comment1_tag2_label" }]
          }
        ]
      }
    end

    it "should fail" do
      expect(form).to be_invalid
    end

    specify "errors should point to the nested attribute where the validation failed" do
      expect(form).to be_invalid
      expect(form.errors.messages[:comments]).to be_present
      expect(form.comments.first.errors[:tags]).to be_present
      expect(form.comments.first.tags.first.errors[:label]).to be_present
      expect(form.comments.first.tags.second.errors[:label]).to be_blank
    end
  end

  after(:all) do
    # don't let those classes leak into other specs
    Object.send(:remove_const, :UserForm)
  end
end
