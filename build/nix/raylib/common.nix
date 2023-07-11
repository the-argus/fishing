{fetchFromGitHub, ...}: {
  version = "4.5.0";
  src = fetchFromGitHub {
    repo = "raylib";
    owner = "raysan5";
    rev = "ed2caa12775da95d3e19ce42dccdca4a0ba8f8a0";
    hash = "sha256-EcY0Z9AsEm2B9DeA2LXSv6iJX4DwC8Gh+NNJp/F2zkQ=";
  };
}
