# lib/tasks/ambassador_report.rake
namespace :report do
  desc "Print unique-user counts per ambassador across all pools their referees commissioned"
  task ambassadors: :environment do
    header = %w[ambassador_key ambassador_label pools_created unique_users direct_referred_signups]
    rows   = [header]

    User.ambassadors.each do |amb_key, amb_val|
      # 1) Users who selected this ambassador at signup
      referred_ids        = User.where(ambassador: amb_val).pluck(:id)
      direct_referred_cnt = referred_ids.size

      # 2) Pools where any of those users is a commissioner
      pool_ids = if referred_ids.empty?
                   []
                 else
                   PoolMembership.where(is_commissioner: true, user_id: referred_ids)
                                 .distinct
                                 .pluck(:pool_id)
                 end
      pools_created_cnt = pool_ids.size

      # 3) Unique users across ALL memberships for those pools (commissioners INCLUDED)
      unique_users_cnt = if pool_ids.empty?
                           0
                         else
                           PoolMembership.where(pool_id: pool_ids).distinct.count(:user_id)
                         end

      rows << [
        amb_key,
        amb_key.to_s.humanize.titleize,
        pools_created_cnt,
        unique_users_cnt,
        direct_referred_cnt
      ]
    end

    # Pretty-print table
    widths = rows.transpose.map { |col| col.map { |v| v.to_s.length }.max }
    rows.each_with_index do |row, i|
      line = row.each_with_index.map { |cell, idx| cell.to_s.ljust(widths[idx]) }.join(" | ")
      puts line
      puts widths.map { |w| "-" * w }.join("-+-") if i.zero?
    end
  end
end