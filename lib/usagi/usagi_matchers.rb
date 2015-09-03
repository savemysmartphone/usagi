require_relative 'matcher_container'

Usagi.define_matcher :any_value do
  match do
    true
  end
end

Usagi.define_matcher :any_value_not_nil do
  error do
    "expected to be a non-nil value"
  end

  match do |api_value|
    api_value != nil
  end
end

Usagi.define_matcher :range do |from, to|
  error do |api_value|
    "expected to be in range #{from}..#{to} (got: #{api_value})"
  end

  match do |api_value|
    api_value >= from && api_value <= to
  end
end
