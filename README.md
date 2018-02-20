# Terraform-plan

This is a ruby library to parse output of `terraform plan` into ruby hash.
You might need it for running specs and use together with `ruby_terraform` gem.

Note: you might better test real result rather than plan. In that case you don't need this library, use just `ruby_terraform` for that.

Status: experimental.
This was a hack day project and coding style is very much suboptimal.

References to the similar libraries of better quality are welcome.

Pull requests and bug reports are welcome too.

### Example

```
require 'ruby_terraform'
require 'terraform_plan'

describe 'module VM' do
  context 'using simple config' do
    before(:all) do
      RubyTerraform.get(directory: 'spec/testing')
      output = RubyTerraform.plan(directory: 'spec/testing',
                                  var_file: 'spec/testing/terraform.tfvars',
                                  no_color: true)
      @plan = TerraformPlan.process_output(output)
    end

    let(:plan) do
      @plan
    end

    let(:disk_names) { plan.disk_names_for('+ module.VM.vsphere_virtual_machine.vm') }

    it 'creates VM' do
      expect(plan).to have_key '+ module.VM.vsphere_virtual_machine.vm'
    end

    it 'processes server_prefix required param' do
      expect(disk_names).to include 'foobar-prefix-01-disk1'
    end

    # ......... add more specs here ..........
    # ....
    # Check the source code for additional helpers
    # ...
    # ........................................

    after(:all) do
      RubyTerraform.destroy(directory: 'spec/testing',
                            var_file: 'spec/testing/terraform.tfvars',
                            force: true)
      RubyTerraform.clean(base_directory: 'spec/testing')
    end
  end
end
```

### Example without using this library

```
require 'ruby_terraform'
require 'resolv'
require 'net/ping'

describe 'module VM' do
  context 'testing real work on vSphere cluster' do
    before(:all) do
      RubyTerraform.get(directory: 'spec/testing')
      RubyTerraform.plan(directory: 'spec/testing',
                         var_file: 'spec/testing/terraform.tfvars',
                         no_color: true)
      RubyTerraform.apply(directory: 'spec/testing',
                          var_file: 'spec/testing/terraform.tfvars')
    end

    let(:dns_name_string) { RubyTerraform.output(name: 'dns_name') }
    let(:ip_string) { RubyTerraform.output(name: 'ip') }
    let(:dns_names) { dns_name_string.split(",\n").map { |s| s.chomp('.') }}
    let(:ips) { ip_string.split(",\n") }

    it 'produces DNS name of the server' do
      expect(dns_names).not_to be_empty
      expect(dns_names).to eql %w(foobar-prefix-01.example.org)
    end

    it 'produces IP addresses of the server' do
      expect(ips).not_to be_empty
    end

    it 'creates DNS names that resolve into IPs' do
      dns_names.each_with_index do |dns, index|
        expect(Resolv.getaddress(dns)).to eql ips[index]
      end
    end

    it 'creates reverse DNS names that resolve into forward DNS' do
      ips.each_with_index do |ip, index|
        expect(Resolv.getname(ip)).to eql dns_names[index]
      end
    end

    it 'produces pingable hosts' do
      dns_names.each do |dns|
        expect(Net::Ping::External.new(dns).ping?).to be true
      end
    end

    after(:all) do
      RubyTerraform.destroy(directory: 'spec/testing',
                            var_file: 'spec/testing/terraform.tfvars',
                            force: true)
      RubyTerraform.clean(base_directory: 'spec/testing')
    end
  end
end
```

### License and authors

* License:: MIT
* Author:: Timur Batyrshin <erthad@gmail.com>
