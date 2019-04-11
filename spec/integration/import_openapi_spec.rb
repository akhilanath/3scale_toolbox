require '3scale_toolbox'

RSpec.shared_context :import_oas_stubbed_api3scale_client do
  let(:internal_http_client) { double('internal_http_client') }
  let(:http_client_class) { class_double('ThreeScale::API::HttpClient').as_stubbed_const }

  let(:endpoint) { 'https://example.com' }
  let(:provider_key) { '123456789' }
  let(:verify_ssl) { true }
  let(:external_http_client) { double('external_http_client') }
  let(:api3scale_client) { ThreeScale::API::Client.new(external_http_client) }
  let(:fake_service_id) { 100 }
  let(:backend_version) { '1' }

  let(:service_attr) do
    { 'service' => { 'id' => fake_service_id,
                     'system_name' => 'some_system_name',
                     'backend_version' => backend_version } }
  end
  let(:metrics) do
    {
      'metrics' => [
        { 'metric' => { 'id' => '1', 'system_name' => 'hits' } }
      ]
    }
  end

  let(:service_policies) do
    {
      'policies_config' => [
        { 'name' => 'apicast', 'version' => 'builtin', 'configuration' => {}, 'enabled' => true }
      ]
    }
  end

  let(:external_methods) do
    {
      'methods' => [
        { 'method' => { 'id' => '0', 'friendly_name' => 'old_method', 'system_name' => 'old_method' } },
        { 'method' => { 'id' => '1', 'friendly_name' => 'addPet', 'system_name' => 'addpet' } },
        { 'method' => { 'id' => '2', 'friendly_name' => 'updatePet', 'system_name' => 'updatepet' } },
        { 'method' => { 'id' => '3', 'friendly_name' => 'findPetsByStatus', 'system_name' => 'findpetsbystatus' } }
      ]
    }
  end
  let(:external_mapping_rules) do
    {
      'mapping_rules' => [
        { 'mapping_rule' => { 'delta' => 1, 'http_method' => 'POST', 'pattern' => '/v2/pet$' } },
        { 'mapping_rule' => { 'delta' => 1, 'http_method' => 'PUT', 'pattern' => '/v2/pet$' } },
        { 'mapping_rule' => { 'delta' => 1, 'http_method' => 'GET', 'pattern' => '/v2/pet/findByStatus$' } }
      ]
    }
  end
  let(:existing_mapping_rules) do
    {
      'mapping_rules' => [
        { 'mapping_rule' => { 'id' => '1', 'delta' => 1, 'http_method' => 'GET', 'pattern' => '/' } }
      ]
    }
  end
  let(:existing_services) do
    {
      'services' => [
        { 'service' => { 'id' => fake_service_id, 'system_name' => system_name } }
      ]
    }
  end
  let(:external_activedocs) do
    {
      'api_docs' => [
        {
          'api_doc' => {
            'id' => 4, 'name' => 'Swagger Petstore', 'system_name' => system_name,
            'service_id' => service_id, 'body' => oas_resource_json
          }
        }
      ]
    }
  end

  let(:external_proxy) do
    {
      'proxy' => {
        'service_id' => 2555417777578,
        'endpoint' => 'https://some-service-01-2445582057490.production.gw.apicast.io:443',
        'api_backend' => 'https://petstore.swagger.io:443',
        'credentials_location' => 'headers',
        'auth_app_key' => 'app_key',
        'auth_app_id' => 'app_id',
        'auth_user_key' => 'api_key',
        'oidc_issuer_endpoint' => 'https://issuer.com'
      }
    }
  end

  before :example do
    puts '============ RUNNING STUBBED 3SCALE API CLIENT =========='
    ##
    # Internal http client stub
    allow(internal_http_client).to receive(:post).with('/admin/api/services', anything)
                                                 .and_return(service_attr)
    expect(http_client_class).to receive(:new).and_return(internal_http_client)
    expect(internal_http_client).to receive(:get).with('/admin/api/services/100/metrics')
                                                 .and_return(metrics)
    expect(internal_http_client).to receive(:post).with('/admin/api/services/100/metrics/1/methods', anything)
                                                  .at_least(:once)
                                                  .and_return('id' => '1')
    expect(internal_http_client).to receive(:get).with('/admin/api/services/100/proxy/mapping_rules').and_return(existing_mapping_rules)
    expect(internal_http_client).to receive(:delete).with('/admin/api/services/100/proxy/mapping_rules/1')
    expect(internal_http_client).to receive(:post).with('/admin/api/services/100/proxy/mapping_rules', anything)
                                                  .at_least(:once)
    expect(internal_http_client).to receive(:post).with('/admin/api/active_docs', anything).and_return({})
    expect(internal_http_client).to receive(:get).with('/admin/api/services/100').and_return(service_attr)
    expect(internal_http_client).to receive(:patch).with('/admin/api/services/100/proxy', anything).and_return({})
    expect(internal_http_client).to receive(:get).with('/admin/api/services/100/proxy/policies')
                                                 .and_return(service_policies)
    # Not all the tests update the following settings
    allow(internal_http_client).to receive(:patch).with('/admin/api/services/100/proxy/oidc_configuration', anything).and_return({})
    allow(internal_http_client).to receive(:put).with('/admin/api/services/100/proxy/policies', anything).and_return({})

    ##
    # External http client stub
    allow(external_http_client).to receive(:post).with('/admin/api/services', anything)
                                                 .and_return(service_attr)
    expect(external_http_client).to receive(:get).with('/admin/api/services')
                                                 .and_return(existing_services)
    allow(external_http_client).to receive(:get).with('/admin/api/services/100/metrics')
                                                .and_return(metrics)
    allow(external_http_client).to receive(:get).with('/admin/api/services/100/metrics/1/methods')
                                                .and_return(external_methods)
    allow(external_http_client).to receive(:get).with('/admin/api/services/100/proxy/mapping_rules')
                                                .and_return(external_mapping_rules)
    allow(external_http_client).to receive(:get).with('/admin/api/active_docs')
                                                .and_return(external_activedocs)
    allow(external_http_client).to receive(:get).with('/admin/api/services/100/proxy')
                                                .and_return(external_proxy)
    allow(external_http_client).to receive(:get).with('/admin/api/services/100')
                                                .and_return(service_attr)
  end
