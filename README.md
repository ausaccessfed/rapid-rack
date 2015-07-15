# RapidRack

[![Gem Version][GV img]][Gem Version]
[![Build Status][BS img]][Build Status]
[![Dependency Status][DS img]][Dependency Status]
[![Code Climate][CC img]][Code Climate]
[![Coverage Status][CS img]][Code Climate]

[Gem Version]: https://rubygems.org/gems/rapid-rack
[Build Status]: https://codeship.com/projects/91209
[Dependency Status]: https://gemnasium.com/ausaccessfed/rapid-rack
[Code Climate]: https://codeclimate.com/github/ausaccessfed/rapid-rack

[GV img]: https://img.shields.io/gem/v/rapid-rack.svg
[BS img]: https://img.shields.io/codeship/6fad8f80-0cd0-0133-0d1a-36a99efb0264/develop.svg
[DS img]: https://img.shields.io/gemnasium/ausaccessfed/rapid-rack/develop.svg
[CC img]: https://img.shields.io/codeclimate/github/ausaccessfed/rapid-rack.svg
[CS img]: https://img.shields.io/codeclimate/coverage/github/ausaccessfed/rapid-rack.svg

[AAF Rapid Connect](https://rapid.aaf.edu.au) authentication plugin for
Rack-based web applications. Contains Rails-specific extensions for consumption
by Rails applications.

Author: Shaun Mangelsdorf

```
Copyright 2014-2015, Australian Access Federation

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

## Installation

Add the `rapid-rack` dependency to your application's `Gemfile`:

```
gem 'rapid-rack'
```

Use Bundler to install the dependency:

```
bundle install
```

Create a Receiver class, which will receive the validated claim from Rapid
Connect and establish a session for the authenticated subject.

```ruby
module MyApplication
  class MyReceiver
    # Helper mixin which provides default behaviour for the Receiver class
    include RapidRack::DefaultReceiver

    # Default implementation of Redis-backed replay detection
    include RapidRack::RedisRegistry

    # Receives the contents of the 'https://aaf.edu.au/attributes' claim from
    # Rapid Connect, and returns a set of attributes appropriate for passing in
    # to the `subject` method.
    def map_attributes(_env, attrs)
      {
        targeted_id: attrs['edupersontargetedid'],
        name: attrs['displayname'],
        email: attrs['mail']
      }
    end

    # Receives a set of attributes returned by `map_attributes`, and is
    # responsible for either creating a new user record, or updating an existing
    # user record to ensure attributes are current.
    #
    # Must return the subject, and the subject must have an `id` method to work
    # with the DefaultReceiver mixin.
    def subject(_env, attrs)
      identifier = attrs.slice(:targeted_id)
      MyOwnUserClass.find_or_initialize_by(identifier).tap do |subject|
        subject.update_attributes!(attrs)
      end
    end
  end
end
```

### Integrating with a Rack application

Map the `RapidRack::Authenticator` app to a path in your application. The
strongly suggested default of `/auth` will result in a callback URL ending in
`/auth/jwt`, which is given to Rapid Connect during registration:

```ruby
Rack::Builder.new do
  use Rack::Lint

  map '/auth' do
    opts = { ... }
    run RapidRack::Authenticator.new(opts)
  end

  run MyApplication
end
```

`opts` must be the same arguments derived from the Rails configuration below,
that is:

* `url` &mdash; The URL provided during registration with Rapid Connect
* `secret` &mdash; Your extremely secure secret
* `issuer` &mdash; The `iss` claim to expect. This is the identifier of the
  Rapid Connect server you're authenticating against
* `audience` &mdash; The `aud` claim to expect. This is your own service's
  identifier
* `receiver` &mdash; **String** representing the fully qualified class name of
  your receiver class
* `error_handler` *(optional)* &mdash; **String** representing the fully
  qualified class name of your error handler class

In the `opts` hash, all keys must be symbols.

### Integrating with a Rails application

Add a `config/rapidconnect.yml` file to your application, with the
deployment-specific options described above:

```yaml
---
url: https://rapid.example.com/url/provided/by/registration
secret: very_secure_secret_you_generated_yourself
issuer: https://rapid.example.com
audience: https://yourapp.example.org
```

Configure the receiver, and optional error handler in `config/application.rb`:

```ruby
module MyApplication
  class Application < Rails::Application
    # ...

    config.rapid_rack.receiver = 'MyApplication::MyReceiver'
    config.rapid_rack.error_handler = 'MyApplication::MyErrorHandler'
  end
end
```

Mount the `RapidRack::Engine` engine in your Rails app.  The strongly suggested
default of `/auth` will result in a callback URL ending in `/auth/jwt`, which is
given to Rapid Connect during registration. In `config/routes.rb`:

```ruby
Rails.application.routes.draw do
  mount RapidRack::Engine => '/auth'

  # ...
end
```

Redirect to `/auth/login` to force authentication. By default, the subject id is
available as `session[:subject_id]`. For example:

```ruby
class WelcomeController < ApplicationController
  before_action do
    @subject = session[:subject_id] && MyOwnUserClass.find(session[:subject_id])
    redirect_to('/auth/login') if @subject.nil?
  end

  def index
  end
end
```

### Using with Capybara-style tests

Configure `rapid_rack` to run in test mode. In a Rails application this can be
set in `config/environments/test.rb`:

```ruby
Rails.application.configure do
  # ...

  config.rapid_rack.test_mode = true
end
```

Set the JWT in your test code. In this example factory\_girl has a `jwt` factory
registered which creates a valid JWT.

```ruby
RSpec.feature 'First visit', type: :feature do
  given(:user_attrs) { attributes_for(:user) }

  background do
    attrs = create(:aaf_attributes, displayname: user_attrs[:name],
                                    mail: user_attrs[:email])
    RapidRack::TestAuthenticator.jwt = create(:jwt, aaf_attributes: attrs)
  end

  # ...
end
```

Once this is in place, your example will be presented with a plain page with a
'Login' button when it is required to log in. The button will submit the form
to the `/auth/jwt` endpoint, which works as normal and will invoke your
receiver.

```ruby
RSpec.feature 'First visit', type: :feature do
  # ... code from above ...

  scenario 'initial login' do
    visit '/'
    click_button 'Sign in via AAF'

    # At this point, your Capybara test is sitting in the TestAuthenticator page
    # which has a 'Login' button and no other content.
    expect(current_path).to eq('/auth/login')
    click_button 'Login'

    expect(current_path).to match(%r{/users/\d+})
    expect(page).to have_content("Logged in as: #{user_attrs[:name]}")
  end
end
```

## Contributing

Refer to [GitHub Flow](https://guides.github.com/introduction/flow/) for
help contributing to this project.
