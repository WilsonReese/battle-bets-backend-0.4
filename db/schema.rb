# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2025_05_09_224933) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "battles", force: :cascade do |t|
    t.datetime "start_date"
    t.datetime "end_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "locked", default: false, null: false
    t.bigint "league_season_id", null: false
    t.index ["league_season_id"], name: "index_battles_on_league_season_id"
  end

  create_table "bet_options", force: :cascade do |t|
    t.string "title"
    t.decimal "payout"
    t.string "category"
    t.bigint "game_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "success"
    t.string "long_title"
    t.index ["game_id"], name: "index_bet_options_on_game_id"
  end

  create_table "bets", force: :cascade do |t|
    t.bigint "betslip_id", null: false
    t.bigint "bet_option_id", null: false
    t.decimal "bet_amount"
    t.decimal "to_win_amount"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "amount_won"
    t.index ["bet_option_id"], name: "index_bets_on_bet_option_id"
    t.index ["betslip_id"], name: "index_bets_on_betslip_id"
  end

  create_table "betslips", force: :cascade do |t|
    t.string "name"
    t.bigint "user_id", null: false
    t.bigint "battle_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "status", default: "created", null: false
    t.boolean "locked", default: false, null: false
    t.float "earnings", default: 0.0, null: false
    t.float "max_payout_remaining", default: 0.0, null: false
    t.index ["battle_id"], name: "index_betslips_on_battle_id"
    t.index ["user_id"], name: "index_betslips_on_user_id"
  end

  create_table "games", force: :cascade do |t|
    t.datetime "start_time"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "home_team_id"
    t.integer "away_team_id"
  end

  create_table "leaderboard_entries", force: :cascade do |t|
    t.bigint "league_season_id", null: false
    t.bigint "user_id", null: false
    t.float "total_points", default: 0.0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "ranking"
    t.index ["league_season_id"], name: "index_leaderboard_entries_on_league_season_id"
    t.index ["user_id"], name: "index_leaderboard_entries_on_user_id"
  end

  create_table "league_seasons", force: :cascade do |t|
    t.bigint "season_id", null: false
    t.bigint "pool_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "start_week"
    t.index ["pool_id"], name: "index_league_seasons_on_pool_id"
    t.index ["season_id"], name: "index_league_seasons_on_season_id"
  end

  create_table "pool_memberships", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "pool_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "is_commissioner", default: false, null: false
    t.index ["pool_id"], name: "index_pool_memberships_on_pool_id"
    t.index ["user_id"], name: "index_pool_memberships_on_user_id"
  end

  create_table "pools", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "invite_token"
    t.index ["invite_token"], name: "index_pools_on_invite_token", unique: true
  end

  create_table "seasons", force: :cascade do |t|
    t.integer "year", null: false
    t.datetime "start_date", null: false
    t.datetime "end_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "teams", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "username"
    t.string "first_name"
    t.string "last_name"
    t.string "avatar"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "jti", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["jti"], name: "index_users_on_jti", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "battles", "league_seasons"
  add_foreign_key "bet_options", "games"
  add_foreign_key "bets", "bet_options"
  add_foreign_key "bets", "betslips"
  add_foreign_key "betslips", "battles"
  add_foreign_key "betslips", "users"
  add_foreign_key "games", "teams", column: "away_team_id"
  add_foreign_key "games", "teams", column: "home_team_id"
  add_foreign_key "leaderboard_entries", "league_seasons"
  add_foreign_key "leaderboard_entries", "users"
  add_foreign_key "league_seasons", "pools"
  add_foreign_key "league_seasons", "seasons"
  add_foreign_key "pool_memberships", "pools"
  add_foreign_key "pool_memberships", "users"
end
