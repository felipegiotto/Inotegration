class CreateAnalises < ActiveRecord::Migration
  def self.up
    create_table :analises do |t|
      t.integer :projeto_id
      t.text :texto
      t.string :dados_do_commit
      t.timestamps
    end
  end

  def self.down
    drop_table :analises
  end
end
