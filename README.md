# Muffin

## Why form objects?

Form objects encapsulate logic to modify data (similar to changesets in Elixir or Mutations in GraphQL). Every non trivial form in rails usually has some custom (and conditional) validation, specific behavior (when update `x`, then remove `y`) and complex association (e.g. `accepts_nested_attributes_for`). This is usually spread all over the model leading to hard to maintain code and tons of conditional validation that is hard to understand. Also it’s not possible to have a form for many objects without having a parent object that is doing the nested_attribute dance.

Forms are living in `/app/forms`. They should work independently from controllers (for unit testing) and can (but doesn’t have to!) handle `ActiveRecord` objects.

## Public API

```ruby
my_form = MyForm.new(request:, params:, scope:) # scope could be the current_user
my_form.call # 'commits' the form: it validates and calls the internal process method. returns true on success, false when validation fails. Other errors are signaled via Exceptions.
my_form.call! # same as call, but raises a ValidationError if validation fails
```

## Attributes

Attributes specify which attribute in the form can be set via a request

```ruby
class MyForm < Muffin::Base
  attribute :name # type String is implicit
  attribute :age, Integer # second argument defines type if present
  attribute :accepted?, Boolean # boolean is defined for true or false, converts strings like "on" or "off" (from forms) automatically to their boolean value
  attribute :tags, array: true # array of strings
  attribute :tags, [String] # same as above
end
```

Forms can contain validations

```ruby
class MyForm < Muffin::Base
  attribute :name
  validates :name, presence: true
end
```

And also give a list of required attributes (useful for html validation and marking them in the UI).

```ruby
my_form.required_attributes # [:name]
my_form.valid? # returns true/false
my_form.errors # returns an error object
```

Attributes are automatically assigned on init:

```ruby
my_form = MyForm.new(params: { name: "Superman" }) # assigns the name attribute
my_form.attributes # { name: "Superman" }
```

## Performing Changes

When `call` is invoked, the form performs validation steps. If those steps are successful, `perform` is called. `perform` is invoked inside of a transaction.

```ruby
class MyForm < Muffin::Base
  attribute :name

  def perform
    Model.find(5).update! name: name
  end
end
```

The form does not make any assumptions about what perform does except for needing all validations to be successful.

## Nesting forms

Attributes can be nested (this replaces `accepts_nested_attributes_for` and is compatible with its helpers, e.g. in forms).

```ruby
class WishlistForm < Muffin::Base
  attribute :children_name
  attribute :wishes do
    attribute :name
    validates :name, presence: true
  end
end

WishlistForm.new(params: { children_name: "Klaus", wishes: [{ name: "some cookies}])
```

## Manually assigning parameters

Sometimes it's necessary to manually assign attributes after initialization. In this case `assign_attributes` can be overriden (a call to super is optional and will invoke the normal behaviour).

```ruby
class MyForm < Form
  attribute :name

  def assign_attributes
    self.name = params[:name].downcase
  end
end

MyForm.new(params: { name: "Klaus" }).name # "klaus"
```

## Creating / updating active record objects

In the most simple case of a form mapping 1:1 to an active record object, the form object should be as simple as possible:

```ruby
class Object < ActiveRecord::Base
  # has a :name
end

class ObjectUpdateForm < Muffin::Base
  attribute :id
  attribute :name

  validates :name, presence: true

  def model
    @model ||= Object.find(params[:id])
  end

  private

  def assign_attributes
    self.name = model.name
    super # assigns the params hash
  end

  def perform
    model.update!(attributes.slice(:name))
  end
end

Post.first.name # "My Post" from Post 1
form = ObjectUpdateForm.new(params: { id: 1, name: "Updated Post" })
form.call
Post.first.name # "Updated Post"
```

## Updating nested active record objects

```ruby
class User < ActiveRecord::Base
  has_many :comments
end

class Comment < ActiveRecord::Base
  belongs_to :user
end

class MyForm < Muffin::Base
  attribute :id, Integer
  attribute :comments do
    attribute :id, Integer
    attribute :_destroy, Boolean
    attribute :text
  end

  def user
    @user ||= User.find(params[:id])
  end

  def assign_attributes
    self.attributes = user.attributes.merge(comments: user.comments.map(&:attributes))
    super
  end

  def perform
    update_nested! user.comments, comments
  end
end
```

`update_nested` will create new comments, update existing comments and destroy comments where `_destroy` is true. If no `:id` is present, it will create a new object always. If you don’t want to allow deleting, don’t add a `:_destroy` attribute.

## Integrating with policies

Policies are integrated with form objects.

```ruby
class MyForm < Muffin::Base
  attribute :name
  permitted? { scope.admin? }
end

form = MyForm.new(params: { name: "Klaus"}, scope: normal_user)
form.permitted? # false
form.call # raises NotPermitted
```

You can also permit single attributes depending on the user (which works as a replacement for strong attributes):

```ruby
class MyForm < Muffin::Base
  attribute :name, permit: -> { scope.admin? }
end

form = MyForm.new(params: { name: "Klaus"}, scope: normal_user)
form.name # nil
form.permitted? # true
form.attributes # { }, will not include non permitted attributes
form.attribute_permitted?(:name) # false
```

If permission should happen depending on the actual value of an attribute, this is possible, too.

```ruby
class MyForm < Muffin::Base
  attribute :role, permitted_values: -> { scope.admin? ? ["user", "admin"] : ["user"] }
end

form = MyForm.new(params: { role: "admin"}, scope: normal_user)
# will raise NotPermitted
form = MyForm.new(params: { role: "user"}, scope: normal_user)
form.attribute_permitted?(:role) # true
form.attribute_value_permitted?(:role, "admin") # false
form.permitted_values(:role) # ["user"]
```
## Integration with controllers

A form object should be easy to create from a controller with a special helper (inspired by Trailblazer).

```ruby
def create
  @form = prepare MyForm
  if @form.call
    redirect_to @form.model
  else
    render :new
  end
end
```

This will instantiate a form object, hand over the params and the context (e.g. the currently logged in user or auth scope) and performs depending on the method, which is roughly equivalent to

```ruby
def prepare(klass)
  scope = try(:form_auth_scope) || try(:current_user)
  processed_params = params[klass.model_name.underscore].permit!.to_h.map {...} # extract params from hash and clean up keys, e.g. comments_attributes -> comments
  klass.new params: processed_params, request: request, scope: scope
end
```

## Integration with Views

Form objects work with Rails' form helpers automatically.

```ruby
class SurveyForm < Form
  attribute :email
  attribute :answers do
    attribute :question_id, Integer
    attribute :answer

    validates :answer, presence: true
  end

  validates :email, presence: true
end

def new
  @survey = prepare SurveyForm
end


= form_for @survey do |f|
  = f.email_field :email
  = f.fields_for :answers do |ff|
    = ff.hidden_field :question_id
    = ff.text_field :answer
  = f.submit
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nerdgeschoss/muffin. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
