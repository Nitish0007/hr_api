class JwtDenylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist

  self.table_name = "jwt_denylist"

  # Rows are safe to delete after +exp+ (JWT is already invalid). Batch to limit lock duration.
  def self.purge_expired
    where(arel_table[:exp].lt(Time.current)).in_batches(of: 1_000, &:delete_all)
  end
end
