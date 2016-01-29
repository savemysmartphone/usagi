# Usagi
兎 - Usagi is a functional test suite for Ruby on Rails APIs, depending on the RSpec
(rspec-core & rspec-rails) testing framework.

See also:

- [rspec](http://rspec.info/)
- [rspec-rails](https://github.com/rspec/rspec-rails)


## Description

**Usagi** means `rabbit` in Japanese.
It's a simple, easy-to-handle testing tool for your API requests, based on RSpec.


## Installation

Add Usagi to **both** the `:development` and `:test`  groups in the `Gemfile`:

```
group :development, :test do
  gem 'usagi'
end
```

Then run `bundle install`.

Initialize the `spec/` directory from RSpec with:

```
rails generate rspec:install
```

This adds the following files used for configuration:

- `.rspec`
- `spec/spec_helper.rb`
- `spec/rails_helper.rb`

Fore more information about RSpec, read their [documentation](http://rspec.info/).


You can also add your own `usagi_helper.rb` file to create your own matchers (don't forget to require it at the top of each usagi_spec file).
Add the `spec/usagi` directory (where usagi specs will reside).

Use the `usagi` **command** to run your specs:

```
bundle exec usagi
```

By default the above will run all `.rb` files in the `spec/usagi` directory and its subdirectories.
***Be careful to not add the `_spec.rb` extension to your usagi files, since it'll compromise the proper execution of `rspec`.***

You can specify a subset of the specs with the following command:

```
# Run only feature specs
bundle exec usagi spec/usagi/features

# Run only usagi specs for your filter feature
bundle exec usagi spec/usagi/features/filters.rb
```

## Options
Run the following command to check out all the available options:

```
bundle exec usagi --help
```

All the provided options by RSpec are also available by default.

## Usage

### Spec file
The DSL is similar to RSpec. The use of `describe` is decorative. Describe your scenario using `context` and `usagi_scenario` helper inside an `it` block.
Your spec file may look like this.

```
# spec/usagi/features/sort_by.rb
# require 'spec_helper'
require 'usagi_helper'

describe 'FEATURE: sort_by' do
    before :all do
      # Populate the database
      Post.create(title: 'Bar', author: 'bar@bar.com')
      Post.create(title: 'Foo', author: 'foo@foo.com')
    end

    after :all do
      # Clean Usagi suite options after running the tests
      Usagi.suite_options = {}
      # Clean the database (https://github.com/DatabaseCleaner/database_cleaner)
      DatabaseCleaner.clean
    end

  context 'Default sort for Posts' do
    it { should usagi_scenario('sort posts by title ASC') }
    it { should usagi_scenario('sort posts by title DESC') }
  end
end
```

The above example uses only standard Rails and RSpec APIs, but many RSpec/Rails users like to use extension libraries like [FactoryGirl](https://github.com/thoughtbot/factory_girl) and [DatabaseCleaner](https://github.com/DatabaseCleaner/database_cleaner).

### Scenario
The scenario YAML file is **the expected output of your API requests**, named after the execution file. It lists all the **contexts** and **usagi scenario** described in the `.rb` corresponding file.

It requires the following fields:

- **context**: `[Context]`
- **scenario**: `[usagi_scenario]`
- **query**: `[HTTP VERB] [PATH]`
- **reply**: `[EXPECTED API OUTPUT]`

```
# spec/usagi/features/sort_by.yml
Default sort:
  sort posts by title ASC:
  query: GET /v1/posts?sort_by=title:ASC
  reply: {
    posts: [
      {
        id: 1,
        title: 'Bar',
        author: 'bar@bar.com'
      },
      {
        id: 2,
        title: 'Foo',
        author: 'foo@foo.com'
      }
    ]
  }
  sort posts by title DESC:
  query: GET /v1/posts?sort_by=title:DESC
  reply: {
    posts: [
      {
        id: 2,
        title: 'Foo',
        author: 'foo@foo.com'
      },
        {
        id: 1,
        title: 'Bar',
        author: 'bar@bar.com'
      }
    ]
  }
```

## Advanced usage

### Passing query options
You can call `#usagi_scenario` supplying **query** and **body** parameters as an options hash.

```
# spec/usagi/posts.rb
describe 'Posts (actions)' do
  context 'Posts (CREATE)' do
    it do
      opts = {
        # query: additional query parameters if needed
        body: {
          title: 'New post',
          author: 'me@me.com'
        }
      }
      should usagi_scenario('return the created post with right attributes', opts)
    end
  end
end
```
And the corresponding YAML scenario:

```
# spec/usagi/posts.yml
Posts (CREATE):
  query: POST /v1/posts
  reply: {
    post: {
      id: ANY_VALUE_NOT_NIL, # one of the default value matcher provided by the gem
      title: 'New post',
      author: 'me@me.com',
      created_at: ANY_VALUE # other usagi matcher
    }
  }
```

### Usagi Matchers
The default matchers are the following ones:

- **ANY_VALUE**: any value from API response (returns always true)

  `title: ANY_VALUE`
- **ANY_VALUE_NOT_NIL** any not null/nil value from API response

  `id: ANY_VALUE_NOT_NIL`
- **RANGE** any API response value belonging to the specified range

  `rating: RANGE(1, 5)`
- **OBJ_HAS_MANY** number of nested objects

  Instead of having:

  ```
  post: {
    id: ANY_VALUE_NOT_NIL,
    comments: [
      {
        id: 1,
        message: 'first comment'
      },
      {
        id: 2,
        message: 'second comment'
      },
      ...
    ]
  }
  ```
  You can write (if you're not interesting in matching the nested objects content):

  ```
  post: {
    id: ANY_VALUE,
    comments: OBJ_HAS_MANY(5)
  }

  ```

- **ANY_VALUE_MATCHES** any API response value matching to the given regexp

  `token: ANY_VALUE_MATCHES(/\A[a-fA-F0-9]{64}\z/)`



You can add your own usagi matchers in your `usagi_helper.rb`  file using the following DSL:

```
Usagi.define_matcher :name_of_your_matcher do |matcher_args|
  error do |api_value|
    "expected to match something (got: #{api_value})"
  end

  match do |api_value|
    # your matching code here returning true or false
  end
end

```

### Adding suite options
Default unmatchable keys are `:created_at` and `:updated_at`, you can rewrite this option this way:

```
Usagi.suite_options = {
  unmatchable_keys: [:id, :updated_at, :created_at]
}
```
