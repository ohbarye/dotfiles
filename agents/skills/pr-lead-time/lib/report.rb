# frozen_string_literal: true

require "json"

# Renders aggregated lead-time rows (see Aggregator.build) as Markdown or JSON.
module Report
  def self.to_markdown(rows, granularity:, excluded: {})
    label = granularity == :weekly ? "週(月曜起点)" : "月"
    header = "| #{label} | ①中央値(h) | ①平均(h) | ①N | ②中央値(h) | ②平均(h) | ②N | 計中央値(h) | 計平均(h) | 計N |\n"
    sep = "|---|---|---|---|---|---|---|---|---|---|\n"
    body = rows.map { |row| markdown_row(row) }.join("\n")
    distribution = markdown_distribution(rows, label)
    notes = markdown_notes(excluded)
    "#{header}#{sep}#{body}\n\n#{distribution}\n#{notes}"
  end

  def self.to_json(rows, excluded: {})
    JSON.pretty_generate(rows: rows, excluded: excluded)
  end

  def self.markdown_row(row)
    cells = [row[:bucket]]
    %i[stage1 stage2 stage3].each do |stage|
      cells << fmt(row[stage][:median]) << fmt(row[stage][:mean]) << row[stage][:n]
    end
    "| #{cells.join(" | ")} |"
  end
  private_class_method :markdown_row

  # 中央値は二山分布で月ごとに大きく跳ねるため、平均（上表）に加えて分布の裾と
  # 「6h以内に完了した割合」を別表で示す。
  def self.markdown_distribution(rows, label)
    heads = %w[① ② 計].flat_map { |s| ["#{s}p75(h)", "#{s}p90(h)", "#{s}6h以内(%)"] }
    header = "| #{label} | #{heads.join(" | ")} |\n"
    sep = "|---|---|---|---|---|---|---|---|---|---|\n"
    body = rows.map do |row|
      cells = [row[:bucket]]
      %i[stage1 stage2 stage3].each do |stage|
        cells << fmt(row[stage][:p75]) << fmt(row[stage][:p90]) << fmt_percent(row[stage][:within_6h])
      end
      "| #{cells.join(" | ")} |"
    end.join("\n")
    "#{header}#{sep}#{body}\n"
  end
  private_class_method :markdown_distribution

  def self.markdown_notes(excluded)
    return "" if excluded.values.all? { |v| v.to_i.zero? }

    "\n注: 集計から除外された件数 — bot作成PR: #{excluded[:bot_authored] || 0}件, " \
      "デプロイ未到達(まだmainに未反映): #{excluded[:not_deployed] || 0}件, " \
      "ancestry判定不能: #{excluded[:ancestry_unresolved] || 0}件\n"
  end
  private_class_method :markdown_notes

  def self.fmt_percent(ratio)
    ratio.nil? ? "-" : format("%.0f", ratio * 100)
  end
  private_class_method :fmt_percent

  def self.fmt(value)
    value.nil? ? "-" : format("%.1f", value)
  end
  private_class_method :fmt
end
