{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    awscli2
    ssm-session-manager-plugin
    terraform
    kubectl
    kubernetes-helm
    eksctl
    k9s
  ];
}
