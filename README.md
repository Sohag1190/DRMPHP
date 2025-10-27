# DRMPHP
**NOTICE**: The adding of user lines is a work in progress, do not use in a production enviroment until fully completed.  
## Installation
```bash
curl -sL https://raw.githubusercontent.com/DRM-Scripts/DRMPHP/master/installer.sh | bash
```
This script has been tested on the following Linux distributions: Ubuntu 18.04+, Debian 10, CentOS 8, Fedora 30.


**To install DRMPHP on Ubuntu using the script from your GitHub repository, run the following commands in your terminal:**

```bash
wget https://raw.githubusercontent.com/Sohag1190/DRMPHP/master/install_drmphp_ubuntu.sh
chmod +x install_drmphp_ubuntu.sh
sudo ./install_drmphp_ubuntu.sh
```

---

### 🧰 What This Script Does

- **Checks system compatibility**: Only runs on Ubuntu 18.04, 20.04, or 22.04 with `x86_64` architecture.
- **Installs dependencies**: Apache, MySQL, PHP (7.2 or 7.4), Git, aria2, and ffmpeg.
- **Clones the DRMPHP repo**: Into `/opt/drmphp`.
- **Configures MySQL and PHP**: Sets SQL mode and enables `short_open_tag`.
- **Prompts for custom web port**: Updates Apache config if needed.
- **Deploys the panel**: Moves files to `/var/www/html`, sets permissions, and prepares directories.
- **Sets up MySQL database**: Asks for root password, creates DB/user, updates `_db.php`, and imports schema.
- **Displays access info**: Shows panel URL, default credentials, and setup notes.

---



