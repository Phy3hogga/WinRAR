clear all;

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