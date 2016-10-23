# Software patch-panel.
class PatchPanel < Trema::Controller
  def start(_args)
    @patch = Hash.new { [] }
    @mirror = Hash.new { [] } #ミラーリング用のハッシュ
    logger.info 'PatchPanel started.'
  end

  def switch_ready(dpid)
    @patch[dpid].each do |port_a, port_b|
      delete_flow_entries dpid, port_a, port_b
      add_flow_entries dpid, port_a, port_b
    end
  end

  def create_patch(dpid, port_a, port_b)
    add_flow_entries dpid, port_a, port_b
    @patch[dpid] += [port_a, port_b].sort
  end

  def delete_patch(dpid, port_a, port_b)
    delete_flow_entries dpid, port_a, port_b
    @patch[dpid] -= [port_a, port_b].sort
  end

#ミラーリングの処理
  def mirror_patch(dpid, port_a, port_b)
    add_mirror_flow_entrie dpid, port_a, port_b
    @mirror[dpid] += [port_a, port_b] #ミラーリングは双方向ではないので、sortはしない
  end

#パッチとミラーリングの表示の処理
  def show_list(dpid)
    @patch[dpid].each do |port_a, port_b|
      puts "port_#{port_a} and port_#{port_b} is patched."
    end
    @mirror[dpid].each do |port_a, port_b|
      puts "port_#{port_a} and port#{port_b} is mirrored."
    end
  end

  private

  def add_flow_entries(dpid, port_a, port_b)
    send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_a),
                      actions: SendOutPort.new(port_b))
    send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_b),
                      actions: SendOutPort.new(port_a))
  end

  def delete_flow_entries(dpid, port_a, port_b)
    send_flow_mod_delete(dpid, match: Match.new(in_port: port_a))
    send_flow_mod_delete(dpid, match: Match.new(in_port: port_b))
  end

#ミラーリング用のprivateメソッド
  def add_mirror_flow_entrie(dpid, port_a, port_b)
    send_flow_mod_add(dpid,
                      match: Match.new(in_port: port_a),
                      actions: SendOutPort.new(port_b))
  end
end
