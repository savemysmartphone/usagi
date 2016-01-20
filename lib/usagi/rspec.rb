RSpec::Matchers.define :usagi_scenario do |*api_declaration|
  description do
    api_declaration.first
  end

  match do |data|
    api_scenario, api_opts = *api_declaration
    api_opts = Usagi.suite_options.deep_merge(api_opts || {})
    current_context = @matcher_execution_context.class.metadata[:description]

    file_path = @matcher_execution_context.class.metadata[:file_path].gsub(/\.rb$/, '.yml')
    raise "missing scenario file: #{file_path}" unless File.exist?(file_path)
    scenario = YAML.load_file(file_path)
    raise "missing context: #{current_context}" unless scenario[current_context]
    raise "missing scenario: #{current_context}:#{api_scenario}" unless scenario[current_context][api_scenario]
    scenario = JSON.parse(scenario[current_context][api_scenario].to_json)
    protocol, path = scenario['query'].split(' ')
    query = URI.parse(path).query
    path  = URI.parse(path).path
    query = Rack::Utils.parse_nested_query(query).merge(api_opts[:query] || {}).to_query
    post_data = api_opts[:body]
    headers   = api_opts[:headers] || {}
    headers['Cookie'] = Usagi.cookies if Usagi.suite_options[:cookies]

    full_uri = URI::HTTP.build([
      nil,
      "localhost",
      Usagi.port,
      path,
      query,
      nil
    ]).to_s
    data = %[curl -i --silent -X #{protocol} "#{full_uri}"]
    data += %[ --data "#{post_data.to_query}"] if post_data && post_data.keys.length > 0
    headers.each do |key, value|
      data += %[ -H "#{key}: #{value}"]
    end if headers
    puts "REQ__#{data}__" if Usagi.options[:debug_requests]
    data = `#{data}`
    head, body = data.split("\r\n\r\n", 2)
    head.each_line do |li|
      Usagi.cookies = li.split(' ', 2).last if li =~ /^Set-Cookie:/
    end if Usagi.suite_options[:cookies]
    puts "RES__#{body}__" if Usagi.options[:debug_requests]
    body = JSON.parse(body)
    Usagi::ApiResponse.new(scenario['reply']) == body
  end
end
