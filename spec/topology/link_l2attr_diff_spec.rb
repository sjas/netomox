RSpec.describe 'link diff with L2 attribute', :diff, :link, :attr, :l2attr do
  before do
    l2nw_type = { Netomox::DSL::NWTYPE_L2 => {} }
    link_attr = { name: 'linkX', flags: [], rate: 1000, delay: 10, srlg: '' }
    link_attr_changed = { name: 'linkX', flags: [], rate: 1000, delay: 20, srlg: '' }

    link_spec = %w[link1 tp1 link2 tp2]
    link_l2attr0_def = Netomox::DSL::Link.new(*link_spec, l2nw_type)
    link_l2attr_def = Netomox::DSL::Link.new(*link_spec, l2nw_type) do
      attribute(link_attr)
    end
    link_l2attr_changed_def = Netomox::DSL::Link.new(*link_spec, l2nw_type) do
      attribute(link_attr_changed)
    end

    @link_l2attr0 = Netomox::Topology::Link.new(link_l2attr0_def.topo_data, '')
    @link_l2attr = Netomox::Topology::Link.new(link_l2attr_def.topo_data, '')
    @link_l2attr_changed = Netomox::Topology::Link.new(link_l2attr_changed_def.topo_data, '')
  end

  it 'kept link L2 attributes' do
    d_link = @link_l2attr.diff(@link_l2attr.dup)
    expect(d_link.diff_state.detect).to eq :kept
    expect(d_link.attribute.diff_state.detect).to eq :kept
  end

  context 'diff with no-attribute link' do
    it 'added whole L2 attribute' do
      d_link = @link_l2attr0.diff(@link_l2attr)
      expect(d_link.diff_state.detect).to eq :changed
      expect(d_link.attribute.diff_state.detect).to eq :added
    end

    it 'deleted whole L2 attribute' do
      d_link = @link_l2attr.diff(@link_l2attr0)
      expect(d_link.diff_state.detect).to eq :changed
      expect(d_link.attribute.diff_state.detect).to eq :deleted
    end
  end

  it 'changed link L2 attributes' do
    d_link = @link_l2attr.diff(@link_l2attr_changed)
    expect(d_link.diff_state.detect).to eq :changed
    expect(d_link.attribute.diff_state.detect).to eq :changed
  end
end