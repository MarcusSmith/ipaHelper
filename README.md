# ipaHelper #
==========

Tools and script for examining and resigning ipa files

## Installation ##

To install, double click `ipaHelperInstall.app` and enter your system password.

`ipaHelperInstall.app` copies: 

- `ipaHelper` Bash script into */usr/bin/*  
- man page for `ipaHelper` into */usr/share/man/man1/*  
- `ipaHelper.qlgenerator` QuickLook plugin into *~/Library/Quicklook/*
- `Resign.workflow` resign Automator service into *~/Library/Services/* 

You may need to restart your computer for the QuickLook plugin and Automator service to work

## QuickLook Plugin ##

The `ipaHelper.qlgenerator` QuickLook plugin uses the `ipaHelper` script to quickly display a summary of relevant information for:

- ipa files
- app files
- xcarchive files
- zip files containing an app file one level deep
- provisioning profiles

When in finder with a file of one of these file types selected just hit spacebar to display the QuickLook summary.

## Resign Automator Service ##

The Resign service uses the `ipaHelper` script to resign the following file types:

- ipa files
- app files
- xcarchive files
- zip files containing an app file one level deep

To use the Resign service, right click a **file** of one of these file types and select **"Resign with..."** from the service menu.  Then select a **provisioning profile** to resign the **file** with.

The Resign service uses the following `ipaHelper` command:

	ipaHelper resign [file] --force -p [provisioning profile] 2>&1
	
Using the --force option, the Resign service will force match the **file**'s bundle ID to the **profile**'s App ID.

The resigned file will be named *filename*-resigned.*filetype*,for example:

**MyApp.ipa** would be resigned as **MyApp-resigned.ipa**

xcarchive files will only be resigned as app files, for example:

**MyXCArchive.xcarchive** would be resigned as **MyXCArchive-resigned.app**

## ipaHelper Script ##

### BASIC USAGE ###

#### Get a summary of a file ####

	$ ipaHelper summary /path/to/the/file.ipa

The **Summary** command works for .app, .ipa, .xcarchive, .mobileprovision, and .zip files (if the .zip file has an .app file one level deep)

#### Resign an app with a profile ####


	$ ipaHelper resign [theApp] -p [theProfile]

The **resign** command works on .app, .ipa, .xcarchive, and .zip files (if the .zip file has an .app file one level deep)

The **p** option is not necessary if there is only one provisioning profile in the same directory as the app.

#### Resign an app with a profile in your library that matches the app's bundle ID ####

	$ ipaHelper resign [theApp] --find --double-check

The **double-check** option is not necessary, but it is a good idea to double check that the profile found by the **find** option is the one you want.

#### Resign an app with a profile in your library matching the app and other criteria ####

	$ ipaHelper resign [theApp] --find --matching [criteria1] [criteria2] --double-check

The **matching** command could be used to specify "distribution" to make sure it is not matched to a development profile.  Or a specific name of a profile, if there are several matching the same bundle ID.


### USAGE ###
  
**ipaHelper profile \[** *file* **\] \[** *options* **\]**  
**ipaHelper find \[** *file* **\] \[** *options* **\]**  
**ipaHelper info \[** *file* **\] \[** *options* **\]**  
**ipaHelper summary \[** *file* **\]**  
**ipaHelper clean \[** *file* **\] \[** *--all* **\]**  
**ipaHelper rezip \[** *outputfile* **\]**  
**ipaHelper verify \[** *file* **\]**  
**ipaHelper resign \[** *file* **\] \[** *options* **\]**     
**ipaHelper help \[** *-v* **\] \[** *commands* **\]**

### DESCRIPTION ###
       

#### PROFILE ####

**ipaHelper profile \[** *file* **\] \[** *options* **\]**

Checks the profile of an ipa, app, xcarchive, or zip *file* containing an app file, or shows the information about a mobileprovision *file*
If no *file* is provided, the first (alphabetically) ipa file in the working directory is used. If no options are present, a summary of the provisioning profile is displayed.

**Profile Options**

**-v, --verbose**  
display the entire profile in xml format

**-e, --entitlements**  
display the entitlements on the profile

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

**ipaHelper clean \[** *file* **\] \[** *--all* **\]**

Cleans temporary files left over from Summary command with the --dont-clean option. If run with the --all option, the entire temp folder for ipaHelper is deleted. If *file* is supplied, the folder associated with that file is deleted. When run with no arguments or options, the folder associated with the first (alphabetically) ipa file in the working directory is deleted.

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

**-F, --force**  
overwrite output file on resign without asking.  Uses the profiles App ID if the App ID and Bundle ID do not match.


#### HELP ####

**ipaHelper help \[** -v **\] \[** *commands...*  **\]**

Displays usage information for the commands.

If *-v* option is present it shows the usage information for all of the commands.

### AUTHOR ###

Marcus Smith
