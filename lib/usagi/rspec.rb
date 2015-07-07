RSpec::Matchers.define :usagi_scenario do |*api_declaration|
  description do
    api_declaration.first
  end

  match do |data|
    api_scenario, api_opts = *api_declaration
    api_opts ||= {}
    current_context = @matcher_execution_context.class.metadata[:description]

    #file_path = @ma'/Users/red/save/si-api-sync/spec/usagi/brands/logged_in.yml'
    file_path = @matcher_execution_context.class.metadata[:file_path].gsub(/\.rb$/, '.yml')
    raise "missing scenario: #{file_path}" unless File.exist?(file_path)
    scenario = YAML.load_file(file_path)
    raise "missing context: #{current_context}" unless scenario[current_context]
    raise "missing scenario: #{current_context}:#{api_scenario}" unless scenario[current_context][api_scenario]
    scenario = JSON.parse(scenario[current_context][api_scenario].to_json)
    protocol, path = scenario['query'].split(' ')
    path, query = [:path, :query].map{|f| URI.parse(path).send(f) }
    query = Rack::Utils.parse_nested_query(query).merge(api_opts[:query] || {}).to_query
    full_uri = URI::HTTP.build([
      nil,
      "localhost",
      ENV['USAGI_PORT'].to_i,
      path,
      query,
      nil
    ]).to_s
    data = %[curl --silent -X #{protocol} "#{full_uri}"]
    data = `#{data}`
    data = JSON.parse(data)
    Usagi::ApiResponse.new(scenario['reply']) == data
  end
end
