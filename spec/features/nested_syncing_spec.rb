require "active_record"

RSpec.describe "Nested syncing" do
  before(:all) do
    ActiveRecord::Migration.verbose = false
    ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
    ActiveRecord::Schema.define(version: 1) do
      create_table :users do |t|
        t.string :first_name
        t.string :last_name
        t.string :country
      end

      create_table :comments do |t|
        t.integer :user_id
        t.text :text
      end

      create_table :tags do |t|
        t.integer :comment_id
        t.string :label
      end
    end

    class User < ActiveRecord::Base
      has_many :comments
    end

    class Comment < ActiveRecord::Base
      belongs_to :user
      has_many :tags
    end

    class Tag < ActiveRecord::Base
      belongs_to :comment
    end

    class UserForm < Muffin::Base
      attribute :id, Integer
      attribute :first_name, String
      attribute :last_name, String
      attribute :comments do
        attribute :id, Integer
        attribute :text, String
        attribute :_destroy, Muffin::Boolean
        attribute :tags do
          attribute :id, Integer
          attribute :label, String
          attribute :_destroy, Muffin::Boolean
        end
      end

      def user
        @user ||= User.find(params[:id])
      end

      def assign_attributes
        self.attributes = user.attributes.merge(comments: user.comments.map(&:attributes))
        super
      end

      def perform
        update_nested! user
      end
    end
  end

  describe "#update_nested!" do
    it "is defined as a private method" do
      expect(Class.new(Muffin::Base).new.private_methods).to include(:update_nested!)
    end
  end

  describe "a complex use case" do
    let!(:user) do
      User.create(
        first_name: "Max",
        last_name: "Mustermann",
        country: "de",
        comments: [
          Comment.create(
            text: "comment1_text",
            tags: [
              Tag.create(label: "comment1_tag1_label"),
              Tag.create(label: "comment1_tag2_label")
            ]
          ),
          Comment.create(
            text: "comment2_text",
            tags: [
              Tag.create(label: "comment2_tag1_label"),
              Tag.create(label: "comment2_tag2_label")
            ]
          )
        ]
      )
    end

    let(:updated_user) { User.find(user.id) }

    let(:params) do
      {
        id: user.id,
        first_name: user.first_name,
        # the the last_name to nil
        last_name: nil,
        comments: [
          {
            # change the text of the first comment
            id: user.comments.first.id, text: "comment1_text_changed",
            tags: [
              # change the label of the first tag
              { id: user.comments.first.tags.first.id, label: "comment1_tag1_label_changed" },
              # Delete the second tag
              { id: user.comments.first.tags.second.id, _destroy: true },
              # Create a new (third) label
              { label: "comment1_tag3_label" }
            ]
          },
          # Delete the second comment
          { id: user.comments.second.id, _destroy: true },
          # Create a (new) third comment with new tags
          {
            text: "comment3_text",
            tags: [
              { label: "comment3_tag1" },
              { label: "comment3_tag2" }
            ]
          }
        ]
      }
    end

    before(:each) { UserForm.new(params: params).perform }

    it "leaves the users first name as is (because it's given)" do
      expect(updated_user.first_name).to eq(user.first_name)
    end

    it "it does not alter the users country (because the form has no such attribute)" do
      expect(updated_user.country).to eq(user.country)
    end

    it "updates the users last_name to nil" do
      expect(user.last_name).to be_present
      expect(updated_user.last_name).to be_nil
    end

    it "changes the the text of the first comment" do
      updated_comment_text = params[:comments].first[:text]
      expect(updated_user.comments.first.text).to eq(updated_comment_text)
    end

    it "changes the label of the first comments first tag" do
      updated_tag_label = params[:comments].first[:tags].first[:label]
      expect(updated_user.comments.first.tags.first.label).to eq(updated_tag_label)
    end

    it "deletes the first comments second tag" do
      expect(Comment.exists?(user.comments.first.tags.second.id)).to be(false)
    end

    it "adds a new tag the first comment" do
      label_of_the_new_tag = params[:comments].first[:tags].last[:label]
      expect(updated_user.comments.first.tags.map(&:label)).to include(label_of_the_new_tag)
    end

    it "deletes the second comment" do
      expect(updated_user.comments.exists?(user.comments.second.id)).to be(false)
    end

    it "creates a new (third) comment" do
      new_comments_text = params[:comments].last[:text]
      expect(updated_user.comments.map(&:text)).to include(new_comments_text)
    end

    it "creates two tags for the newly created comment" do
      new_comment = updated_user.comments.find_by(text: params[:comments].last[:text])
      new_comments_first_tag_label = params[:comments].last[:tags].first[:label]
      new_comments_second_tag_label = params[:comments].last[:tags].second[:label]

      expect(new_comment.tags.map(&:label)).to include(new_comments_first_tag_label)
      expect(new_comment.tags.map(&:label)).to include(new_comments_second_tag_label)
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.close

    # don't let those classes leak into other specs
    Object.send(:remove_const, :Comment)
    Object.send(:remove_const, :User)
    Object.send(:remove_const, :UserForm)
    Object.send(:remove_const, :Tag)
  end
end
