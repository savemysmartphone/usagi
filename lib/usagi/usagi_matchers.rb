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

Usagi.define_matcher :obj_has_many do |object_counts, object_keys|
  error do |api_value|
    "expected to have #{object_counts} objects, with the following keys: #{object_keys.sort} (got #{api_value.length} objects with keys: #{api_value.map(&:keys).flatten.uniq.map(&:to_sym).sort}"
  end

  match do |api_value|
    next nil unless api_value.length == object_counts
    api_value.all?{|row| row.keys.map(&:to_sym).sort == object_keys.sort }
  end
end
