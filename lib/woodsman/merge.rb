require 'active_support/all'
module Woodsman
  # TODO: allow this to take a block or proc param so customize merge behavior, a la merge.
  # NOTE: we assume both values for any given key at any matching level are of the same type
  # TODO: raise if not?
  def self.merge_hash(h1, h2)
    return (h1 || h2 || {}) unless h1 && h2
    h1.merge(h2) do |k, v1, v2|
      v3 = merge_hash(v1, v2) if v1.kind_of?(Hash)
      v3 ||= merge_array(v1, v2) if v1.kind_of?(Array)
      v3 ||= v2 || v1
      v3
    end
  end

  def self.merge_array(a1, a2)
    return (a1 || a2) unless a1 && a2
    # Assume array is the same type
    # TODO: handle mismatched array lengths? probably iterate through the longer?
    is_holding_hashes = a1[0].kind_of?(Hash) if a1.count > 0
    if is_holding_hashes
      merged = a1
      a1.each_with_index do |v, idx|
        v2 = a2[idx]
        merged[idx] = merge_hash(v, v2)
      end
    else
      merged = a1 + a2
    end
    merged
  end

  # TODO: optimize
  # TODO: allow this to take a block or proc param so customize split behavior, a la merge.
  # TODO: hmm, should we not do the indifferent access for callers by default...? makes it easier to deal with though...
  def self.split_hash(h, split_map)
    return [nil, h] if h.nil?

    split = {}.with_indifferent_access
    leftover = h.dup.with_indifferent_access

    h.each do |k, v|
      k = k.to_sym
      # go through all keys at this level, recurse split_hash on each
      if split_map.key?(k)
        if v.kind_of?(Hash)
          # Recurse hash values
          split[k], leftover[k] = split_hash(v, split_map[k])
        elsif v.kind_of?(Array)
          # Iterate through array values
          split[k], leftover[k] = v.map { |item| split_hash(item, split_map[k][0]) }.transpose
        else
          # Take all other values
          split[k] = leftover.delete(k)
        end
      end
    end

    split = nil if split.empty?
    leftover = nil if leftover.empty?
    [split, leftover]
  end
end