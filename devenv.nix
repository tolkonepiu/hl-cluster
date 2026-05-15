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
  mcpServers = {
    kubernetes-mcp-server = {
      type = "http";
      url = "https://kubernetes-mcp-server.popov.wtf/mcp";
    };
    flux-operator-mcp = {
      type = "http";
      url = "https://flux-operator-mcp.popov.wtf/mcp";
    };
    mcp-victoriametrics = {
      type = "http";
      url = "https://mcp-victoriametrics.popov.wtf/mcp";
    };
  };
  opencodeMcpConfig = inputs.mcp-servers-nix.lib.mkConfig pkgs {
    flavor = "opencode";
    settings.servers = mcpServers;
  };
  claudeCodeMcpConfig = inputs.mcp-servers-nix.lib.mkConfig pkgs {
    flavor = "claude-code";
    settings.servers = mcpServers;
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
    shfmt.enable = true;
    trufflehog.enable = true;
    yamllint.enable = true;
    markdownlint.enable = true;
  };

  tasks."agent-skills:install" = {
    exec = agentSkillsInstallHook;
    before = ["devenv:enterShell"];
  };

  tasks."mcp:install" = {
    exec = ''
      ln -sf ${claudeCodeMcpConfig} .mcp.json
      ln -sf ${opencodeMcpConfig} opencode.json
    '';
    before = ["devenv:enterShell"];
  };
}
