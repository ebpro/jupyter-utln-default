import  os
import shutil
def _get_code_server_cmd(port):
    executable = "code-server"
    if not shutil.which(executable):
        raise FileNotFoundError("Can not find code-server in PATH")

    # Start vscode in CODE_WORKINGDIR env variable if set
    # If not, start in 'current directory', which is $REPO_DIR in mybinder
    # but /home/jovyan (or equivalent) in JupyterHubs
    working_dir = os.getenv("CODE_WORKINGDIR", ".")

    extensions_dir = os.getenv("CODESERVEREXT_DIR", None)

    cmd = [
        executable,
        "--auth","none",
        "--disable-telemetry",
        "--disable-update-check",
        "--bind-addr","0.0.0.0:{port}",
        "--user-data-dir",os.getenv("CODESERVERDATA_DIR")
    ]

    if extensions_dir:
        cmd += ["--extensions-dir", extensions_dir]

    cmd.append(working_dir)
    return cmd


c.ServerProxy.servers = {
  'codeserver': {
    'command': _get_code_server_cmd,
    'timeout': 20,
    'launcher_entry': {
      'title': 'VS Code',
      'icon_path': os.path.join(
                os.path.dirname(os.path.abspath(__file__)), "icons", "code-server.svg"),
    }
  }
}

