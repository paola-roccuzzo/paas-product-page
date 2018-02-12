require 'open3'

describe "generating a manifest" do
  let(:dir) { Pathname(File.absolute_path(__dir__) + '/..') }
  let(:manifest_template) { dir.join('manifest.yml').read }

  let(:new_manifest) {
    cmd = dir.join('release', 'generate-manifest')

    stdout, stderr, = Open3.capture3(
      {
        'DESKPRO_API_KEY' => 'my-great-deskpro-api-key',
        'CF_API' => 'https://api.foo.bar.baz',
      },
      cmd.to_s,
      stdin_data: manifest_template
    )

    expect(stderr).to be_empty
    YAML.safe_load(stdout)
  }

  it "adds a www.SYSTEM_DOMAIN route" do
    expect(new_manifest['applications'][0]['routes']).
      to include('route' => 'www.foo.bar.baz')
  end

  it "sets the DeskPro API key" do
    expect(new_manifest['applications'][0]['env']['DESKPRO_API_KEY']).
      to eq('my-great-deskpro-api-key')
  end

  it "preserves the existing env" do
    expect(new_manifest['applications'][0]['env']['DESKPRO_TEAM_ID']).
      to eq('1')
  end

  let(:redirect_manifest_template) { dir.join('redirect/manifest.yml').read }

  describe "the redirect app" do
    let(:new_redirect_manifest) {
      cmd = dir.join('release', 'generate-redirect-manifest')

      stdout, stderr, = Open3.capture3(
        {
          'CF_API' => 'https://api.foo.bar.baz',
          'CF_APPS_DOMAIN' => 'apps.foo.bar.baz',
          'CF_APP_NAME' => 'paas-product-page',
        },
        cmd.to_s,
        stdin_data: redirect_manifest_template
      )

      expect(stderr).to be_empty
      YAML.safe_load(stdout)
    }

    it "redirects the app's name on the app domain to www on the system domain" do
      expect(new_redirect_manifest['applications'][0]['routes']).
        to include('route' => 'paas-product-page.apps.foo.bar.baz')
    end

    it "redirects the bare apex system domain to www on the system domain" do
      expect(new_redirect_manifest['applications'][0]['routes']).
        to include('route' => 'foo.bar.baz')
    end

    it "sets the REDIRECT_DOMAIN environment variable" do
      expect(new_redirect_manifest['applications'][0]['env']).
        to include('REDIRECT_DOMAIN' => 'www.foo.bar.baz')
    end
  end
end
