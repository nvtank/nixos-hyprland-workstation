{ ... }: {
  # Store deduplication only; retain recovery generations and existing update policy.
  nix.optimise = {
    automatic = true;
    dates = [ "weekly" ];
  };
}
