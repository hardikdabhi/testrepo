# Websphere Portal Copy Theme

Shell script to create copy of default Websphere Portal theme and deploy created theme on Portal.

## How to use

1. Download and copy ```copy-theme.sh``` and ```copy-theme.sh.bin``` in same directory.
2. **IMPORTANT** - Connect to themelist webdav (script will look for existing dav connection to copy static resources). Which is ```dav://{portal_host}:{portal_port}/wps/mycontenthandler/dav/themelist```.
3. Run ```./copy-theme.sh```.
4. Change static resources and dynamic resources as required.

## Parameter Information

* Protocol - Protocol on which portal is running
* host - Host name for portal
* port - Port on which portal is running
* username - Portal admin username
* password - Portal admin password
* profilePath - Absolute path to profile on which portal is installed
* portalPath - Absolute path to portal server root
* server - Name of Websphere Portal server
* themeId - Unique name or id of new theme
* themeName - Name of new theme

> Note: Either of above parameters can be left blank. In that case default parameter will be used.

## Versions Supported

Websphere Portal v8.x
