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
  agentInstallHook = agentLib.mkShellHook {
    inherit pkgs bundle;
    targets = {
      agents = {
        enable = true;
        dest = ".agents/skills";
        structure = "copy-tree";
      };
    };
  };
in {
  env = {
    ANSIBLE_CONFIG = "${config.env.DEVENV_ROOT}/ansible/ansible.cfg";
    KUBECONFIG = "${config.env.DEVENV_ROOT}/kubeconfig";
    SOPS_AGE_KEY_FILE = "${config.env.DEVENV_ROOT}/age.key";
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
    yq
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
    end-of-file-fixer.enable = true;
    shfmt.enable = true;
    trufflehog.enable = true;
    yamllint.enable = true;
    markdownlint.enable = true;
  };

  tasks."agent-skills:install" = {
    exec = agentInstallHook;
    before = ["devenv:enterShell"];
  };
}
