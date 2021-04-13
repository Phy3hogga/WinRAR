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
    %% Supported file prefixes
    Allowed_File_Extensions = ["RAR", "ZIP"];
    
    %% Default values
    Encrypt_Files = false;
    Encrypt_Filenames = false;
    Password = "";
    Silent_Override = false;
    Recovery_Percentage = 25;
    Compression_Level = 5;
    %Overwrite_Mode = " -o";
    Delete_Files = false;
    
    %Filename for comment (no switch currently exists directly to file)
    Temporary_Comment_Filename = strcat('Temp_Comment_File-', num2str(now), '.txt');
    
    %Parts of Output archive filepath
    [Output_File_Path, Output_File_Filename, Output_File_Extension] = fileparts(Output_Archive_File);
    Output_File_Path_Empty = isempty(Output_File_Path) || (isstring(Output_File_Path) && length(Output_File_Path) == 1 && strlength(Output_File_Path)==0);
    %Set archive type by teh file extension
    File_Extension_Match = strcmp(Output_File_Extension, Allowed_File_Extensions);
    if(any(File_Extension_Match))
        Archive_Format = Allowed_File_Extensions(File_Extension_Match);
    else
        Archive_Format = "RAR";
    end
    %% Input Handling
    if(nargin < 2)
        error("RAR : Insufficient input arguments");
    elseif(nargin == 2)
        %% Default optional arguments
        warning("RAR : Using default optional arguments supplied in RAR_Parameters structure.");
        RAR_Utility_Path = Get_RAR_Utility_Path();
    elseif(nargin == 3)
        %% Get input parameters, dynamically build winrar command
        % Path to WinRAR / RAR package
        [Struct_Var_Value, Struct_Var_Valid, Struct_Default_Used] = Verify_Structure_Input(RAR_Parameters, 'WinRAR_Path', "");
        if(Struct_Var_Valid)
            if(Struct_Default_Used)
                RAR_Utility_Path = Get_RAR_Utility_Path();
            else
                RAR_Utility_Path = Struct_Var_Value;
                %Escape directory path on PC
                if(ispc)
                    RAR_Utility_Path = strcat('"', RAR_Utility_Path, '"');
                end
            end
        else
            RAR_Utility_Path = Get_RAR_Utility_Path();
        end
        
        % Run WinRAR in the Background or not (default = background process)
        [Struct_Var_Value, Struct_Var_Valid, ~] = Verify_Structure_Input(RAR_Parameters, 'Silent_Override', false);
        if(Struct_Var_Valid)
            Silent_Override = Struct_Var_Value;
        else
            Silent_Override = false;
        end
        
        %% Archive format (defaults to file type in the RAR_Parameters Archive_Format field. Uses filename extension to verify if it exists or if Archive_Format is unset.
        Output_File_Extension_Empty = isempty(Output_File_Extension) || (isstring(Output_File_Extension) && length(Output_File_Extension) == 1 && strlength(Output_File_Extension)==0);
        [Struct_Var_Value, Struct_Var_Valid, Struct_Default_Used] = Verify_Structure_Input(RAR_Parameters, 'Archive_Format', "RAR", Allowed_File_Extensions);
        if(Struct_Var_Valid)
            %Archive_Format supplied, use as default
            if(Struct_Default_Used)
                %if blank
                Archive_Format = "RAR";
                disp("RAR : Defaulting to RAR archive");
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
        
        % Encryption using password for archive
        [Struct_Var_Value, Struct_Var_Valid, Struct_Default_Used] = Verify_Structure_Input(RAR_Parameters, 'Password', "");
        if(Struct_Var_Valid && ~Struct_Default_Used)
            Password = Struct_Var_Value;
            if(strlength(Password) >= 125)
                warning("RAR : Password string length restricted to 125 characters, archive will not be protected by password");
            else
                % Password is within length constraints
                Encrypt_Files = true;
                % Check if encrypting filenames
                [Struct_Var_Value, Struct_Var_Valid, ~] = Verify_Structure_Input(RAR_Parameters, 'Encrypt_Filenames ', true);
                if(Struct_Var_Valid)
                    Encrypt_Filenames  = Struct_Var_Value;
                end
            end
        end
        
        % Comment in archive
        [Struct_Var_Value, Struct_Var_Valid, ~] = Verify_Structure_Input(RAR_Parameters, 'Comment', "");
        if(Struct_Var_Valid)
            Comment = Struct_Var_Value;
            try
                fid = fopen(Temporary_Comment_Filename, 'wt');
                if(isfile(Temporary_Comment_Filename))
                    fprintf(fid, '%s\n', Comment);
                end
                fclose(fid);
            catch
                warning("RAR : Error generating temporary file for comment; no comment added");
            end
        end
        
        % Recovery Partition of file (varying size - default 25%)
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
        
        % Compression Level
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
        
        % Delete files being archived after they are successfully added to the archive (default: no deletion)
        [Struct_Var_Value, Struct_Var_Valid, ~] = Verify_Structure_Input(RAR_Parameters, 'Delete_Files_After_Archive', false);
        if(Struct_Var_Valid)
            Delete_Files = Struct_Var_Value;
        else
            Delete_Files = false;
        end
    else
        error('RAR : Unexpected Input');
    end
    
    %% Compile system command
    %Call relevent RAR utility (based on operating system)
    RAR_Command = Escape_File_Path_String(RAR_Utility_Path, true);
    
    %Only add file seperator if required (absolute file paths)
    if(~Output_File_Path_Empty)
        Output_File_Path = strcat(Output_File_Path, filesep);
    end
    Archive_File = strcat(Output_File_Path, Output_File_Filename, ".", lower(Archive_Format));
    %Archive format only specified on PC
    RAR_Command = strcat(RAR_Command, " a ", '"', Archive_File, '"');
    if(ispc)
        RAR_Command = strcat(RAR_Command, " -af", Archive_Format);
    end
    
    % Password protection
    if(Encrypt_Files)
        if(Encrypt_Filenames)
            %encrypts filenames and file contents in archive
            RAR_Command = strcat(RAR_Command, " -hp", Password);
        else
            %encrypts file contents only
            RAR_Command = strcat(RAR_Command, " -p", Password);
        end
    end
    % Comment in archive
    if(isfile(Temporary_Comment_Filename))
        RAR_Command = strcat(RAR_Command, " -z", Temporary_Comment_Filename);
    end
    % Recovery partition
    RAR_Command = strcat(RAR_Command, " -rr", num2str(Recovery_Percentage), "p");
    % Compression Level
    RAR_Command = strcat(RAR_Command, " -m", num2str(Compression_Level));
    % Delete files being archived after they are successfully added to the archive (default: no deletion)
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
    RAR_Command = strcat(RAR_Command, " -t  -ma -htb -ed -ep1 -r ", '"', Directory_Path_To_RAR, filesep, '*"');
    
    %% Suppression of output / gui.
    if(~Silent_Override)
        if(ispc)
            RAR_Command = strcat(RAR_Command, " -IBCK");
        elseif(isunix)
            RAR_Command = strcat(RAR_Command, " >/dev/null");
        else
            warning("RAR : Suppression may not work as indended, unknown operating system.");
            RAR_Command = strcat(RAR_Command, " >/dev/null");
        end
    end
    %% Creation of the archive
    [Zip_File_Creation_Unsuccessful, ~] = system(RAR_Command);
    
    %% If the temporary comment file exists, remove the file after creating the archive
    if(isfile(Temporary_Comment_Filename))
        try
            delete(Temporary_Comment_Filename);
        catch
            warning(strcat("RAR : Error deleting temporary file for adding the ZIP comment: ", Temporary_Comment_Filename));
        end
    end

    %% Display message on failure to zip files
    if(~Zip_File_Creation_Unsuccessful)
        Success = true;
        %Verify output file exists
        if(~isfile(Archive_File))
            Success = false;
            warning("RAR : Archive file not found. Compression may have failed.");
        end
    else
        Success = false;
        warning("RAR: Archive Compression Failure");
    end
end

%% Verifies WinRAR software / RAR repository is installed
function RAR_Utility_Path = Get_RAR_Utility_Path()
    RAR_Utility_Path = "";
    %% Windows
    if(ispc)
        %% Attempt to read WinRAR installation path from Windows Registry
        %Default Install Path
        try
            Registry_Keys = winqueryreg('name', 'HKEY_LOCAL_MACHINE', 'SOFTWARE\WinRAR');
        catch
            Registry_Keys = {};
        end
        if(~isempty(Registry_Keys))
            for Current_Registry_Key_Index = 1:length(Registry_Keys)
                try
                    Current_Registry_Key = regexp(winqueryreg('HKEY_LOCAL_MACHINE','SOFTWARE\WinRAR', Registry_Keys{Current_Registry_Key_Index}), '^[a-zA-Z]:\\(((?![<>:"/\\|?*]).)+((?<![ .])\\)?)*$', 'match');
                    if(isfile(Current_Registry_Key))
                        RAR_Utility_Path = char(Current_Registry_Key);
                    end
                catch
                end
            end
        end
        if(isempty(RAR_Utility_Path))
            %Installed Software Registry
            try
                Registry_Keys = winqueryreg('name', 'HKEY_LOCAL_MACHINE', 'SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe');
            catch
                Registry_Keys = {};
            end
            if(~isempty(Registry_Keys))
                for Current_Registry_Key_Index = 1:length(Registry_Keys)
                    try
                        Current_Registry_Key = regexp(winqueryreg('HKEY_LOCAL_MACHINE','SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\WinRAR.exe', Registry_Keys{Current_Registry_Key_Index}), '^[a-zA-Z]:\\(((?![<>:"/\\|?*]).)+((?<![ .])\\)?)*$', 'match');
                        if(isfile(Current_Registry_Key))
                            RAR_Utility_Path = char(Current_Registry_Key);
                        end
                    catch
                    end
                end
            end
        end
        if(isempty(RAR_Utility_Path))
            error("RAR : Can't verify that the WinRAR is installed.");
            RAR_Utility_Path = "WinRAR.exe";
        end
    %% UNIX; check RAR repository is installed
    elseif(isunix)
        % verify RAR repository is installed
        [Status, CMD_Out] = system("TERM=ansi; dpkg-query --showformat='${Version}' --show rar");
        if(Status || isempty(CMD_Out))
            [Status, CMD_Out] = system("TERM=ansi; dpkg -s rar | grep '^Version:'");
        end
        if(Status || isempty(CMD_Out))
            error("RAR : Can't verify that the RAR package is installed");
        end
        RAR_Utility_Path = 'TERM=ansi; rar';
    %% MAC; treat as unix (unsupported)
    elseif(ismac)
        warning("RAR : Mac is currently unsupported, attempting to use unix implementation.");
        [Status, CMD_Out] = system("TERM=ansi; dpkg-query --showformat='${Version}' --show rar");
        if(Status || isempty(CMD_Out))
            [Status, CMD_Out] = system("TERM=ansi; dpkg -s rar | grep '^Version:'");
        end
        if(Status || isempty(CMD_Out))
            error("RAR : Can't verify that the RAR package is installed");
        end
        RAR_Utility_Path = 'TERM=ansi; rar';
    else
        error("RAR : Unable to determine system operating system for automatic selection");
    end
    %Ensure the output is a character array
    RAR_Utility_Path = char(RAR_Utility_Path);
end