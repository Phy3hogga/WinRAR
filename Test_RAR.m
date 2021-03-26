clear all;

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
%Uncompress files from the archive
if(Success)
    [Success, Comment] = UNRAR(Output_RAR_File, Extraction_Directory, RAR_Parameters);
end