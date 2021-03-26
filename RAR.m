%% Compress a single directory to a RAR / ZIP archive (ZIP not fully supported)
%Extraction Directory (string) - absolute or relative path to uncompress the archive to
%Archive Path (string) - absolute or relative path to RAR / ZIP archive
%RAR_Parameters(structure) - options for uncompressing the archive
% - WinRAR_Path (string) - absolute path to WinRAR.exe if not found
% - Comment (string) - Comment for archive (default empty)
% - Password (string) - Archive Password
% - Encrypt_Filenames (boolean) - Encrypt filenames (true), don't encrypt filenames (false)
% - Delete_Files_After_Archive (boolean) - delete original files (true), leave original files (false)
% - Archive_Format (string) - RAR (default), ZIP (not fully supported)
% - Compression_Level (integer; range 0-5) - change the level of compression (0 = no compression; 5 = maximum compression - default 5)
% - Recovery_Percent (integer; range 0-100) - percentage recovery portion (25% default)
% - Silent_Override (boolean) - Run in foreground or background (default)
function Success = RAR(Directory_Path_To_RAR, Output_Archive_File, RAR_Parameters)
    Allowed_File_Extensions = ["RAR", "ZIP"];
    %% Get input parameters, dynamically build winrar command
    RAR_Command = '"';
    %% Path to WinRAR EXE
    [Struct_Var_Value, Struct_Var_Valid, Struct_Default_Used] = Verify_Structure_Input(RAR_Parameters, 'WinRAR_Path', "");
    if(Struct_Var_Valid)
        if(Struct_Default_Used)
            WinRAR_Path = "WinRAR.exe";
        else
            WinRAR_Path = Struct_Var_Value;
        end
    else
        WinRAR_Path = "WinRAR.exe";
    end
    RAR_Command = strcat(RAR_Command, WinRAR_Path, '"');
    %% Run WinRAR in the Background or not (default = background process)
    [Struct_Var_Value, Struct_Var_Valid, Struct_Default_Used] = Verify_Structure_Input(RAR_Parameters, 'Silent_Override', false);
    if(Struct_Var_Valid)
        Silent_Override = Struct_Var_Value;
    else
        Silent_Override = false;
    end
    if(~Silent_Override)
        RAR_Command = strcat(RAR_Command, ' -IBCK');
    end
    
    %% Archive format (defaults to file type in the RAR_Parameters Archive_Format field. Uses filename extension to verify if it exists or if Archive_Format is unset.
    [Output_File_Path, Output_File_Filename, Output_File_Extension] = fileparts(Output_Archive_File);
    Output_File_Path_Empty = isempty(Output_File_Path) || (isstring(Output_File_Path) && length(Output_File_Path) == 1 && strlength(Output_File_Path)==0);
    Output_File_Extension_Empty = isempty(Output_File_Extension) || (isstring(Output_File_Extension) && length(Output_File_Extension) == 1 && strlength(Output_File_Extension)==0);
    [Struct_Var_Value, Struct_Var_Valid, Struct_Default_Used] = Verify_Structure_Input(RAR_Parameters, 'Archive_Format', "", Allowed_File_Extensions);
    if(Struct_Var_Valid)
        %Archive_Format supplied, use as default
        if(Struct_Default_Used)
            %if blank
            Archive_Format = "RAR";
        else
            Archive_Format = Struct_Var_Value;
        end
    else
        if(Output_File_Extension_Empty)
            Archive_Format = "RAR";
        else
            File_Extension_Match = strcmp(Output_File_Extension, Allowed_File_Extensions);
            if(any(File_Extension_Match))
                Archive_Format = Allowed_File_Extensions(File_Extension_Match);
            else
                Archive_Format = "RAR";
            end
        end
    end
    %Only add file seperator if required (absolute file paths)
    if(~Output_File_Path_Empty)
        Output_File_Path = strcat(Output_File_Path, filesep);
    end
    Archive_File = strcat(Output_File_Path, Output_File_Filename, ".", lower(Archive_Format));
    RAR_Command = strcat(RAR_Command, " a -af", Archive_Format, ' "', Archive_File, '"');
    
    %% Encryption using password for archive
    [Struct_Var_Value, Struct_Var_Valid, Struct_Default_Used] = Verify_Structure_Input(RAR_Parameters, 'Password', "");
    if(Struct_Var_Valid)
        Password = Struct_Var_Value;
        if(strlength(Password) >= 125)
            disp("Warning: Password string length restricted to 125 characters, archive will not be protected by password");
        else
            [Struct_Var_Value, Struct_Var_Valid, Struct_Default_Used] = Verify_Structure_Input(RAR_Parameters, 'Encrypt_Filenames ', true);
            if(Struct_Var_Valid)
                Encrypt_Filenames  = Struct_Var_Value;
                if(Encrypt_Filenames)
                    %encrypts filenames and file contents in archive
                    RAR_Command = strcat(RAR_Command, " -hp", Password);
                else
                    %encrypts file contents only
                    RAR_Command = strcat(RAR_Command, " -p", Password);
                end
            else
                %encrypts file contents only
                RAR_Command = strcat(RAR_Command, " -p", Password);
            end
        end
    end
    %% Comment in archive
    [Struct_Var_Value, Struct_Var_Valid, ~] = Verify_Structure_Input(RAR_Parameters, 'Comment', "");
    if(Struct_Var_Valid)
        Comment = Struct_Var_Value;
        Temporary_Comment_Filename = strcat('Temp_Comment_File-',num2str(now),'.txt');
        try
        fid = fopen(Temporary_Comment_Filename, 'wt');
        if(isfile(Temporary_Comment_Filename))
            fprintf(fid, '%s\n', Comment);
        end
        fclose(fid);
        RAR_Command = strcat(RAR_Command, " -z", Temporary_Comment_Filename);
        catch
            disp("Error generating file comment; no comment added");
        end
    end
    
    %% Recovery Partition of file (varying size - default 25%)
    [Struct_Var_Value, Struct_Var_Valid, Struct_Default_Used] = Verify_Structure_Input(RAR_Parameters, 'Recovery_Percent', 25);
    if(Struct_Var_Valid)
        if(Struct_Default_Used)
            Recovery_Percentage = 25;
        else
            Recovery_Percentage = uint8(round(Struct_Var_Value));
            if(Recovery_Percentage <= 0)
                Recovery_Percentage = 0;
            elseif(Recovery_Percentage >= 100)
                Recovery_Percentage = 100;
            end
        end
    else
        Recovery_Percentage = 25;
    end
    RAR_Command = strcat(RAR_Command, " -rr", num2str(Recovery_Percentage), "p");
    
    %% Compression Level
    [Struct_Var_Value, Struct_Var_Valid, Struct_Default_Used] = Verify_Structure_Input(RAR_Parameters, 'Compression_Level', 5);
    if(Struct_Var_Valid)
        if(Struct_Default_Used)
            Compression_Level = 5;
        else
            Compression_Level = uint8(round(Struct_Var_Value));
            if(Compression_Level <= 0)
                Compression_Level = 0;
            elseif(Compression_Level >= 5)
                Compression_Level = 5;
            end
        end
    else
        Compression_Level = 5;
    end
    RAR_Command = strcat(RAR_Command, " -m", num2str(Compression_Level));
    
    %% Delete files being archived after they are successfully added to the archive (default: no deletion)
    [Struct_Var_Value, Struct_Var_Valid, ~] = Verify_Structure_Input(RAR_Parameters, 'Delete_Files_After_Archive', false);
    if(Struct_Var_Valid)
        Delete_Files = Struct_Var_Value;
    else
        Delete_Files = false;
    end
    if(Delete_Files)
        RAR_Command = strcat(RAR_Command, " -dr");
    end
    
    %% Common fixed settings
    %-t (test after archiving)
    %-ed (ignore empty directories)
    %-ep1 (ignore the root directory as a directory within the archive)
    %-r (recurse subfolders from root directory)
    %-ma (RAR 5.0 archive)
    %-htc (CRC32 file checksum) - discontinued in favour of BLAKE2 [command switch below]
    %-htb (Use 256 bit BLAKE2 checksum for files)
    RAR_Command = strcat(RAR_Command, " -t  -ma -htb -ed -ep1 -r ", '"', Directory_Path_To_RAR, '\*"');
    %disp(RAR_Command);
    %% Creation of the archive
    Zip_File_Creation_Unsuccessful = system(RAR_Command);
    %% Add a comment to the archive
    if(exist('Comment','var'))
        if(isfile(Temporary_Comment_Filename))
            try
                delete(Temporary_Comment_Filename);
            catch
                disp(strcat("Error deleting temporary file for adding the ZIP comment: ", Temporary_Comment_Filename));
            end
        end
    end

    %% Display message on failure to zip files
    if(Zip_File_Creation_Unsuccessful)
        Success = false;
    else
        Success = true;
    end
    %% VERIFY IF OUTPUT FILE EXISTS
    if(Success == true)
        if(~isfile(Archive_File))
            disp("Warning: Archive file not found. Compression may have failed.");
            Success = false;
        end
    end
    if(Success == true)
        %Successful compression
    else
        disp("Warning: Archive Compression Failure");
    end
end