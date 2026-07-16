# frozen_string_literal: true

module Stats
  def self.median(values)
    return nil if values.empty?

    sorted = values.sort
    mid = sorted.length / 2
    sorted.length.odd? ? sorted[mid].to_f : (sorted[mid - 1] + sorted[mid]) / 2.0
  end

  def self.mean(values)
    return nil if values.empty?

    values.sum.to_f / values.length
  end
end
