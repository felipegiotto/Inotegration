class Flay
  def report_string prune = nil
    out = ""
    out += "Total score (smaller is better) = #{self.total}\n"

    count = 0
    masses.sort_by { |h,m| [-m, hashes[h].first.file] }.each do |hash, mass|
      nodes = hashes[hash]
      next unless nodes.first.first == prune if prune
      out += "\n"

      same = identical[hash]
      node = nodes.first
      n = nodes.size
      match, bonus = if same then
                       ["IDENTICAL", "*#{n}"]
                     else
                       ["Similar",   ""]
                     end

      count += 1
      out += "%d) %s code found in %p (score %s = %d)\n" %
        [count, match, node.first, bonus, mass]

      nodes.each_with_index do |node, i|
        if option[:verbose] then
          c = (?A + i).chr
          out += "  #{c}: #{node.file}:#{node.line}\n"
        else
          out += "  #{node.file}:#{node.line}\n"
        end
      end

      if option[:verbose] then
        out += "\m"
        r2r = Ruby2Ruby.new
        out += n_way_diff(*nodes.map { |s| r2r.process(s.deep_clone) })
        out += "\n"
      end
    end
    out
  end
end
