class CreateJobs < ActiveRecord::Migration
  def change
    create_table :jobs do |t|
      t.integer :checked_out_by_user_id
      t.string :checked_out_by_user_type
      t.datetime :checked_out_at
      t.string :name

      t.timestamps
    end
  end
end
