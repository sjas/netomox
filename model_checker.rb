require 'json'
require 'optparse'
require_relative 'model_checker/topo_networks_diff'
require_relative 'model_checker/graph_networks_ops'

opt = OptionParser.new
option = {}
opt.on('-c', '--check', 'Run model check') do |v|
  option[:check] = v
end
opt.on('-n', '--neo4j', 'Add data to neo4j') do |v|
  option[:neo4j] = v
end
opt.on('-v', '--verbose', 'Verbose output (dump data)') do |v|
  option[:verbose] = v
end
opt.on('-d', '--diff', 'Diff between models') do |v|
  option[:diff] = v
end
opt.banner += ' FILE [FILE]'
opt.parse!(ARGV)

def help_and_exit(opt)
  warn opt.help
  exit 1
end

## read file
data = nil
if ARGV.empty?
  help_and_exit opt
else
  data = JSON.parse(File.read(ARGV[0]))
end

if option[:verbose]
  puts "# Target File: #{ARGV[0]}"
  puts JSON.pretty_generate(data)
end

if option[:check]
  networks = TopoChecker::Networks.new(data)
  puts '# check all supporting networks'
  networks.check_all_supporting_networks
  puts '# check all supporting nodes'
  networks.check_all_supporting_nodes
  puts '# check all supporting termination points'
  networks.check_all_supporting_tps
  puts '# check all supporting links'
  networks.check_all_supporting_links
  puts '# check all link pair'
  networks.check_all_link_pair
  puts '# check uniqueness'
  networks.check_object_uniqueness
  puts '# check terminal point reference count'
  networks.check_tp_ref_count
end

if option[:neo4j]
  db_info = JSON.parse(File.read('./db_info.json'), symbolize_names: true)
  networks = TopoChecker::GraphNetworks.new(data, db_info)
  if option[:verbose]
    puts '# node objects'
    puts JSON.pretty_generate(networks.node_objects)
    puts '# relationship objects'
    puts JSON.pretty_generate(networks.relationship_objects)
    puts '# DB info'
    puts db_info
    exit(0)
  end
  puts '# clear all nodes'
  networks.exec_clear_all_objects
  puts '# create nodes/relationships'
  networks.exec_create_objects
end

if option[:diff]
  data2 = nil
  if ARGV.length != 2
    help_and_exit opt
  else
    data2 = JSON.parse(File.read(ARGV[1]))
  end
  if option[:verbose]
    puts "# Target File: #{ARGV[1]}"
    puts JSON.pretty_generate(data2)
  end

  nws1 = TopoChecker::Networks.new(data)
  nws2 = TopoChecker::Networks.new(data2)
  d_nws = nws1.diff(nws2)

  # test
  p '- networks'
  d_nws.networks.each do |nw|
    p "  - #{nw.name}, #{nw.diff_state}"
    nw.nodes.each do |node|
      p "    - #{node}, #{node.diff_state}"
      node.termination_points.each do |tp|
        p "      - #{tp}, #{tp.diff_state}"
      end
    end
    nw.links.each do |link|
      p "    - #{link}, #{link.diff_state}"
      %i[source destination].each do |d|
        p "      - #{d}, #{link.send(d).diff_state}"
      end
    end
  end
end
