# Simple build orchestration for the Lite HTTP chat site
# Usage:
#   make          # same as `make build`
#   make build    # build bundle + JupyterLite site into ./build
#   make clean    # remove build outputs
#
# Environment overrides:
#   BUILD_DIR=out make build
#   JUPYTER_CONFIG_DIR=... JUPYTER_DATA_DIR=... JUPYTER_RUNTIME_DIR=... make build

BUILD_DIR ?= build
LITE_KERNEL_DIR := lite-kernel
LITE_SITE_DIR   := lite-site
BUNDLE          := $(LITE_KERNEL_DIR)/dist/index.js
EXT_DIR         := $(LITE_SITE_DIR)/extensions/lite-kernel

PYTHON ?= python3
JUPYTER_CONFIG_DIR ?= $(CURDIR)/.jupyter
JUPYTER_DATA_DIR   ?= $(CURDIR)/.jupyter-data
JUPYTER_RUNTIME_DIR?= $(CURDIR)/.jupyter-runtime

.PHONY: all install bundle build clean check-jupyterlite check-pyodide

all: build

check-jupyterlite:
	@printf '%s\n' \
		"import importlib.util, sys" \
		"if importlib.util.find_spec('jupyterlite') is None:" \
		"    sys.stderr.write('jupyterlite not found. Install with: $(PYTHON) -m pip install jupyterlite\n')" \
		"    sys.exit(1)" \
		| $(PYTHON) -

check-pyodide:
	@printf '%s\n' \
		"import importlib.util, sys" \
		"if importlib.util.find_spec('jupyterlite_pyodide_kernel') is None:" \
		"    sys.stderr.write('Pyodide kernel not found. Install with: $(PYTHON) -m pip install jupyterlite-pyodide-kernel\n')" \
		"    sys.exit(1)" \
		| $(PYTHON) -

# Install JS deps for the lite kernel
install:
	npm --prefix $(LITE_KERNEL_DIR) install

# Compile TypeScript + bundle with esbuild
bundle: install
	npm --prefix $(LITE_KERNEL_DIR) run build

# Build the JupyterLite site and place output under $(BUILD_DIR)
build: check-jupyterlite check-pyodide bundle
	@rm -rf $(BUILD_DIR)
	@mkdir -p $(EXT_DIR)
	cp $(BUNDLE) $(EXT_DIR)/index.js
	cd $(LITE_SITE_DIR) && \
		JUPYTER_CONFIG_DIR=$(JUPYTER_CONFIG_DIR) \
		JUPYTER_DATA_DIR=$(JUPYTER_DATA_DIR) \
		JUPYTER_RUNTIME_DIR=$(JUPYTER_RUNTIME_DIR) \
		$(PYTHON) -m jupyterlite build --output-dir $(CURDIR)/$(BUILD_DIR)
	@mkdir -p $(BUILD_DIR)/extensions/lite-kernel
	cp $(BUNDLE) $(BUILD_DIR)/extensions/lite-kernel/index.js
	@printf '%s\n' \
		"import json" \
		"from pathlib import Path" \
		"config_path = Path('$(BUILD_DIR)') / 'jupyter-lite.json'" \
		"if config_path.exists():" \
		"    data = json.loads(config_path.read_text())" \
		"    cfg = data.setdefault('jupyter-config-data', {})" \
		"    fed = cfg.setdefault('federated_extensions', [])" \
		"    if not any(e.get('name') == 'lite-kernel' for e in fed):" \
		"        fed.append({'name': 'lite-kernel', 'load': 'index.js', 'extension': './index'})" \
		"        config_path.write_text(json.dumps(data, indent=2))" \
		| $(PYTHON) -
	@echo "Build complete -> $(BUILD_DIR)"

clean:
	rm -rf $(BUILD_DIR) $(LITE_KERNEL_DIR)/dist $(LITE_KERNEL_DIR)/lib
