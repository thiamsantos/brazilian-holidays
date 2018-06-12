require 'roo-xls'
require_relative '../app/holidays'

path = File.join(File.dirname(__FILE__), './holidays.xls')
document = Roo::Spreadsheet.open(path, extension: :xls)

Holidays::Holiday.transaction do
  document
    .sheet(document.default_sheet)
    .parse(occurs_at: 'Data', name: 'Feriado')
    .select { |holiday| holiday[:occurs_at].is_a?(Date) }
    .each { |holiday| Holidays::Holiday.create(holiday) }
end
