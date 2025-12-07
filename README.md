# Agent Client Kernel / Lite Site

Minimal instructions for building and running the browser-based Lite site using `make`.

## Prerequisites
- Node.js/npm
- Python 3
- `jupyterlite` installed in your active virtualenv: `python -m pip install jupyterlite`
- If your Python binary isn’t `python3`, set `PYTHON` when invoking make (see below).

## Build
Compile the lite kernel and build the JupyterLite site into `./build`:

```
make
```
You can override the output path: `BUILD_DIR=out make`.
If your Python executable isn’t `python3`, point the Makefile at it:

```
PYTHON=/path/to/python make
```

## Run the built site
Serve the static build locally:

```
cd build
python3 -m http.server 8000
```
Then open http://localhost:8000 in your browser.

## Clean

```
make clean
```
Removes `build/` and the lite-kernel build artifacts.

## Environment overrides (optional)
Keep Jupyter writes inside the repo (recommended on macOS/Homebrew installs):

```
JUPYTER_CONFIG_DIR="$PWD/.jupyter" \
JUPYTER_DATA_DIR="$PWD/.jupyter-data" \
JUPYTER_RUNTIME_DIR="$PWD/.jupyter-runtime" \
make
```
