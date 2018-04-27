## Installation script :

Installation script is build for Linux Ubuntu 16.04.

The script has been tested for the following VPS provider :

| Provider | Result |
| :---: | :---: |
| OVH  | OK |
| Scaleway  | OK |
| Vultr  | Not tested |

VPS provider are configuring Linux core in their own way that can cause error in script. Please reports if you test it on another provider listed above.

To launch the installation, connect to your VPS via SSH and run this command :

```bash
wget https://raw.githubusercontent.com/monacocoin-net/masternode-script-monoeci/master/install.sh && chmod +x install.sh && ./install.sh
```

Follow the on-screen instructions.


---

## Update script (from 0.12.2.0 to 0.12.2.3)

To launch the installation, connect to your VPS via SSH and run this command :

```bash
wget https://raw.githubusercontent.com/monacocoin-net/masternode-script-monoeci/master/update_12_2_0_to_12_2_3.sh && chmod +x update_12_2_0_to_12_2_3.sh && ./update_12_2_0_to_12_2_3.sh
```

Follow the on-screen instructions.


---
## Error troubleshooting : 
If for some reason you dont have Git installed, you can install git with the following command:

```bash
sudo apt-get install git -y
```

If script doesn't start : 
- Check that you have write permission in the current folder
- Check that you can change permission on a file
