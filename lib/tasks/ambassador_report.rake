# # lib/tasks/ambassador_report.rake
# namespace :report do
#   desc "Print unique-user counts per ambassador across all pools their referees commissioned"
#   task ambassadors: :environment do
#     header = %w[ambassador_key ambassador_label pools_created unique_users direct_referred_signups]
#     rows   = [header]

#     User.ambassadors.each do |amb_key, amb_val|
#       # 1) Users who selected this ambassador at signup
#       referred_ids        = User.where(ambassador: amb_val).pluck(:id)
#       direct_referred_cnt = referred_ids.size

#       # 2) Pools where any of those users is a commissioner
#       pool_ids = if referred_ids.empty?
#                    []
#                  else
#                    PoolMembership.where(is_commissioner: true, user_id: referred_ids)
#                                  .distinct
#                                  .pluck(:pool_id)
#                  end
#       pools_created_cnt = pool_ids.size

#       # 3) Unique users across ALL memberships for those pools (commissioners INCLUDED)
#       unique_users_cnt = if pool_ids.empty?
#                            0
#                          else
#                            PoolMembership.where(pool_id: pool_ids).distinct.count(:user_id)
#                          end

#       rows << [
#         amb_key,
#         amb_key.to_s.humanize.titleize,
#         pools_created_cnt,
#         unique_users_cnt,
#         direct_referred_cnt
#       ]
#     end

#     # Pretty-print table
#     widths = rows.transpose.map { |col| col.map { |v| v.to_s.length }.max }
#     rows.each_with_index do |row, i|
#       line = row.each_with_index.map { |cell, idx| cell.to_s.ljust(widths[idx]) }.join(" | ")
#       puts line
#       puts widths.map { |w| "-" * w }.join("-+-") if i.zero?
#     end
#   end
# end

# # lib/tasks/ambassador_report.rake
# namespace :report do
#   desc "Ambassador reach: union of (members of pools created by their referees) and (their direct referees who joined any league)"
#   task ambassadors: :environment do
#     header = %w[
#       ambassador_key
#       ambassador_label
#       pools_created
#       unique_users_ref_pools
#       direct_referred_joiners
#       unique_users_total_union
#     ]
#     rows = [header]

#     User.ambassadors.each do |amb_key, amb_val|
#       # Subquery: users who selected this ambassador
#       referred_users_subq = User.where(ambassador: amb_val).select(:id)

#       # Pools where any referred user is a commissioner
#       # (count distinct pool_ids without loading into Ruby)
#       pools_created_cnt = PoolMembership
#                             .where(is_commissioner: true, user_id: referred_users_subq)
#                             .distinct
#                             .count(:pool_id)

#       # Subquery: the pool ids above (as a relation) for reuse
#       ref_pool_ids_subq = PoolMembership
#                             .where(is_commissioner: true, user_id: referred_users_subq)
#                             .select(:pool_id)
#                             .distinct

#       # Set A: unique users across all memberships in those pools
#       unique_users_ref_pools = if pools_created_cnt.zero?
#         0
#       else
#         PoolMembership.where(pool_id: ref_pool_ids_subq).distinct.count(:user_id)
#       end

#       # Set B: direct-referred users who joined ANY league (i.e., they have a membership)
#       direct_referred_joiners = PoolMembership
#                                   .where(user_id: referred_users_subq)
#                                   .distinct
#                                   .count(:user_id)

#       # Union A ∪ B without double-counting:
#       # Count distinct user_id among memberships where (pool in A) OR (user is in referred cohort)
#       base = PoolMembership.all
#       union_relation =
#         if pools_created_cnt.zero?
#           base.where(user_id: referred_users_subq)
#         else
#           base.where(pool_id: ref_pool_ids_subq).or(base.where(user_id: referred_users_subq))
#         end
#       unique_users_total_union = union_relation.distinct.count(:user_id)

#       rows << [
#         amb_key,
#         amb_key.to_s.humanize.titleize,
#         pools_created_cnt,
#         unique_users_ref_pools,
#         direct_referred_joiners,
#         unique_users_total_union
#       ]
#     end

