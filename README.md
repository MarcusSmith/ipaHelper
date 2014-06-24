ipaHelper
==========

### NAME ###

**ipaHelper** -- script to help with examining and resigning ipa files

### SYNOPSIS ###

**ipaHelper get \[** *mobileprovision files...*  **\]**  
**ipaHelper certs \[** *substring* **\]**  
**ipaHelper profile \[** *file* **\] \[** *options* **\]**  
**ipaHelper find \[** *file* **\] \[** *options* **\]**  
**ipaHelper info \[** *file* **\] \[** *options* **\]**  
**ipaHelper summary \[** *file* **\]**  
**ipaHelper clean**  
**ipaHelper rezip \[** *outputfile* **\]**  
**ipaHelper verify \[** *file* **\]**  
**ipaHelper resign \[** *file* **\] \[** *options* **\]**  
**ipaHelper account \[** *options* **\]**  
**ipaHelper upload \[** *ipa file* **\]**  
**ipaHelper help \[** *-v* **\] \[** *commands* **\]**

### DESCRIPTION ###
       
#### GET ####

**ipaHelper get \[** *mobileprovision files...*  **\]**

Moves *mobileprovision files* into the working directory.
If no profiles are specified, all .mobileprovision files in the Downloads folder are moved.

#### CERTS ####

**ipaHelper certs \[** *substring* **\]**

Displays information on all certificates in the keychain.
If *substring* is provided, only certificates containing this *substring* are displayed.

#### PROFILE ####

**ipaHelper profile \[** *file* **\] \[** *options* **\]**

Checks the profile of an ipa, app, xcarchive, or zip *file* containing an app file, or shows the information about a mobileprovision *file*
If no *file* is provided, the first (alphabetically) ipa file in the working directory is used. If no options are present, a summary of the provisioning profile is displayed.

**Profile Options**

**-v, --verbose**  
display the entire profile in xml format

**-e, --entitlements**  
display the entitlements on the profile

**-k** *key* **, --key** *key*  
return the value for *key* in the profile

**-l, --list**  
list all keys in the profile

**-i, --id**  
display the application identifier

**-c, --certificate**  
display the certificate name

**-t, --team**  
display the team name on the certificate

**-x, --expiration**  
display the expiration date for the profile

#### FIND ####

**ipaHelper find \[** *file* **\] \[** *options* **\]**  

Looks for profiles saved in the users library matching the bundle ID of the ipa, app, xcarchive or zip file  containing  an  app file.

If no file is provided, the first (alphabetically) ipa file in the working directory is used.

**Find Options:**

**-m** *pattern* **, --matching** *pattern*    
only display profiles matching *pattern*

**-n, --no-wildcard**  
only display profiles with exact matches to the bundle ID, and not matching wildcard profiles

**-a, --all**  
display all profiles in the users library.  Ignores --no-wildcard option

**--json**  
return the profile information in a JSON dictionary

#### INFO ####

**ipaHelper info \[** *file* **\] \[** *options* **\]**

Checks the Info.plist of an ipa, app, xcarchive, or zip *file* containing an app file, or shows the information about and Info.plist *file*
If no *file* is provided, the first (alphabetically) ipa file in the working directory is used.
If no options are present, a summary of the Info.plist is displayed.

**Info Options:**

**-e** *editor* **, --edit** *editor*    
edit the Info.plist with *editor*. If no *editor* is provided, the default $EDITOR is used.

**-v, --verbose**  
display the entire Info.plist in xml format

**-k** *key* **, --key** *key*  
return the value for *key* in the Info.plist

**-l, --list**  
list all keys in the Info.plist

**-i, --identifier**  
display the CFBundleIdentifier

#### SUMMARY ####

**ipaHelper summary \[** *file* **\]**

Displays profile and info.plist information about an ipa, app, xcarchive, or zip *file* containing an app file.
If no *file* is provided the first (alphabetically) ipa file in the working directory is used.

**Summary Options:**

**--json**  
return the summary information in a JSON dictionary.  Also adds the a key "AppDirectory" for the temporary unzipped app
        
**-dc, --dont-clean**  
do not remove or zip the temporary app directory after returning summary information

#### CLEAN ####

**ipaHelper clean**

Cleans temporary files left over from Summary command with the --dont-clean option

#### REZIP ####

**ipaHelper rezip \[** *outputfile* **\]**  

Rezips left over temporary files from Summary command with the --dont-clean option as *outputfile*

*Outputfile* must be an app, ipa, or zip file.

#### VERIFY ####

**ipaHelper verify \[** *file* **\]**

Checks to make sure the necessary code signing components are in place for an ipa, app, xcarchive, or zip *file* containing an app file.
If no *file* is provided the first (alphabetically) ipa file in the working directory is used.

#### RESIGN ####

**ipaHelper resign \[** *file* **\] \[** *options* **\]**

Removes  the  code  signature from an ipa, app, xcarchive, or zip *file* containing an app file, and replaces it either with the first profile (alphabetically) in the directory with *file* or a specified profile.
Resigns *file* using the certificate on the profile and entitlements matching the profile, zips the resigned ipa file with the output filename.  If no output filename is provided, \[*filename*\]-resigned.ipa is used.
If no *file* is provided, the first (alphabetically) ipa file in the working directory is used.

**Resign Options:**

**-p profile , --profile profile**  
use profile for resigning the ipa

**-f, --find**  
look for a profile in the user's library matching the *file*'s bundle ID

**-m** *patterns* **, --matching** *patterns*  
restricts the *--find* option to only profiles matching *patterns*  

**-o** *filename* **, --output** *filename*  
resign the ipa file as *filename* instead of \[*ipa filename*\]-resigned.ipa

**-d, --double-check**  
display information about the file, its Info.plist, and the provisioning profile and have be given an option to continue with the resign or quit

**-f, --force**
overwrite output file on resign without asking.  Uses the profiles App ID if the App ID and Bundle ID do not match.

#### ACCOUNT ####

**ipaHelper account \[** *options* **\]**

Displays information about which certificates are linked with which iTunesConnect accounts.

If no options are provided, then all certificates and their linked accounts are displayed.

**Account Options:**

**-g** *certificate* **, --get** *certificate*  
returns the iTunesConnect account linked to *certificate*

**-s** *certificate account* **, --set** *certificate account*  
Links *certificate* to the iTunesConnect *account*

**-r** *certificate* **, --remove** *certificate*  
Removes the link between *certificate* and its iTunesConnect account

#### UPLOAD ####

**ipaHelper upload \[** *ipa file* **\]**

Uploads *ipa file* to iTunesConnect.  Asks for an iTunesConnect username if none is linked to the ipas certificate. Asks for a password for this account.  If no *ipa file* is provided, the first (alphabetically) ipa file in the working directory is used.

#### HELP ####

**ipaHelper help \[** -v **\] \[** *commands...*  **\]**

Displays usage information for the commands.

If *-v* option is present it shows the usage information for all of the commands.

### AUTHOR ###

Marcus Smith
