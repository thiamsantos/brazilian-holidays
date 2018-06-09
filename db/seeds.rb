require 'roo-xls'
require_relative '../app/models/holiday'

path = File.join(File.dirname(__FILE__), './holidays.xls')
document = Roo::Spreadsheet.open(path, extension: :xls)

Holiday.transaction do
  document
    .sheet(document.default_sheet)
    .parse(occurs_at: 'Data', name: 'Feriado')
    .select { |holiday| holiday[:occurs_at].is_a?(Date) }
    .each { |holiday| Holiday.create(holiday) }
end
