require 'yaml'

class TerraformPlan
  class << self
    ### Color output is not supported!
    def process_output(lines)
      lines = lines.split("\n")
      lines = strip_banners(lines)

      result = {}
      current_resource = nil

      lines.each do |line|
        case line
        # resource is added/removed
        when /^(\+|-)/
          current_resource = line
          result[current_resource] = {}

        # parameter inside a resource
        when /^\s+/
          k, v = line.split(':').map(&:strip)
          result[current_resource][k] = strip_quotes(v)

        # empty line or something unexpected
        else
          # protect processed results by polluting from garbage
          current_resource = nil
        end
      end
      new result
    end

    private

    def strip_banners(lines)
      # Plan got without '-out' parameter
      start = lines.index { |s| s.match("Note: You didn't specify an \"-out\" parameter to save this plan, so when") }
      # Plan got with '-out' parameter
      start ||= lines.index { |s| s.match("Your plan was also saved to the path below. Call the \"apply\" subcommand") }

      result = lines.drop(start)
      result = result.drop_while { |s| !s.empty? }
      result.drop_while { |s| s.match(/^(Path:|)$/) }
    end

    def strip_quotes(str)
      if str.start_with?('"') && str.end_with?('"')
        str[1..-2]
      else
        str
      end
    end
  end

  attr_reader :plan

  def initialize(resources)
    @plan = resources
  end

  def eql?(other)
    other.class == self.class && other.plan == @plan
  end

  def method_missing(method_sym, *arguments, &block)
    plan.send(method_sym, *arguments, &block)
  end

  def respond_to?(method_sym, include_private = false)
    if plan.respond_to?(method_sym, include_private)
      true
    else
      super
    end
  end

  def plan_for(vm)
    plan[vm] || []
  end

  def disk_ids_for(vm)
    plan_for(vm).keys.map { |key| id_from_label_disk_name(key) }.compact
  end

  def disk_names_for(vm)
    disk_labels_for(vm, 'name')
  end

  def disk_datastores_for(vm)
    disk_labels_for(vm, 'datastore')
  end

  def disk_templates_for(vm)
    disk_labels_for(vm, 'template')
  end

  def disk_sizes_for(vm)
    disk_labels_for(vm, 'size')
  end

  def disk_labels_for(vm, label)
    labels = plan_for(vm).keys.select { |key| label_disk?(key, label) }
    plan_for(vm).values_at(*labels)
  end

  ### FIXME: write tests
  def records_for(vm)
    labels = plan_for(vm).keys.select { |key| label_record?(key) }
    labels.reject! {|x| x == 'records.#' }
    plan_for(vm).values_at(*labels).map { |s| unescape(s) }
  end

  def vm_created?(name)
    plan.keys.find { |resource|
      resource.match("\\+ module\\.(.*\\.)?#{name}\\.vsphere_virtual_machine\\.vm")
    }
  end

  private

  def unescape(s)
    YAML.load(%Q(---\n"#{s}"\n))
  end

  def label_disk?(id, label)
    id.match(/disk\.(.*)\.#{label}/)
  end

  def label_disk_name?(id)
    id.match(/disk\.(.*)\.name/)
  end

  def label_disk_datastore?(id)
    id.match(/disk\.(.*)\.datastore/)
  end

  def label_disk_template?(id)
    id.match(/disk\.(.*)\.template/)
  end

  def label_record?(id)
    id.match(/records\.(.*)/)
  end

  def id_from_label_disk_name(label)
    disk_id = label_disk_name?(label)
    disk_id[1] if disk_id
  end
end
