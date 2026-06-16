# asterisk-install

Bash script for installing Asterisk from source on Debian-based systems.

## What It Does

- installs the base packages required for building Asterisk;
- downloads the requested Asterisk source archive;
- runs `contrib/scripts/install_prereq install`;
- runs `./configure`, `make`, and `make install`;
- optionally installs sample configuration files with `--with-samples`;
- installs init scripts and logrotate configuration.

## Requirements

- Debian-based Linux distribution;
- run as `root` or via `sudo`;
- `--asterisk-version` is required.

## Usage

```bash
chmod +x asterisk-install.sh
sudo ./asterisk-install.sh --asterisk-version=20.19.0
```

With sample configuration files:

```bash
sudo ./asterisk-install.sh --asterisk-version=20.19.0 --with-samples
```

## After Installation

Start the service:

```bash
systemctl start asterisk
```

Check status:

```bash
systemctl status asterisk
```

Open the Asterisk CLI:

```bash
asterisk -rvvv
```
