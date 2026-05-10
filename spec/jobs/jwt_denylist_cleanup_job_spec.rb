require "rails_helper"

RSpec.describe JwtDenylistCleanupJob, type: :job do
  describe "#perform" do
    it "deletes denylist rows whose exp is in the past" do
      JwtDenylist.create!(jti: "old-jti", exp: 1.day.ago)
      JwtDenylist.create!(jti: "future-jti", exp: 1.day.from_now)

      described_class.perform_now

      expect(JwtDenylist.exists?(jti: "old-jti")).to be(false)
      expect(JwtDenylist.exists?(jti: "future-jti")).to be(true)
    end
  end
end
