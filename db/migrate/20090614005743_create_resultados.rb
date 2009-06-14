class CreateResultados < ActiveRecord::Migration
  def self.up
    create_table :resultados do |t|
      t.integer :analise_id
      t.string :nome
      t.text :texto
      t.integer :tempo
      t.integer :situation

      t.timestamps
    end
  end

  def self.down
    drop_table :resultados
  end
end
