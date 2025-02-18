{
  description = "Flake for Expo ecosystem";

  inputs.nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

  outputs = {
    self,
    nixpkgs,
  }: let
    mkEasCli = pkgs:
      pkgs.stdenvNoCC.mkDerivation (finalAttrs: {
        pname = "eas-cli";
        version = "15.0.10";

        src = pkgs.fetchFromGitHub {
          owner = "expo";
          repo = "eas-cli";
          rev = "v${finalAttrs.version}";
          hash = "sha256-wYQTeh9qNBWdd0wC/ubMgRIJkibd6FYpI37r2WpqrYc=";
        };

        packageJson = finalAttrs.src + "/packages/eas-cli/package.json";

        yarnOfflineCache = pkgs.fetchYarnDeps {
          yarnLock = finalAttrs.src + "/yarn.lock"; # Point to the root lockfile
          hash = "sha256-pnp9MI2S5v4a7KftxYC3Sgc487vooX8+7lmYkmRTWWs=";
        };

        nativeBuildInputs = with pkgs; [
          yarnConfigHook
          yarnBuildHook
          yarnInstallHook
          nodejs
          jq
        ];

        # Add version field to package.json to prevent yarn pack from failing
        preInstall = ''
          echo "Adding version field to package.json"
          jq '. + {version: "${finalAttrs.version}"}' package.json > package.json.tmp
          mv package.json.tmp package.json
        '';

        postInstall = ''
          echo "Creating symlink for eas-cli binary"
          mkdir -p $out/bin
          ln -sf $out/lib/node_modules/eas-cli-root/packages/eas-cli/bin/run $out/bin/eas
          chmod +x $out/bin/eas

          # no longer required after build
          rm -f $out/lib/node_modules/eas-cli-root/node_modules/.bin/rimraf
        '';

        meta = with pkgs.lib; {
          changelog = "https://github.com/expo/eas-cli/releases/tag/v${finalAttrs.version}";
          description = "EAS command line tool from submodule";
          homepage = "https://github.com/expo/eas-cli";
          license = licenses.mit;
        };
      });

    supportedSystems = ["x86_64-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin"];

    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
  in {
    packages = forAllSystems (system: let
      pkgs = import nixpkgs {inherit system;};
    in {
      default = mkEasCli pkgs;
      eas-cli = mkEasCli pkgs;
    });
  };
}
