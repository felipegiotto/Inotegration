class CreateProjects < ActiveRecord::Migration
  def self.up
    create_table :projects do |t|
      t.string :nome
      t.string :folder_name
      
      t.timestamps
    end
  end

  def self.down
    drop_table :projects
  end
end
