# Terraform-plan

This is a ruby library to parse output of `terraform plan` into ruby hash.
You might need it for running specs and use together with `ruby_terraform` gem.

Status: experimental.

Pull requests and bug reports are welcome.

### Example

```
require 'ruby_terraform'
require 'terraform_plan'

describe 'module m1' do
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

    it 'creates VM' do
      expect(plan).to have_key '+ module.m1.vsphere_virtual_machine.vm'
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
