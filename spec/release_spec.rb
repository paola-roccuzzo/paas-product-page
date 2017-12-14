require 'open3'

describe "generating a manifest" do
  let(:dir) { Pathname(File.absolute_path(__dir__) + '/..') }
  let(:manifest_template) { dir.join('manifest.yml').read }

  let(:new_manifest) {
    cmd = dir.join('release', 'generate-manifest')

    stdout, stderr, status = Open3.capture3(
      {
        'DESKPRO_API_KEY' => 'my-great-deskpro-api-key',
        'CF_API' => 'https://api.foo.bar.baz',
      },
      cmd.to_s,
      stdin_data: manifest_template
    )

    expect(stderr).to be_empty
    YAML.load(stdout)
  }

  it "adds a www.SYSTEM_DOMAIN route" do
    expect(new_manifest['applications'][0]['routes']).
      to include({ 'route' => 'www.foo.bar.baz' })
  end

  it "adds the cloudapps.digital route" do
    expect(new_manifest['applications'][0]['routes']).
      to include({ 'route' => 'paas-product-page.cloudapps.digital' })
  end

  it "sets the DeskPro API key" do
    expect(new_manifest['applications'][0]['env']['DESKPRO_API_KEY']).
      to eq('my-great-deskpro-api-key')
  end

  it "preserves the existing env" do
    expect(new_manifest['applications'][0]['env']['DESKPRO_TEAM_ID']).
      to eq('1')
  end
end