end

RSpec.shared_examples 'oas imported' do
  let(:expected_methods) do
    [
      { 'friendly_name' => 'addPet', 'system_name' => 'addpet' },
      { 'friendly_name' => 'updatePet', 'system_name' => 'updatepet' },
      { 'friendly_name' => 'findPetsByStatus', 'system_name' => 'findpetsbystatus' }
    ]
  end
  let(:method_keys) { %w[friendly_name system_name] }
  let(:expected_mapping_rules) do
    [
      { 'pattern' => '/v2/pet$', 'http_method' => 'POST', 'delta' => 1 },
      { 'pattern' => '/v2/pet$', 'http_method' => 'PUT', 'delta' => 1 },
      { 'pattern' => '/v2/pet/findByStatus$', 'http_method' => 'GET', 'delta' => 1 }
    ]
  end
  let(:expected_api_backend) { 'https://petstore.swagger.io:443' }
  let(:expected_credentials_location) { 'headers' }
  let(:expected_auth_user_key) { 'api_key' }
  let(:mapping_rule_keys) { %w[pattern http_method delta] }

  it 'methods are created' do
    expect { subject }.to output.to_stdout
    expect(subject).to eq(0)
    expect(expected_methods.size).to be > 0
    # test Set(service.methods) includes Set(expected_methods)
    # with a custom identity method for methods
    expect(expected_methods).to be_subset_of(service.methods).comparing_keys(method_keys)
  end

  it 'mapping rules are created' do
    expect { subject }.to output.to_stdout
    expect(subject).to eq(0)
    expect(expected_mapping_rules.size).to be > 0
    # expect Set(service.mapping_rules) == Set(expected_mapping_rules)
    # with a custom identity method for mapping_rules
    expect(expected_mapping_rules).to be_subset_of(service.mapping_rules).comparing_keys(mapping_rule_keys)
    expect(service.mapping_rules).to be_subset_of(expected_mapping_rules).comparing_keys(mapping_rule_keys)
  end

  it 'activedocs are created' do
    expect { subject }.to output.to_stdout
    expect(subject).to eq(0)
    expect(service_active_docs.size).to eq(1)
    expect(service_active_docs[0]['name']).to eq('Swagger Petstore')
    expect(service_active_docs[0]['body']).to eq(oas_resource_json)
  end

  it 'service proxy is updated' do
    expect { subject }.to output.to_stdout
    expect(subject).to eq(0)
    expect(service_proxy).not_to be_nil
    expect(service_proxy).to include('api_backend' => expected_api_backend,
                                     'credentials_location' => expected_credentials_location,
                                     'auth_user_key' => expected_auth_user_key)
  end
