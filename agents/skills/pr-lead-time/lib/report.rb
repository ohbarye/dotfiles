# frozen_string_literal: true

require "json"

# Renders aggregated lead-time rows (see Aggregator.build) as Markdown or JSON.
module Report
  def self.to_markdown(rows, granularity:, excluded: {})
    label = granularity == :weekly ? "週(月曜起点)" : "月"
    header = "| #{label} | ①中央値(h) | ①平均(h) | ①N | ②中央値(h) | ②平均(h) | ②N | 計中央値(h) | 計平均(h) | 計N |\n"
    sep = "|---|---|---|---|---|---|---|---|---|---|\n"
    body = rows.map { |row| markdown_row(row) }.join("\n")
    notes = markdown_notes(excluded)
    "#{header}#{sep}#{body}\n#{notes}"
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

  def self.markdown_notes(excluded)
    return "" if excluded.values.all? { |v| v.to_i.zero? }

    "\n注: 集計から除外された件数 — bot作成PR: #{excluded[:bot_authored] || 0}件, " \
      "デプロイ未到達(まだmainに未反映): #{excluded[:not_deployed] || 0}件, " \
      "ancestry判定不能: #{excluded[:ancestry_unresolved] || 0}件\n"
  end
  private_class_method :markdown_notes

  def self.fmt(value)
    value.nil? ? "-" : format("%.1f", value)
  end
  private_class_method :fmt
end
