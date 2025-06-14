class AddEspnIdAndConferenceToTeams < ActiveRecord::Migration[7.1]
  def change
    add_column :teams, :espn_id, :integer
    add_column :teams, :conference, :string
  end
end
