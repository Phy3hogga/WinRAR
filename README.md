# WinRAR integration into Matlab

Scripts to compress / decompress archive files using WinRAR 5.0+ programmatically from within Matlab. These scripts are not a replacement for the official WinRAR software as both RAR.m and UNRAR.m call the executable of the official WinRAR client in order to function.

RAR.m supports the creation of RAR file formats, a full feature list of this script is shown below. While this script also happens to work for the creation of ZIP file formats, it is not fully supported and may be less reliable than using the RAR file format. 

RAR.m supports the use of the following features of WinRAR:
* Variable level of compression.
	* Range of 1-5; where 0 corresponds to no compression, 5 corresponds to maximum compression.
* Resizable recovery sector (%).
	* Range of 0-100.
* Password protection.
	* Encryption of filenames.
* Calculation of BLAKE2 hash per-file.
* Archive comments.
* Running as a background (invisible) or foreground (visible) process.

UNRAR.m supports the extraction of multiple compressed file formats including RAR, ZIP and GZ. Additional file formats that WinRAR supports may work, but are untested. The extraction of password protected RAR archives is supported. Advanced features such as repairing damaged archives that have recovery sectors are not, please use the official WinRAR client to do this in the event of a failed extraction due to corruption.

### Prerequisites

Current requirements for running this script are:
* An installed and licenced version of WinRAR (version 5.0 or higher).
* Windows operating system (see the Contributing section below regarding other operating systems).

### Example

Example use of RAR.m and UNRAR.m to create a RAR archive from a directory, then un-compress the archive to another directory. 

```matlab
%% Directories
%Root directory to compress into a RAR archive
RAR_This_Directory = "C:\Users\Username\Desktop\RAR Testing";
%Filename for the created RAR file
Output_RAR_File = "Test.rar";
%Root directory to extract the files from the RAR archive into
Extraction_Directory = "RAR_Output";

%% Parameters to compress/uncompress RAR file with
%Full path to WinRAR.exe, this (may/may not) be needed depending on system enviroment variables
RAR_Parameters.WinRAR_Path = 'C:\Program Files\WinRAR\WinRAR.exe';
%Password to encrypt the archive with (optional, maximum length 125 characters due to WinRAR constraints)
RAR_Parameters.Password = "testpassword";
%If encrypting the filenames in the archive as well as the file contents
RAR_Parameters.Encrypt_Filenames = false;
%Comment to be inserted into to the archive
RAR_Parameters.Comment = "insertcomment";
%If running WinRAR in the background (false = hidden, true = visible)
RAR_Parameters.Silent_Override = false;
%Deletion of the original files (false = retained, true = deleted)
RAR_Parameters.Delete_Files_After_Archive = false;
%Recovery sector size for a RAR archive (0-100)
RAR_Parameters.Recovery_Percent = 25;
%Archive format (will take precidence over other file format specificatons such as in the archive filename)
RAR_Parameters.Archive_Format = "RAR";
%Compression level (0-5) where 0 is uncompressed, 5 is the maximum compression
RAR_Parameters.Compression_Level = 1;
%If overwriting files (true will overwrite any files during extraction of an archive, false will stop extraction and prompt)
RAR_Parameters.Overwrite_Mode = true;

%Compress files to an archive
Success = RAR(Directory_Path_To_RAR, Output_RAR_File, RAR_Parameters);
%Uncompress files from the archive if the original compression was successful
if(Success)
    [Success, Comment] = UNRAR(Output_RAR_File, Extraction_Directory, RAR_Parameters);
end
```

## Linux

Requires the ```rar``` package installed via ```multiverse``` repository to read/write rar archives on linux.

To install the ```rar``` package:
* ```sudo add-apt-repository multiverse```
* ```sudo apt update```
* ```sudo apt-get install rar```

To register the ```rar``` package, copy the ```rarreg.key``` licence file to either:
* ```/etc```
* ```/usr/lib```
* ```/usr/local/lib```
* ```/usr/local/etc```

## Built With

* [Matlab R2018A](https://www.mathworks.com/products/matlab.html)
* [WinRAR 5.0](https://www.rarlab.com/)
* [Windows 10](https://www.microsoft.com/en-gb/software-download/windows10)

## Contributing

Contributions towards this code will only be accepted under the following conditions:
* Enabling support for additional operating systems (must not break any functionality on Windows)
* Provide new features introduced to WinRAR that do not break current implementations (must be backwards compatible).

## Authors

* **Alex Hogg** - *Initial work* - [Phy3hogga](https://github.com/Phy3hogga)