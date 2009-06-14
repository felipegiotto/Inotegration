class CreateAnalyses < ActiveRecord::Migration
  def self.up
    create_table :analyses do |t|
      t.integer :project_id
      t.text :texto
      t.string :dados_do_commit
      t.boolean :finished
      t.timestamps
    end
  end

  def self.down
    drop_table :analyses
  end
end
