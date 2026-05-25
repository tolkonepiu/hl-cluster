{
  config,
  inputs,
  pkgs,
  ...
}: let
  agentLib = inputs.agent-skills.lib.agent-skills;
  sources = {
    flux = {
      path = inputs.flux-agent-skills;
      subdir = "skills";
      filter.maxDepth = 1;
    };
  };
  catalog = agentLib.discoverCatalog sources;
  allowlist = agentLib.allowlistFor {
    inherit catalog sources;
    enableAll = ["flux"];
  };
  selection = agentLib.selectSkills {
    inherit catalog allowlist sources;
    skills = {};
  };
  bundle = agentLib.mkBundle {
    inherit pkgs selection;
  };
  agentSkillsInstallHook = agentLib.mkShellHook {
    inherit pkgs bundle;
    targets = {
      agents = {
        enable = true;
        dest = ".agents/skills";
        structure = "copy-tree";
      };
    };
  };
  mcp = {
    kubernetes-mcp-server = {
      type = "remote";
      url = "https://kubernetes-mcp-server.popov.wtf/mcp";
    };
    flux-operator-mcp = {
      type = "remote";
      url = "https://flux-operator-mcp.popov.wtf/mcp";
    };
    mcp-victoriametrics = {
      type = "remote";
      url = "https://mcp-victoriametrics.popov.wtf/mcp";
    };
  };
in {
  env = {
    ANSIBLE_CONFIG = "${config.env.DEVENV_ROOT}/ansible/ansible.cfg";
    KUBECONFIG = "${config.env.DEVENV_ROOT}/kubeconfig";
    SOPS_AGE_KEY_FILE = "${config.env.DEVENV_ROOT}/age.key";
    SOPS_CONFIG = "${config.env.DEVENV_ROOT}/.sops.yaml";
  };

  packages = with pkgs; [
    age
    ansible
    cilium-cli
    cloudflared
    fluxcd
    git
    go-task
    helmfile
    jq
    kubeconform
    kubectl
    kubefetch
    kubernetes-helm
    kustomize
    moreutils
    sops
    stern
    yaml-language-server
    yq-go
  ];

  git-hooks.hooks = {
    alejandra.enable = true;
    ansible-lint = {
      enable = true;
      settings.subdir = "ansible";
    };
    check-yaml.enable = true;
    deadnix.enable = true;
    shellcheck.enable = true;
    statix.enable = true;
    shfmt.enable = true;
    trufflehog.enable = true;
    yamllint.enable = true;
    markdownlint.enable = true;
  };

  opencode = {
    enable = true;
    inherit mcp;
  };

  tasks."agent-skills:install" = {
    exec = agentSkillsInstallHook;
    before = ["devenv:enterShell"];
  };
}
