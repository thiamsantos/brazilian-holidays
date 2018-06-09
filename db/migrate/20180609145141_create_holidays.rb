class CreateHolidays < ActiveRecord::Migration[5.2]
  def change
    create_table :holidays do |t|
      t.string :name, null: false
      t.date :occurs_at, null: false
    end

    add_index(:holidays, [:occurs_at], unique: true)
  end
end