#     # Pretty-print table
#     widths = rows.transpose.map { |col| col.map { |v| v.to_s.length }.max }
#     rows.each_with_index do |row, i|
#       line = row.each_with_index.map { |cell, idx| cell.to_s.ljust(widths[idx]) }.join(" | ")
#       puts line
#       puts widths.map { |w| "-" * w }.join("-+-") if i.zero?
#     end

#     puts "\nNotes:"
#     puts "- 'unique_users_ref_pools' = distinct users in pools where a commissioner is a direct referral of the ambassador."
#     puts "- 'direct_referred_joiners' = direct referrals who joined any league (at least one membership)."
#     puts "- 'unique_users_total_union' = union of the two sets (no double-count)."
#     puts "- Commissioners are included; a person may appear under multiple ambassadors if leagues overlap."
#   end
# end

# lib/tasks/ambassador_report.rake
namespace :report do
  desc "Ambassador reach: union of (members of pools created by their referees) and (their direct referees who joined any league). Includes raw direct signup count."
  task ambassadors: :environment do
    header = %w[
      ambassador_key
      ambassador_label
      direct_referred_signups
      direct_referred_joiners
      pools_created
      unique_users_ref_pools
      unique_users_total_union
    ]
    rows = [header]

    User.ambassadors.each do |amb_key, amb_val|
      # Cohort: users who selected this ambassador (raw signups)
      referred_scope           = User.where(ambassador: amb_val)
      direct_referred_signups  = referred_scope.count
      referred_users_subq      = referred_scope.select(:id) # for subqueries

      # Pools where any referred user is a commissioner
      ref_commissioner_pools   = PoolMembership
                                   .where(is_commissioner: true, user_id: referred_users_subq)
      pools_created_cnt        = ref_commissioner_pools.distinct.count(:pool_id)

      # Set A: distinct users across ALL memberships in those pools (commissioners INCLUDED)
      unique_users_ref_pools = if pools_created_cnt.zero?
        0
      else
        PoolMembership.where(pool_id: ref_commissioner_pools.select(:pool_id))
                      .distinct
                      .count(:user_id)
      end

      # Set B: direct-referred users who joined ANY league (at least one membership)
      direct_referred_joiners = PoolMembership
                                  .where(user_id: referred_users_subq)
                                  .distinct
                                  .count(:user_id)

      # Union A ∪ B (no double-count): distinct user_ids where
      # - membership is in any pool commissioned by the ambassador's referees OR
      # - membership belongs to a direct-referred user (in any pool)
      union_relation =
        if pools_created_cnt.zero?
          PoolMembership.where(user_id: referred_users_subq)
        else
          PoolMembership.where(pool_id: ref_commissioner_pools.select(:pool_id))
                        .or(PoolMembership.where(user_id: referred_users_subq))
        end
      unique_users_total_union = union_relation.distinct.count(:user_id)

      rows << [
        amb_key,
        amb_key.to_s.humanize.titleize,
        direct_referred_signups,
        direct_referred_joiners,
        pools_created_cnt,
        unique_users_ref_pools,
        unique_users_total_union
      ]
    end

    # Pretty-print table to console
    widths = rows.transpose.map { |col| col.map { |v| v.to_s.length }.max }
    rows.each_with_index do |row, i|
      line = row.each_with_index.map { |cell, idx| cell.to_s.ljust(widths[idx]) }.join(" | ")
      puts line
      puts widths.map { |w| "-" * w }.join("-+-") if i.zero?
    end

    puts "\nNotes:"
    puts "- direct_referred_signups: users who selected the ambassador at signup (whether or not they joined a league)."
    puts "- direct_referred_joiners: those direct referrals who have at least one pool membership."
    puts "- unique_users_ref_pools: distinct users in pools where a commissioner is a direct referral of the ambassador."
    puts "- unique_users_total_union: union of the two sets above (no double-count)."
    puts "- Commissioners are included; a person may appear under multiple ambassadors if their leagues overlap."
  end
end
