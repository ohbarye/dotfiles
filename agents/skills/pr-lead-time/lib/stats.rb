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

  # 線形補間によるパーセンタイル（p は 0.0〜1.0）。
  def self.percentile(values, p)
    return nil if values.empty?

    sorted = values.sort
    rank = (sorted.length - 1) * p
    lower = rank.floor
    upper = [lower + 1, sorted.length - 1].min
    sorted[lower] + (sorted[upper] - sorted[lower]) * (rank - lower)
  end

  # threshold 以下の値の割合（0.0〜1.0）。
  def self.share_within(values, threshold)
    return nil if values.empty?

    values.count { |v| v <= threshold }.to_f / values.length
  end
end
