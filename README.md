# Terraform-plan

This is a ruby library to parse output of `terraform plan` into ruby hash.
You might need it for running specs and use together with `ruby_terraform` gem.

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

### License and authors

* License:: MIT
* Author:: Timur Batyrshin <erthad@gmail.com>
