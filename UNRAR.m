%% Uncompress RAR / ZIP archive
%Archive Path (string) - absolute or relative path to RAR / ZIP archive
%Extraction Directory (string) - absolute or relative path to uncompress the archive to
%RAR_Parameters(structure) - options for uncompressing the archive
% - WinRAR_Path (string) - absolute path to WinRAR.exe if not found
% - Silent_Override (boolean) - Run in foreground or background (default)
% - Overwrite_Mode (boolean) - Overwrite (true), don't overwrite (false), ask (default)
% - Password (string) - Archive Password
function [Success, Comment] = UNRAR(Archive_Path, Extraction_Directory, RAR_Parameters)
    %% Get input parameters, dynamically build winrar command
    RAR_Command = '"';
    %% Path to WinRAR EXE
    if(nargin < 2)
        error('Error: Insufficient Input, expected a minimum of two inputs');
    elseif(nargin == 2)
        %% Default optional arguments
        RAR_Utility_Path = Get_RAR_Utility_Path();
        Comment = "";
        Overwrite_Mode = " -o";
        RAR_Command_Password = "";
        Rar_Command_Silent_Override = false;
    elseif(nargin == 3)
        %% handle optional arguments
        %Change winrar path
        [Struct_Var_Value, Struct_Var_Valid, Struct_Default_Used] = Verify_Structure_Input(RAR_Parameters, 'WinRAR_Path', '');
        if(Struct_Var_Valid)
            if(Struct_Default_Used)
                RAR_Utility_Path = Get_RAR_Utility_Path();
            else
                RAR_Utility_Path = Struct_Var_Value;
            end
        else
            RAR_Utility_Path = Get_RAR_Utility_Path();
        end
        
        %% Run WinRAR in the Background or not (default = background process)
        [Struct_Var_Value, Struct_Var_Valid, ~] = Verify_Structure_Input(RAR_Parameters, 'Silent_Override', false);
        if(Struct_Var_Valid)
            Rar_Command_Silent_Override = Struct_Var_Value;
        else
            Rar_Command_Silent_Override = false;
        end
        
        %% Encryption using password for archive
        [Struct_Var_Value, Struct_Var_Valid, ~] = Verify_Structure_Input(RAR_Parameters, 'Password', "");
        if(Struct_Var_Valid)
            Password = Struct_Var_Value;
            if(strlength(Password) >= 125)
                disp("Warning: Password string length restricted to 125 characters, archive will not be protected by password");
                RAR_Command_Password = "";
            else
                [Struct_Var_Value, Struct_Var_Valid, ~] = Verify_Structure_Input(RAR_Parameters, 'Encrypt_Filenames ', true);
                if(Struct_Var_Valid)
                    Encrypt_Filenames  = Struct_Var_Value;
                    if(Encrypt_Filenames)
                        %encrypts filenames and file contents in archive
                        RAR_Command_Password = strcat(" -hp", Password);
                    else
                        %encrypts file contents only
                        RAR_Command_Password = strcat(" -p", Password);
                    end
                else
                    %encrypts file contents only
                    RAR_Command_Password = strcat(" -p", Password);
                end
            end
        else
            RAR_Command_Password = "";
        end
        
        %% If overwriting files automatically or not
        [Struct_Var_Value, Struct_Var_Valid, Struct_Default_Used] = Verify_Structure_Input(RAR_Parameters, 'Overwrite_Mode', false);
        if(Struct_Var_Valid)
            if(Struct_Default_Used)
                Overwrite_Mode = " -o";
            else
                if(true(Struct_Var_Value))
                    Overwrite_Mode = " -o+";
                else
                    Overwrite_Mode = " -o-";
                end
            end
        else
            Overwrite_Mode = " -o";
        end
    else
        error('RAR : Unexpected Input');
    end
    
    %% Read comment in archive (seperate to extraction)
    Temporary_Comment_Filename = strcat('Temp_Comment_File-', num2str(now), '.txt');
    try
        Comment_Read_Command = strcat('"', RAR_Utility_Path, '" cw "', Archive_Path, '"', ' "', Temporary_Comment_Filename, '"');
        system(Comment_Read_Command);
        Comment = fileread(Temporary_Comment_Filename);
    catch
        Comment = "";
    end
    %Remove the temporary file containing the RAR file comment
    if(isfile(Temporary_Comment_Filename))
        try
            delete(Temporary_Comment_Filename);
        catch
            disp(strcat("Error deleting temporary file for adding the ZIP comment: ", Temporary_Comment_Filename));
        end
    end
    
    %% Optional argument addition to system command call
    %Winrar path change
    RAR_Command = strcat(RAR_Command, RAR_Utility_Path, '"');
    %Silent unpacking of files
    if(~Rar_Command_Silent_Override)
        RAR_Command = strcat(RAR_Command, " -IBCK");
    end
    
    %Password protection of archive
    RAR_Command = strcat(RAR_Command, RAR_Command_Password);
    
    %Overwrite or not
    RAR_Command = strcat(RAR_Command, Overwrite_Mode);
    
    %% EXTRACTION
    if(~isfolder(Extraction_Directory))
        try
            mkdir(Extraction_Directory);
        catch
            error(strcat("RAR : Error creating extraction directory path: ", Extraction_Directory));
        end
    end
    RAR_Command = strcat(RAR_Command, " x ", '"', Archive_Path, '" "', Extraction_Directory, '"');
    Extraction_Unsuccessful = system(RAR_Command);
    if(~Extraction_Unsuccessful)
        Success = true;
    else
        Success = false;
    end
end

%% Verifies WinRAR software / RAR repository is installed
function RAR_Utility_Path = Get_RAR_Utility_Path()
    RAR_Utility_Path = "";
    %% Windows
    if(ispc)
        %% Attempt to read WinRAR installation path from Windows Registry
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
            error("RAR : Can't verify that the WinRAR is installed");
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
        RAR_Utility_Path = "TERM=ansi; rar";
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
        RAR_Utility_Path = "TERM=ansi; rar";
    else
        error("RAR : Unable to determine system operating system for automatic selection");
    end
    RAR_Utility_Path = char(RAR_Utility_Path);
end