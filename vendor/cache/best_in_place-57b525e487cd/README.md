# Best In Place
[![Build Status](https://secure.travis-ci.org/bernat/best_in_place.png)](http://travis-ci.org/bernat/best_in_place)
**The Unobtrusive in Place editing solution**


##Description

**Best in Place** is a jQuery based AJAX Inplace-Editor that takes profit of RESTful server-side controllers to allow users to edit stuff with
no need of forms. If the server has standard defined REST methods, particularly those to UPDATE your objects (HTTP PUT), then by adding the
Javascript file to the application it allows all the fields with the proper defined classes to become user in-place editable.

The editor works by PUTting the updated value to the server and GETting the updated record afterwards to display the updated value.

---

##Installation

###Rails

Installing *best_in_place* is very easy and straight-forward.
Just begin including the gem in your Gemfile:

    gem 'best_in_place', '~> 3.0.1'

After that, specify the use of the jquery and best in place
javascripts in your application.js, and optionally specify jquery-ui if
you want to use jQuery UI datepickers:

    //= require jquery
    //= require best_in_place

    //= require jquery-ui
    //= require best_in_place.jquery-ui

If you want to use jQuery UI datepickers, you should also install and
load your preferred jquery-ui CSS file and associated assets.

Then, just add a binding to prepare all best in place fields when the document is ready:

    $(document).ready(function() {
      /* Activating Best In Place */
      jQuery(".best_in_place").best_in_place();
    });

You are done!

##Features

- Compatible with text **inputs**
- Compatible with **textarea**
- Compatible with **select** dropdown with custom collections
- Compatible with custom boolean values (same usage of **checkboxes**)
- Compatible with **jQuery UI Datepickers**
- Sanitize HTML and trim spaces of user's input on user's choice
- Displays server-side **validation** errors
- Allows external activator
- Allows optional, configurable OK and Cancel buttons for inputs and textareas
- ESC key destroys changes (requires user confirmation)
- Autogrowing textarea with **jQuery Autosize**
- Helper for generating the best_in_place field only if a condition is satisfied
- Provided test helpers to be used in your integration specs
- Custom display methods using a method from your model or an existing rails
  view helper

##Usage of Rails 3 Gem

###best_in_place
**best_in_place object, field, OPTIONS**

Params:

- **object** (Mandatory): The Object parameter represents the object itself you are about to modify
- **field** (Mandatory): The field (passed as symbol) is the attribute of the Object you are going to display/edit.

Options:

- **:as** It can be only [:input, :textarea, :select, :checkbox, :date] or if undefined it defaults to :input.
- **:collection**: If you are using the :select type then you must specify the collection of values it takes as a hash where values represent the display text and keys are the option's value when selected. If you are using the :checkbox type you can specify the two values it can take, or otherwise they will default to Yes and No.
- **:url**: URL to which the updating action will be sent. If not defined it defaults to the :object path.
- **:place_holder**: The nil param defines the content displayed in case no value is defined for that field. It can be something like "click me to edit".
  If not defined it will show *"-"*.
- **:activator**: Is the DOM object that can activate the field. If not defined the user will making editable by clicking on it.
- **:ok_button**: (Inputs and textareas only) If set to a string, then an OK button will be shown with the string as its label, replacing save on blur.
- **:ok_button_class**: (Inputs and textareas only) Specifies any extra classes to set on the OK button.
- **:cancel_button**: (Inputs and textareas only) If set to a string, then a Cancel button will be shown with the string as its label.
- **:cancel_button_class**: (Inputs and textareas only) Specifies any extra classes to set on the Cancel button.
- **:sanitize**: True by default. If set to false the input/textarea will accept html tags.
- **:html_attrs**: Hash of html arguments such as maxlength, default-value, etc. that will be set on the rendered input **not** the best_in_place span.
- **:inner_class**: Class that is set to the rendered input.
- **:display_as**: A **model** method which will be called in order to display this field. Cannot be used when using `display_with`.
- **:display_with**: A **helper** method or proc will be called in order to display this field. Cannot be used with `display_as`.
- **:helper_options**: A hash of parameters to be sent to the helper method specified by `display_with`.
- **:data**: Hash of custom data attributes to be added to span. Can be used to provide data to the ajax:success callback.
- **:class**: Additional classes to apply to the best_in_place span.  Accepts either a string or Array of strings
- **:value**: Customize the starting value of the inline input (defaults to to the field's value)
- **:id**: The HTML id of the best_in_place span. If not specified one is automatically generated.
- **:param**: If you wish to specific the object explicitly use this option.
- **:confirm**: If set to true displays a confirmation message when abandoning changes (pressing the escape key).
- **:skip_blur**: If set to true, blurring the input will not cause changes to be abandoned in textareas.

HTML Options:

If you provide an option that is not explicitly a best_in_place option it will be passed through when creating the best_in_place span.

So, for instance, if you want to add an HTML tab index to the best_in_place span just add it to your method call:

    <%= best_in_place @user, :name, tabindex: "1" %>

###best_in_place_if
**best_in_place_if condition, object, field, OPTIONS**
see also **best_in_place_unless**

It allows us to use best_in_place only if the first new parameter, a
condition, is satisfied. Specifically:

* Will show a normal best_in_place if the condition is satisfied
* Will only show the attribute from the instance if the condition is not satisfied

Say we have something like

    <%= best_in_place_if condition, @user, :name, :as => :input %>

In case *condition* is satisfied, the outcome will be just the same as:

    <%= best_in_place @user, :name, :as => :input %>

Otherwise, we will have the same outcome as:

    <%= @user.name %>

It is a very useful feature to use with, for example, [Ryan Bates](https://github.com/ryanb)' [CanCan](https://github.com/ryanb/cancan), so we only allow BIP edition if the current user has permission to do it.

---

## Examples

Examples (code in the views):

### Input

    <%= best_in_place @user, :name, :as => :input %>

    <%= best_in_place @user, :name, :as => :input, :place_holder => "Click me to add content!" %>

### Textarea

    <%= best_in_place @user, :description, :as => :textarea %>

    <%= best_in_place @user, :favorite_books, :as => :textarea, :ok_button => 'Save', :cancel_button => 'Cancel' %>

### Select

    <%= best_in_place @user, :country, :as => :select, :collection => {"1" => "Spain", "2" => "Italy", "3" => "Germany", "4" => "France"} %>
    <%= best_in_place @user, :country, :as => :select, :collection => { es: 'Spain', it: 'Italy', de: 'Germany', fr: 'France' } %>
    <%= best_in_place @user, :country, :as => :select, :collection => %w(Spain Italy Germany France) %>
    <%= best_in_place @user, :country, :as => :select, :collection => [[1, 'Spain'], [3, 'Germany'], [2, 'Italy'], [4, 'France']] %>

Of course it can take an instance or global variable for the collection, just remember the structure is a hash.
The value will always be converted to a string for display.

### Checkbox

    <%= best_in_place @user, :receive_emails, as: :checkbox, collection: ["No, thanks", "Yes, of course!"] %>
    <%= best_in_place @user, :receive_emails, as: :checkbox, collection: {false: "Nope", true: "Yep"} %>

If you use array as a collection, the first value is always the negative boolean value and the second the positive. Structure: `["false value", "true value"]`.
If not defined, it will default to *Yes* and *No* options.
Default true and false values are stored in locales
 
    t(:'best_in_place.yes', default: 'Yes')
    t(:'best_in_place.no', default: 'No')

### Date

    <%= best_in_place @user, :birth_date, :as => :date %>

With the :date type the input field will be initialized as a datepicker input.
In order to provide custom options to the datepicker initialization you must
prepare a `$.datepicker.setDefaults` call with the preferences of your choice.

More information about datepicker and setting defaults can be found
[here](http://docs.jquery.com/UI/Datepicker/$.datepicker.setDefaults)

## Controller response with respond_with_bip

Best in place provides a utility method you should use in your controller in
order to provide the response that is expected by the javascript side, using
the :json format. This is a simple example showing an update action using it:

    def update
      @user = User.find params[:id]

      respond_to do |format|
        if @user.update_attributes(params[:user])
          format.html { redirect_to(@user, :notice => 'User was successfully updated.') }
          format.json { respond_with_bip(@user) }
        else
          format.html { render :action => "edit" }
          format.json { respond_with_bip(@user) }
        end
      end
    end


## Custom display methods

### Using `display_as`

As of best in place 1.0.3 you can use custom methods in your model in order to
decide how a certain field has to be displayed. You can write something like:

    = best_in_place @user, :description, :as => :textarea, :display_as => :mk_description

Then instead of using `@user.description` to show the actual value, best in
place will call `@user.mk_description`. This can be used for any kind of
custom formatting, text with markdown, etc...

### Using `display_with`

In practice the most common situation is when you want to use an existing
helper to render the attribute, like `number_to_currency` or `simple_format`.
As of version 1.0.4 best in place provides this feature using the
`display_with` option. You can use it like this:

    = best_in_place @user, :money, :display_with => :number_to_currency

If you want to pass further arguments to the helper you can do it providing an
additional `helper_options` hash:

    = best_in_place @user, :money, :display_with => :number_to_currency, :helper_options => {:unit => "€"}

You can also pass in a proc or lambda like this:

    = best_in_place @post, :body, :display_with => lambda { |v| textilize(v).html_safe }

## Ajax success callback

### Binding to ajax:success

The 'ajax:success' event is triggered upon success. Use bind:

    $('.best_in_place').bind("ajax:success", function () {$(this).closest('tr').effect('highlight'); });

To bind a callback that is specific to a particular field, use the 'classes' option in the helper method and
then bind to that class.

    <%= best_in_place @user, :name, :classes => 'highlight_on_success' %>
    <%= best_in_place @user, :mail, :classes => 'bounce_on_success' %>

    $('.highlight_on_success').bind("ajax:success", function(){$(this).closest('tr').effect('highlight');});
    $('.bounce_on_success').bind("ajax:success", function(){$(this).closest('tr').effect('bounce');});

### Providing data to the callback

Use the :data option to add HTML5 data attributes to the best_in_place span. For example, in your view:

    <%= best_in_place @user, :name, :data => {:user_name => @user.name} %>

And in your javascript:

    $('.best_in_place').bind("ajax:success", function(){ alert('Name updated for '+$(this).data('userName')); });

##Non Active Record environments
We are not planning to support other ORMs apart from Active Record, at least for now. So, you can perfectly consider the following workaround as *the right way* until a specific implementation is done for your ORM.

Best In Place automatically assumes that Active Record is the ORM you are using. However, this might not be your case, as you might use another ORM (or not ORM at all for that case!). Good news for you: even in such situation Best In Place can be used!

Let's setup an example so we can illustrate how to use Best In Place too in a non-ORM case. Imagine you have an awesome ice cream shop, and you have a model representing a single type of ice cream. The IceCream model has a name, a description, a... nevermind. The thing is that it also has a stock, which is a combination of flavour and size. A big chocolate ice cream (yummy!), a small paella ice cream (...really?), and so on. Shall we see some code?

    class IceCream < ActiveRecord::Base
      serialize :stock, Hash

      # consider the get_stock and set_stock methods are already defined
    end

Imagine we want to have a grid showing all the combinations of flavour and size and, for each combination, an editable stock. Since the stock for a flavour and a size is not a single and complete model attribute, we cannot use Best In Place *directly*. But we can set it up with an easy workaround.

In the view, we'd do:

    // @ice_cream is already available
    - flavours = ... // get them somewhere
    - sizes = ... // get them somewhere
    table
      tr
        - flavours.each do |flavour|
          th= flavour
      - sizes.each do |size|
        tr
          th= size
          - flavours.each do |flavour|
            - v = @ice_cream.get_stock(flavour: flavour, size: size)
            td= best_in_place v, :to_i, as: :input, url: set_stock_ice_cream_path(flavour: flavour, size: size)

Now we need a route to which send the stock updates:

    TheAwesomeIceCreamShop::Application.routes.draw do
      ...

      resources :ice_creams, :only => :none do
        member do
          put :set_stock
        end
      end

      ...
    end

And finally we need a controller:


    class IceCreamsController < ApplicationController::Base
      respond_to :html, :json

      ...

      def set_stock
        flavour = params[:flavour]
        size = params[:size]
        new_stock = (params["fixnum"] || {})["to_i"]

        @ice_cream.set_stock(new_stock, { :flavour => flavour, :size => size })
        if @ice_cream.save
          head :ok
        else
          render :json => @ice_cream.errors.full_messages, :status => :unprocessable_entity
        end
      end

      ...

    end

And this is how it is done!

## Configuration

You can configure some global options for best_in_place. Currently these options are available:

    BestInPlace.configure do |config|
      config.container = :div
      config.skip_blur = true
    end
    

## Notification

Sometimes your in-place updates will fail due to validation or for some other reason. In such case, you'll want to notify the user somehow. **Best in Place** supports doing so through the best_in_place:error event, and has built-in support for notification via jquery.purr, right out of the box.

To opt into the jquery.purr error notification, just add best_in_place.purr to your javascripts, as described below.

    //= require jquery.purr
    //= require best_in_place.purr

If you'd like to develop your own custom form of error notification, you can use best_in_place.purr as an example to guide you.

## Security

If the script is used with the Rails Gem no html tags will be allowed unless the sanitize option is set to true, in that case only the tags [*b i u s a strong em p h1 h2 h3 h4 h5 ul li ol hr pre span img*] will be allowed. If the script is used without the gem and with frameworks other than Rails, then you should make sure you are providing the csrf authenticity params as meta tags and you should always escape undesired html tags such as script, object and so forth.

    <meta name="csrf-param" content="authenticity_token"/>
    <meta name="csrf-token" content="YOUR UNIQUE TOKEN HERE"/>

---

##TODO

- Client Side Validation definitions
- Accepting more than one handler to activate best_in_place fields

---

## Development

Fork the project on [github](https://github.com/bernat/best_in_place 'bernat / best_in_place on Github')

    $ git clone <your fork>
    $ cd best_in_place
    $ bundle

### Run the specs

    $ appraisal
    $ appraisal rspec

You many need to install appraisal: `gem install appraisal`

---

##Test Helpers
Best In Place has also some helpers that may be very useful for integration testing. Since it might very common to test some views using Best In Place, some helpers are provided to ease it.

As of now, a total of four helpers are available. There is one for each of the following BIP types: a plain text input, a textarea, a boolean input and a selector. Its function is to simulate the user's action of filling such fields.

These four helpers are listed below:

* **bip_area(model, attr, new_value)**
* **bip_text(model, attr, new_value)**
* **bip_bool(model, attr)**
* **bip_select(model, attr, name)**

The parameters are defined here (some are method-specific):

* **model**: the model to which this action applies.
* **attr**: the attribute of the model to which this action applies.
* **new_value** (only **bip_area** and **bip_text**): the new value with which to fill the BIP field.
* **name** (only **bip_select**): the name to select from the dropdown selector.

---

##Authors, License and Stuff

Code by [Bernat Farrero](http://bernatfarrero.com) from [Itnig Web Services](http://itnig.net) (it was based on the [original project](http://github.com/janv/rest_in_place/) of Jan Varwig) and released under [MIT license](http://www.opensource.org/licenses/mit-license.php).

Many thanks to the contributors: [Roger Campos](http://github.com/rogercampos), [Jack Senechal](https://github.com/jacksenechal) and [Albert Bellonch](https://github.com/albertbellonch).
