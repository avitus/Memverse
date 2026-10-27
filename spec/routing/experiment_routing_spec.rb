require "spec_helper"

# MEMVERSE-9J: /finish_experiment called Split's ab_finished long after the
# Split gem was removed, so every request raised NoMethodError
describe "Split experiment routing" do
  it "does not route /finish_experiment" do
    expect(get("/finish_experiment?experiment=signupform")).not_to be_routable
  end
end
