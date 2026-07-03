function __omf.doctor.theme
  if not omf.check.fish_prompt
    echo (omf::err)"Warning: "(omf::off)(omf::em)"fish_prompt.fish"(omf::off)" is overridden."
    echo (omf::em)"  fish_config"(omf::off)" command persists the prompt to "(omf::em)"~/.config/fish/functions/fish_prompt.fish"(omf::off)
    echo "  That file takes precedence over Oh My Fish's themes. Remove the file to fix it:"
    echo (omf::em)"  rm ~/.config/fish/functions/fish_prompt.fish"(omf::off)
    echo

    return 1
  end

  return 0
end

function __omf.doctor.fish_version
  set -l min_version 3.0.0
  set -l current_version
  begin
    echo $FISH_VERSION | read -la --delimiter - version_parts
    set current_version "$version_parts[1]"
  end

  if not omf.check.version $min_version $current_version
    echo (omf::err)"Warning: "(omf::off)"Oh-My-Fish requires "(omf::em)"fish"(omf::off)" version "(omf::em)"$min_version"(omf::off)" or above"
    echo "Your fish version is "(omf::em)$FISH_VERSION(omf::off)
    echo
    return 1
  end
end

function __omf.doctor.wsl
  set -l is_wsl 0
  if set -q WSL_DISTRO_NAME
    set is_wsl 1
  else if test -f /proc/version; and string match -q '*icrosoft*' (cat /proc/version)
    set is_wsl 1
  end

  if test $is_wsl -eq 0
    return 0
  end

  set -l wsl_label "(unknown distro)"
  if set -q WSL_DISTRO_NAME; and test -n "$WSL_DISTRO_NAME"
    set wsl_label "($WSL_DISTRO_NAME)"
  end
  echo "Environment:          WSL $wsl_label"

  if type -q git; and git --version | string match -qi '*windows*'
    echo (omf::err)"Warning: "(omf::off)"Git for Windows is on PATH. OMF requires Linux git inside WSL."
    echo "  Remove Windows Git from PATH or uninstall Git for Windows."
    echo "  See: https://github.com/chrisflory/oh-my-fish#installing-on-windows-wsl"
    echo
    return 1
  end

  if set -q OMF_PATH; and string match -q '/mnt/*' $OMF_PATH
    echo (omf::err)"Warning: "(omf::off)"OMF is installed on the Windows filesystem "(omf::em)$OMF_PATH(omf::off)"."
    echo "  File I/O across /mnt/c is slower. Prefer a Linux home path, e.g.:"
    echo (omf::em)"  bin/install --path=~/.local/share/omf --config=~/.config/omf"(omf::off)
    echo
    return 1
  end

  return 0
end

function __omf.doctor.git_version
  set -l min_version 1.9.5
  set -l current_version
  begin
    git --version | read -la version_parts
    set current_version "$version_parts[3]"
  end

  if not omf.check.version $min_version $current_version
    echo (omf::err)"Warning: "(omf::off)"Oh-My-Fish requires "(omf::em)"git"(omf::off)" version "(omf::em)"$min_version"(omf::off)" or above"
    echo "Your git version is "(omf::em)$current_version(omf::off)
    echo
    return 1
  end
end

function omf.doctor
  echo "Oh My Fish version:   "(omf.version)
  echo "OS type:              "(uname)
  echo "Fish version:         "(fish --version)
  echo "Git version:          "(git --version)
  echo "Git core.autocrlf:    "(git config core.autocrlf; or echo no)

  __omf.doctor.fish_version; or set -l doctor_failed
  __omf.doctor.git_version; or set -l doctor_failed
  __omf.doctor.wsl; or set -l doctor_failed
  __omf.doctor.theme; or set -l doctor_failed

  fish "$OMF_PATH/bin/install" --check
    or set -l doctor_failed

  if set -q doctor_failed
    echo "If everything you use Oh My Fish for is working fine, please don't worry and just ignore the warnings. Thanks!"
  else
    echo (omf::em)"Your shell is ready to swim."(omf::off)
  end
end
