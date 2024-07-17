################################################################################
# Script Name:    install_webex.sh
# Description:    This script downloads and installs the appropriate version of
#                 Webex based on the processor type (Intel or ARM) on macOS.
#                 It verifies the integrity of the downloaded file and the 
#                 application, and performs cleanup on failure.
#
# Usage:          ./install_webex.sh
#
# Author:         Randall Ashley (rashley@wayfair.com)
# Created:        07/17/24
# Last Modified:  07/17/24
#
# Version:        1.0
#
# Requirements:   - macOS
#                 - Internet connection
#                 - Administrator privileges
#
# Parameters:     None
#
# Exit Codes:     0 - Success
#                 1 - Failure
#
# Notes:          Ensure this script is run with the necessary permissions.
#
# Change Log:
#                 - 1.0: Initial version
#
################################################################################

cleanup() {
  if mount | grep -q "/Volumes/Webex"; then
    diskutil unmount /Volumes/Webex || { echo "Failed to unmount disk image during cleanup"; }
  fi
  rm -f $DOWNLOAD_PATH
  rm -rf /Applications/Webex.app
}

# Fetch the processor name from the system profile
Processor_Name=$(system_profiler SPHardwareDataType | grep "Processor Name:")
Intel_URL="https://binaries.webex.com/WebexTeamsDesktop-MACOS-Gold/Webex.dmg"
ARM_URL="https://binaries.webex.com/WebexDesktop-MACOS-Apple-Silicon-Gold/Webex.dmg"
DOWNLOAD_PATH="/Users/Shared/Webex.dmg"

# Create an empty file to indicate the download location
touch "$DOWNLOAD_PATH"

# Determine the processor type and download the appropriate Webex version
if [[ "$Processor_Name" == *Intel* ]]; then
  echo "Processor is Intel"
  curl $Intel_URL --output $DOWNLOAD_PATH || { echo "Failed to download Webex for Intel"; cleanup; exit 1; }
else
  echo "Processor is not Intel"
  curl $ARM_URL --output $DOWNLOAD_PATH || { echo "Failed to download Webex for ARM"; cleanup; exit 1; }
fi

# Verify the downloaded file
codesign -v --verbose $DOWNLOAD_PATH || { echo "Downloaded file verification failed"; cleanup; exit 1; }

# Attach the disk image
hdiutil attach $DOWNLOAD_PATH -nobrowse || { echo "Failed to attach disk image"; cleanup; exit 1; }

# Verify the application within the disk image
codesign -v --verbose /Volumes/Webex/Webex.app || { echo "Webex.app verification failed"; cleanup; exit 1; }

# Copy the application to the Applications folder
cp -R /Volumes/Webex/Webex.app /Applications || { echo "Failed to copy Webex.app to Applications"; cleanup; exit 1; }

# Unmount the disk image
diskutil unmount /Volumes/Webex || { echo "Failed to unmount disk image"; cleanup; exit 1; }

# Remove the downloaded file
rm -f $DOWNLOAD_PATH || { echo "Failed to remove downloaded file"; cleanup; exit 1; }

# Verify the copied application
codesign -v --verbose /Applications/Webex.app || { echo "Webex.app verification in Applications failed"; cleanup; exit 1; }

echo "Webex installation completed successfully"