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
* An installed and licenced version of WinRAR version 5.0 (or higher).
* Windows operating system (see the Contributing section below regarding other operating systems).

### Example

Example use of RAR.m and UNRAR.m to create a RAR archive from a directory, then un-compress the archive to another directory. 

```matlab
RAR_This_Directory = "C:\Users\Username\Desktop\RAR Testing";
Output_RAR_File = "Test.rar";
Extraction_Directory = "RAR_Output";

%Parameters to compress/uncompress RAR file with
RAR_Parameters.WinRAR_Path = 'C:\Program Files\WinRAR\WinRAR.exe';
RAR_Parameters.Password = "testpassword";
RAR_Parameters.Encrypt_Filenames = false;
RAR_Parameters.Comment = "insertcomment";
RAR_Parameters.Silent_Override = false;
RAR_Parameters.Delete_Files_After_Archive = false;
RAR_Parameters.Recovery_Percent = 25;
RAR_Parameters.Archive_Format = "RAR";
RAR_Parameters.Compression_Level = 1;
RAR_Parameters.Overwrite_Mode = true;

%Compress files to an archive
Success = RAR(Directory_Path_To_RAR, Output_RAR_File, RAR_Parameters);
%Uncompress files from the archive if the original compression was successful
if(Success)
    [Success, Comment] = UNRAR(Output_RAR_File, Extraction_Directory, RAR_Parameters);
end
```

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