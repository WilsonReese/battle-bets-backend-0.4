# lib/tasks/metrics_snapshot.rake
namespace :metrics do
  desc "Snapshot counts up to a cutoff date (inclusive): Users, Pools, Betslips(amount_bet>0). Usage: DATE=YYYY-MM-DD [TZ=America/Chicago] bin/rails metrics:snapshot"
  task snapshot: :environment do
    # Parse inputs
    date_str = ENV["DATE"]
    if date_str.blank?
      puts "Please provide DATE=YYYY-MM-DD (or full timestamp). Example: DATE=2025-08-15 bin/rails metrics:snapshot"
      exit 1
    end

    # Respect Rails.time_zone; allow override with TZ=...
    if (tz = ENV["TZ"]).present?
      Time.use_zone(tz) {}
      Time.zone = tz
    end

    cutoff =
      begin
        # end_of_day so the day is inclusive
        Time.zone.parse(date_str).end_of_day
      rescue
        nil
      end

    unless cutoff
      puts "Could not parse DATE='#{date_str}' in TZ=#{Time.zone.name rescue 'UTC'}"
      exit 1
    end

    # --- Counts ---
    users_count = User.where("created_at <= ?", cutoff).count

    # Pools created by/before the cutoff (most common interpretation)
    pools_count = Pool.where("created_at <= ?", cutoff).count

    # Betslips where money was actually bet and the slip was updated by/before cutoff
    betslips_count =
      Betslip
        .where("updated_at <= ?", cutoff)
        .where("amount_bet > 0")
        .count

    # --- Output (pretty table) ---
    rows = [
      ["metric",                               "value"],
      ["cutoff (inclusive, end_of_day)",       cutoff.in_time_zone.strftime("%Y-%m-%d %H:%M %Z")],
      ["users_created_on_or_before",           users_count],
      ["pools_created_on_or_before",           pools_count],
      ["betslips_amount_gt_0_updated_on_or_before", betslips_count],
    ]

    widths = rows.transpose.map { |col| col.map { |v| v.to_s.length }.max }
    rows.each_with_index do |row, i|
      line = row.each_with_index.map { |cell, idx| cell.to_s.ljust(widths[idx]) }.join(" | ")
      puts line
      puts widths.map { |w| "-" * w }.join("-+-") if i.zero?
    end

    puts "\nNotes:"
    puts "- All comparisons are <= cutoff (inclusive)."
    puts "- Betslips are filtered on updated_at and amount_bet > 0."
  end
end
