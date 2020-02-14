RSpec.describe Muffin::Base do
  let(:view) { Muffin::MockView.new }

  let(:operation_class) do
    Class.new(Muffin::Base) do
      attribute :id, :integer
      attribute :first_name

      attribute :address, array: false do
        attribute :street_name
        attribute :street_number
        attribute :phone, array: false do
          attribute :pre
          attribute :num
        end
      end

      attribute :tags, array: true do
        attribute :id, :integer
        attribute :label
      end

      # because this is an anonymous class
      def self.name
        "UpdateUser"
      end
    end
  end

  let(:params) do
    {
      id: 1,
      first_name: "Max",
      address: {
        street_name: "Musterstraße",
        street_number: "1a",
        phone: {
          pre: "030",
          num: "123456"
        }
      },
      tags: [
        { id: 2, label: "foo" },
        { id: 3, label: "bar" }
      ]
    }
  end

  let(:operation) do
    operation_class.new(params: params)
  end

  describe "#form_for" do
    let(:form) do
      view.form_for operation do |f|
        [
          f.text_field(:first_name),
          f.fields_for(:address) do |ff|
            [
              ff.text_field(:street_name),
              ff.text_field(:street_number),
              ff.fields_for(:phone) do |fff|
                [
                  fff.text_field(:pre),
                  fff.text_field(:num)
                ].join.html_safe
              end
            ].join.html_safe
          end,
          f.fields_for(:tags) do |ff|
            ff.text_field :label
          end
        ].join.html_safe
      end
    end

    let(:doc) { Nokogiri::HTML(form) }

    it "renders the form correctly" do
      [
        'input[type="text"][value="Max"][name="update_user[first_name]"][id="update_user_first_name"]',
        'input[type="text"][value="Musterstraße"][name="update_user[address_attributes][street_name]"][id="update_user_address_attributes_street_name"]',
        'input[type="text"][value="1a"][name="update_user[address_attributes][street_number]"][id="update_user_address_attributes_street_number"]',
        'input[type="text"][value="030"][name="update_user[address_attributes][phone_attributes][pre]"][id="update_user_address_attributes_phone_attributes_pre"]',
        'input[type="text"][value="123456"][name="update_user[address_attributes][phone_attributes][num]"][id="update_user_address_attributes_phone_attributes_num"]',
        'input[type="text"][value="foo"][name="update_user[tags_attributes][0][label]"][id="update_user_tags_attributes_0_label"]',
        'input[type="hidden"][value="2"][name="update_user[tags_attributes][0][id]"][id="update_user_tags_attributes_0_id"]',
        'input[type="text"][value="bar"][name="update_user[tags_attributes][1][label]"][id="update_user_tags_attributes_1_label"]',
        'input[type="hidden"][value="3"][name="update_user[tags_attributes][1][id]"][id="update_user_tags_attributes_1_id"]'
      ].each do |selector|
        expect(doc.css(selector)).to be_present
      end
    end
  end
end
