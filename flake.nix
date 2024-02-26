{
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" ];
      config.allowUnfree = true;
      overlays = [
        (final: prev: {
          tiny-cuda-nn = prev.tiny-cuda-nn.overrideAttrs (old:
            let
              cuda-common-redist = with final.cudaPackages; [
                cuda_cudart.dev # cuda_runtime.h
                cuda_cudart.lib
                cuda_cccl.dev # <nv/target>
                libcublas.dev # cublas_v2.h
                libcublas.lib
                libcusolver.dev # cusolverDn.h
                libcusolver.lib
                libcusparse.dev # cusparse.h
                libcusparse.lib
              ];
              cuda-common-redist' = with final.cudaPackages; [
                cuda_cudart.dev # cuda_runtime.h
                cuda_cudart.lib
                cuda_cccl.dev # <nv/target>
                libcublas.dev # cublas_v2.h
                libcublas.lib
                libcusolver.dev # cusolverDn.h
                libcusolver.lib
                libcusparse.dev # cusparse.h
                libcusparse.lib
                cudatoolkit
              ];
              cuda-native-redist = final.symlinkJoin {
                name = "cuda-redist";
                paths = with final.cudaPackages;
                  [ cuda_nvcc ]
                  ++ cuda-common-redist;
              };
              cuda-native-redist' = final.symlinkJoin {
                name = "cuda-redist";
                paths = with final.cudaPackages;
                  [ cuda_nvcc ]
                  ++ cuda-common-redist';
              };
              cuda-redist = final.symlinkJoin {
                name = "cuda-redist";
                paths = cuda-common-redist;
              };
              cuda-redist' = final.symlinkJoin {
                name = "cuda-redist";
                paths = cuda-common-redist';
              };
              inherit (nixpkgs.lib) remove;
              nativeBuildInputs = [ cuda-native-redist' ] ++ (remove cuda-native-redist old.nativeBuildInputs);
              buildInputs = [ cuda-redist' ] ++ (remove cuda-redist old.buildInputs);
            in
            {
              inherit nativeBuildInputs buildInputs;
            });
        })
      ];
      forEachSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        inherit system;
        pkgs = import nixpkgs { inherit system config overlays; };
      });
    in
    {
      formatter = forEachSystem ({ pkgs, ... }: pkgs.nixpkgs-fmt);
      packages = forEachSystem
        ({ pkgs, ... }: {
          default = pkgs.tiny-cuda-nn;
          python = pkgs.tiny-cuda-nn.override { pythonSupport = true; };
        });
    };
}
