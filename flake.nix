{
  description = "Dungeon Crawl Stone Soup";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      inherit (nixpkgs.lib) removeSuffix;
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      # Must match crawl-ref/source/util/gen_ver.pl (not a raw git rev).
      # Bump `base` when the latest `git describe --abbrev=0` tag moves.
      version =
        let
          base = "0.35-a0";
          rev = self.shortRev or (removeSuffix "-dirty" (self.dirtyShortRev or ""));
        in
        if rev == "" then base else "${base}-0-g${rev}";
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          src = pkgs.lib.cleanSource ./.;
          mkCrawl =
            args:
            pkgs.callPackage ./nix/package.nix (
              {
                inherit src version;
              }
              // args
            );
          crawl = mkCrawl { };
          crawl-tiles = mkCrawl { tileMode = true; };
        in
        {
          inherit crawl crawl-tiles;
          default = crawl-tiles;
        }
      );

      apps = forAllSystems (
        system:
        let
          pkgs = self.packages.${system};
        in
        {
          default = {
            type = "app";
            program = "${pkgs.default}/bin/crawl-tiles";
          };
          crawl = {
            type = "app";
            program = "${pkgs.crawl}/bin/crawl";
          };
          crawl-tiles = {
            type = "app";
            program = "${pkgs.crawl-tiles}/bin/crawl-tiles";
          };
        }
      );

      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            inputsFrom = [ self.packages.${system}.crawl-tiles ];
          };
        }
      );
    };
}
