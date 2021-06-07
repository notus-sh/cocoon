# Cocooned

[![Build Status](https://travis-ci.org/notus-sh/cocooned.png?branch=master)](https://travis-ci.org/notus-sh/cocooned)

Cocooned makes it easier to handle nested forms in a Rails project.

Cocooned is form builder-agnostic: it works with standard Rails (>= 5.0, < 7.0) form helpers, [Formtastic](https://github.com/justinfrench/formtastic) or [SimpleForm](https://github.com/plataformatec/simple_form).

**Cocooned does not depend on jQuery** but can be integrated to use it. Your project, your choice.

## Some Background

Cocooned is a fork of [Cocoon](https://github.com/nathanvda/cocoon) by [Nathan Van der Auwera](https://github.com/nathanvda). He and all Cocoon contributors did a great job to maintain it for years. Many thanks to them!

However, the project seems to have only received minimal fixes since 2018 and many pull requests, even simple ones, have been on hold for a long time. In 2019, as I needed a more than what Cocoon provided at this time, I had the choice to either maintain an extension or to fork it and integrate everything that was waiting and more.

Cocooned is almost a complete rewrite of Cocoon, with more functionnalities, a more fluent API (I hope) and integration with modern toolchains (including webpacker).

**For now, Cocooned is completely compatible with Cocoon and can be used as a drop-in replacement** as long as we talk about Ruby code. Just change the name of the gem in your Gemfile and you're done. It will work the same (but will add a bunch of deprecation warning to your logs).

**This compatibility layer with the original Cocoon API will be dropped in Cocooned 3.0.**

On the JavaScript side, Cocoon 1.2.13 introduced the original browser event as a third parameter to all event handlers. Meanwhile, Cocooned already started to use this positional parameter to pass the Cocooned object instance (since 1.3.0). To get access to the original event, [you'll have to change your handlers and use `event.originalEvent`](#javascript-callbacks).

## Installation

Inside your `Gemfile` add the following:

```ruby
gem "cocooned"
```

### Load Cocooned styles and scripts

If you use Sprockets, you have to require `cocooned` in your `application.js` and `application.css`, so it compiles with the asset pipeline.

If you use Yarn to manage your non-Ruby dependencies and/or Webpack to build your assets, you can install the [`@notus.sh/cocooned` companion package](https://www.npmjs.com/package/@notus.sh/cocooned).

## Usage

For all the following examples, we will consider modelisation of an administrable list with items.
Here are the two ActiveRecord models : `List` and `Item`:

```ruby
class Item < ApplicationRecord
  has_many :items, inverse_of: :list
  accepts_nested_attributes_for :items, reject_if: :all_blank, allow_destroy: true
end

class Item < ApplicationRecord
  belongs_to :list
end
```

We will build a form where we can dynamically add and remove items to a list.

### Strong Parameters Gotcha

To destroy nested models, Rails uses a virtual attribute called `_destroy`.
When `_destroy` is set, the nested model will be deleted. If the record has previously been persisted, Rails generate and use an automatic `id` field to fetch the wannabe destroyed record.

When using Rails > 4.0 (or strong parameters), you need to explicitly add both `:id` and `:_destroy` to the list of permitted parameters.

E.g. in your `ListsController`:

```ruby
  def list_params
    params.require(:list).permit(:name, tasks_attributes: [:id, :description, :done, :_destroy])
  end
```

### Basic form

[Rails natively supports nested forms](https://guides.rubyonrails.org/form_helpers.html#nested-forms) but does not support adding or removing nested items.

```erb
<% # `app/views/lists/_form.html.erb` %>
<%= form_for @list do |f| %>
  <%= f.input :name %>
  
  <h3>Items</h3>
  <%= f.fields_for :tasks do |item_form| %>
    <% # This block is repeated for every task in @list.items %>
    <%= item_form.label :description %>
    <%= item_form.text_field :description %>
    <%= item_form.check_box :done %>
  <% end %>
  
  <%= f.submit "Save" %>
<% end %>
```

To enable Cocooned on this form, we need to:

1. Move the nested form to a partial
2. Add a way to add a new item to the collection
3. Add a way to remove an item from the collection
4. Initialize Cocooned to handle this form

Let's do it.

#### 1. Move the nested form to a partial

We now have two files:

```erb
<% # `app/views/lists/_form.html.erb` %>
<%= form_for @list do |form| %>
  <%= form.input :name %>
  
  <h3>Items</h3>
  <%= form.fields_for :items do |item_form|
    <%= render 'item_fields', f: item_form %>
  <% end %>
    
  <%= form.submit "Save" %>
<% end %>
```

```erb
<% # `app/views/lists/_item_fields.html.erb` %>
<%= f.label :description %>
<%= f.text_field :description %>
<%= f.check_box :done %>
```

#### 2. Add a way to add a new item to the collection

```erb
<% # `app/views/lists/_form.html.erb` %>
<%= form_for @list do |form| %>
  <%= form.input :name %>
  
  <h3>Items</h3>
  <div id="items">
    <%= form.fields_for :tasks do |item_form| %>
      <%= render 'item_fields', f: item_form %>
    <% end %>
    
    <div class="links">
      <%= cocooned_add_item_link 'Add an item', form, :items %>
    </div>
  </div>
  
  <%= form.submit "Save" %>
<% end %>
```

By default, a new item will be inserted just before the immediate parent of the 'Add an item' link. You can have a look at the documentation of `cocooned_add_item_link` for more information about how to change that but we'll keep it simple for now.

#### 3. Add a way to remove an item from the collection

```erb
<% # `app/views/lists/_item_fields.html.erb` %>
<div class="cocooned-item">
  <%= f.label :description %>
  <%= f.text_field :description %>
  <%= f.check_box :done %>
  <%= cocooned_remove_item_link 'Remove', f %>
</div>
```

The `cocooned-item` class is required for the `cocooned_remove_item_link` to work correctly.

#### 4. Initialize Cocooned to handle this form

Cocooned will detect on page load forms it should handle and initialize itself.
This detection is based on the presence of a `data-cocooned-options` attribute on the nested forms container.

```erb
<% # `app/views/lists/_form.html.erb` %>
<%= form_for @list do |form| %>
  <%= form.input :name %>
  
  <h3>Items</h3>
  <div id="items" data-cocooned-options="<%= {}.to_json %>">
    <%= form.fields_for :tasks do |item_form| %>
      <%= render 'item_fields', f: item_form %>
    <% end %>
    
    <div class="links">
      <%= cocooned_add_item_link 'Add an item', form, :items %>
    </div>
  </div>
  
  <%= form.submit "Save" %>
</div>
``` 

You're done!

### Wait, what's the point of `data-cocooned-options` if it's to be empty?

For simple use cases as the one we just demonstrated, the `data-cocooned-options` attributes only triggers the Cocooned initialization on page load. But you can use it to pass additional options to the Cocooned javascript and enable plugins.

For now, Cocooned supports two plugins:

* **Limit**, to set a maximum limit of items that can be added to the association
* **Reorderable**, that will automatically update `position` fields when you add or remove an item or when you reorder associated items.

#### The limit plugin

The limit plugin is autoloaded when needed and does not require anything more than you specifiying the maximum number of items allowed in the association.

```erb
<% # `app/views/lists/_form.html.erb` %>
<%= form_for @list do |form| %>
  <%= form.input :name %>
  
  <h3>Items</h3>
  <div id="items" data-cocooned-options="<%= { limit: 12 }.to_json %>">
    <%= form.fields_for :tasks do |item_form| %>
      <%= render 'item_fields', f: item_form %>
    <% end %>
    
    <div class="links">
      <%= cocooned_add_item_link 'Add an item', form, :items %>
    </div>
  </div>
  
  <%= form.submit "Save" %>
<% end %>
```

#### The reorderable plugin

The reorderable plugin is autoloaded when activated and does not support any particular options.

```erb
<% # `app/views/lists/_form.html.haml` %>
<%= form_for @list do |form| %>
  <%= form.input :name %>
  
  <h3>Items</h3>
  <div id="items" data-cocooned-options="<%= { reorderable: true }.to_json %>">
    <%= form.fields_for :tasks do |item_form| %>
      <%= render 'item_fields', f: item_form %>
    <% end %>
    
    <div class="links">
      <%= cocooned_add_item_link 'Add an item', form, :items %>
    </div>
  </div>
    
  <%= form.submit "Save" %>
<% end %>
```

However, you need to edit your nested partial to add the links that allow your users to move an item up or down in the collection and to add a `position` field.

```erb
<% # `app/views/lists/_item_fields.html.erb` %>
<div class="cocooned-item">
  <%= f.label :description %>
  <%= f.text_field :description %>
  <%= f.check_box :done %>
  <%= f.hidden_field :position %>
  <%= cocooned_move_item_up_link 'Up', f %>
  <%= cocooned_move_item_down_link 'Down', f %>
  <%= cocooned_remove_item_link 'Remove', f %>
</div>
```

Also, remember the strong parameters gotcha we mentioned earlier.

Of course, it means your model must have a `position` attribute you will use to sort collections.

## How it works

Cocooned defines some helper functions:

* `cocooned_add_item_link` will build a link that, when clicked, dynamically adds a new partial form for the given association. [Have a look at the documentation for available options](https://github.com/notus-sh/cocooned/blob/master/lib/cocooned/helpers.rb#L21).
* `cocooned_remove_item_link` will build a link that, when clicked, dynamically removes the surrounding partial form. [Have a look at the documentation for available options](https://github.com/notus-sh/cocooned/blob/master/lib/cocooned/helpers.rb#L143).
* `cocooned_move_item_up_link` and `cocooned_move_item_down_link` will build links that, when clicked, will move the surrounding partial form one step up or down in the collection. [Have a look at the documentation for available options](https://github.com/notus-sh/cocooned/blob/master/lib/cocooned/helpers.rb#L178).

### Javascript callbacks

When your collection is modified, the following events can be triggered:

* `cocooned:before-insert`: called before inserting a new nested child, can be [canceled](#canceling-an-action)
* `cocooned:after-insert`: called after inserting
* `cocooned:before-remove`: called before removing the nested child, can be [canceled](#canceling-an-action)
* `cocooned:after-remove`: called after removal

The limit plugin can trigger its own event:

* `cocooned:limit-reached`: called when the limit is reached (before a new item will be inserted)

And so does the reorderable plugin:

* `cocooned:before-move`: called before moving the nested child, can be [canceled](#canceling-an-action)
* `cocooned:after-move`: called after moving
* `cocooned:before-reindex`: called before updating the `position` fields of nested items, can be [canceled](#canceling-an-action) (even if I honestly don't know why you would)
* `cocooned:after-reindex`: called after `position` fields update

To listen to the events in your JavaScript:

```javascript
$('#container').on('cocooned:before-insert', function(event, node, cocoonedInstance) {
  /* Do something */
});
```

An event handler is called with 3 arguments:

The event `event` is an instance of `jQuery.Event` and carry some additional data:

* `event.link`, the clicked link
* `event.node`, the nested item that will be added, removed or moved, as a jQuery object. This is null for `cocooned:limit-reached` and `cocooned:*-reindex` events
* `event.nodes`, the nested items that will be or just have been reindexed on `cocooned:*-reindex` events, as a jQuery object. Null otherwise. 
* `event.cocooned`, the Cocooned javascript object instance handling the nested association.
* `event.originalEvent`, the original (browser) event.

The `node` argument is the same jQuery object as `event.node`.
The `cocooned` argument is the same as `event.cocooned`.

#### Canceling an action

You can cancel an action within the `cocooned:before-<action>` callback by calling `event.preventDefault()` or `event.stopPropagation()`.
