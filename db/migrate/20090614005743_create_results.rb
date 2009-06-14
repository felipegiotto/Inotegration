class CreateResults < ActiveRecord::Migration
  def self.up
    create_table :results do |t|
      t.integer :analysis_id
      t.string :nome
      t.text :texto
      t.integer :tempo
      t.integer :situation

      t.timestamps
    end
  end

  def self.down
    drop_table :results
  end
end
