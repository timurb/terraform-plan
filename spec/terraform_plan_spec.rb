require 'spec_helper'
require 'terraform_plan'

describe TerraformPlan do
  let(:plan) { TerraformPlan.process_output(FIXTURE) }
  let(:disk_ids) { plan.disk_ids_for(VM_NAME) }
  let(:disk_names) { plan.disk_names_for(VM_NAME) }
  let(:disk_datastores) { plan.disk_datastores_for(VM_NAME) }
  let(:disk_templates) { plan.disk_templates_for(VM_NAME) }
  let(:disk_sizes) { plan.disk_sizes_for(VM_NAME) }
  let(:records) { plan.record_ids_for('PowerDNS reverse record') }

  subject { plan }

  it 'processes output of terraform plan command' do
    expect(plan).not_to be_nil
  end

  it { is_expected.to respond_to :'[]' }

  it 'produces correct output' do
    expect(plan.plan).to eql OUTPUT
  end

  it 'produces list of disk ids' do
    expect(disk_ids).to eql ['3549496356', '769064163']
  end

  it 'produces list of disk names' do
    expect(disk_names).to eql ['foobar-01-disk1', '']
  end

  it 'produces list of disk datastores' do
    expect(disk_datastores).to eql ['Datastore1 of the image',
                                    'Datastore2 of the image']
  end

  it 'produces list of disk templates' do
    expect(disk_templates).to eql ['', 'Template name']
  end

  it 'produces list of disk sizes' do
    expect(disk_sizes).to eql ['50', '']
  end

  context 'check for presence of specified VM in the plan' do
    it 'matches single VM' do
      expect( plan.vm_created?('m1') ).to be_truthy
    end

    it 'matches multiple VMs' do
      pending('Update fixture')
      expect( plan.vm_created?('bar') ).to be_truthy
    end

    it 'doesn''t match nonexistant VMs' do
      expect( plan.vm_created?('boom') ).to be_falsey
    end
  end

  it 'produces list of DNS reverse records' do
    pending('Update fixture')
    expect(records).to eql ['foobar_prefix-01.foobar_domain.']
  end
end
