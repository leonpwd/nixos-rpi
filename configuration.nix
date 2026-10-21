{ config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./modules/base.nix
    ./modules/secrets.nix
    ./modules/nginx.nix
    ./modules/services.nix
  ];
}