end

RSpec.shared_context :import_oas_real_cleanup do
  after :example do
    service.list_activedocs.each do |activedoc|
      service.remote.delete_activedocs(activedoc['id'])
    end
    service.delete_service
  end
end

RSpec.describe 'e2e OpenAPI import' do
  include_context :resources
  include_context :random_name
  if ENV.key?('ENDPOINT')
    include_context :real_api3scale_client
    include_context :import_oas_real_cleanup
  else
    include_context :import_oas_stubbed_api3scale_client
  end

  # render from template to avoid system_name collision
  let(:system_name) { "test_openapi_#{random_lowercase_name}" }
  let(:destination_url) do
    endpoint_uri = URI(endpoint)
    endpoint_uri.user = provider_key
    endpoint_uri.to_s
  end
  let(:oas_resource_path) { File.join(resources_path, 'petstore.yaml') }
  let(:oas_resource_json) { JSON.pretty_generate(YAML.safe_load(File.read(oas_resource_path))) }
  let(:command_line_str) { "import openapi -t #{system_name} -d #{destination_url} #{oas_resource_path}" }
  subject { ThreeScaleToolbox::CLI.run(command_line_str.split) }
  let(:service_id) do
    # figure out service by system_name
    api3scale_client.list_services.find { |service| service['system_name'] == system_name }['id']
  end
  let(:service) do
    ThreeScaleToolbox::Entities::Service.new(id: service_id, remote: api3scale_client)
  end
  let(:service_active_docs) { service.list_activedocs }
  let(:service_proxy) { service.show_proxy }

  context 'when target service exists' do
    before :example do
      ThreeScaleToolbox::Entities::Service.create(
        remote: api3scale_client, service: { 'name' => system_name }, system_name: system_name
      )
    end

    it_behaves_like 'oas imported'
  end

  context 'when target service does not exist' do
    it_behaves_like 'oas imported'
  end

  context 'import oidc service' do
    let(:oas_resource_path) { File.join(resources_path, 'oidc.yaml') }
    let(:backend_version) { 'oidc' }
    let(:issuer_endpoint) { 'https://issuer.com' }
    let(:service_settings) { service.show_service }
    let(:credentials_location) { 'headers' }
    let(:command_line_str) do
      "import openapi -t #{system_name} --oidc-issuer-endpoint=#{issuer_endpoint} " \
      " -d #{destination_url} #{oas_resource_path}"
    end

    it 'service oidc settings are updated' do
      expect { subject }.to output.to_stdout
      expect(subject).to eq(0)
      expect(service_settings).not_to be_nil
      expect(service_settings).to include('backend_version' => backend_version)
      expect(service_proxy).not_to be_nil
      expect(service_proxy).to include('oidc_issuer_endpoint' => issuer_endpoint,
                                       'credentials_location' => credentials_location)
    end
  end
end