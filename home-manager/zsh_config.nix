{zsh = {
  enable = true; # don't forget to add   `environment.pathsToLink = [ "/share/zsh" ];` to the system environment
  enableAutosuggestions = true;
  history = {
    size = 100 * 1000;
    save = 100 * 1000;
    share = true;
    ignorePatterns = ["rm *" "pkill *"];
  };
  oh-my-zsh = {
    enable = true;
    plugins = [
      "git"
      "thefuck"
      "docker"
      "docker-compose"
      "celery" # adds completion for python celery
      "zoxide" # simple navigation with z and history
      "tmux" # adds aliases to tmux
      "extract" # creates a command extract and alias x to quickly extract files
      "dircycle" # doesn't seem to work on mini-nix -- let's me use `ctrl + shift + <left/right>` to cycle through my cd paths like a browser would
      "rsync" # adds alias like rsync-copy rsync-move
      "copypath" # copies the absolute path to the file or dir
      "colored-man-pages" # automatically color man pages. I can also preprend `colored` e.g. `colored git help clone`, to try and get colours for terminal output
      "cp" # create alias to cpv: copies with progress bar using rsync
      "copyfile" # copies the content of <file> to my clipboard. e.g. `copyfile temp.txt`
    ];
    theme = "robbyrussell";
  };
};
}
