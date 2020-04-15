class UpdateSpreadsheetJob < ApplicationJob
  queue_as :default

  def perform(report, *args)
    return if report.nil?

    row = report.to_line
    first_column = Sheets.get.map { |s| s[0] }
    line = first_column.index(row[0])
    line = first_column.count if line.nil?
    line += 1
    Sheets.write("A#{line}:Z#{line}", [row])
  end
end
