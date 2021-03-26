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
    disp(nargin);
    if(nargin < 2)
        error('Error: Insufficient Input, expected a minimum of two inputs');
    elseif(nargin == 2)
        %% Default optional arguments
        WinRAR_Path = "WinRAR.exe";
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
                WinRAR_Path = "WinRAR.exe";
            else
                WinRAR_Path = Struct_Var_Value;
            end
        else
            WinRAR_Path = "WinRAR.exe";
        end
        
        %% Run WinRAR in the Background or not (default = background process)
        [Struct_Var_Value, Struct_Var_Valid, Struct_Default_Used] = Verify_Structure_Input(RAR_Parameters, 'Silent_Override', false);
        if(Struct_Var_Valid)
            Rar_Command_Silent_Override = Struct_Var_Value;
        else
            Rar_Command_Silent_Override = false;
        end
        
        %% Encryption using password for archive
        [Struct_Var_Value, Struct_Var_Valid, Struct_Default_Used] = Verify_Structure_Input(RAR_Parameters, 'Password', "");
        if(Struct_Var_Valid)
            Password = Struct_Var_Value;
            if(strlength(Password) >= 125)
                disp("Warning: Password string length restricted to 125 characters, archive will not be protected by password");
                RAR_Command_Password = "";
            else
                [Struct_Var_Value, Struct_Var_Valid, Struct_Default_Used] = Verify_Structure_Input(RAR_Parameters, 'Encrypt_Filenames ', true);
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
        error('Error: Unexpected Input');
    end
    
    %% Read comment in archive (seperate to extraction)
    Temporary_Comment_Filename = strcat('Temp_Comment_File-',num2str(now),'.txt');
    try
        Comment_Read_Command = strcat(RAR_Command_Install_Location, ' cw "', Archive_Path, '"', ' "', Temporary_Comment_Filename, '"');
        system(Comment_Read_Command);
        Comment = fileread(Temporary_Comment_Filename);
        delete(Temporary_Comment_Filename);
    catch
        Comment = "";
    end
    
    %% Optional argument addition to system command call
    %Winrar path change
    RAR_Command = strcat(RAR_Command, WinRAR_Path, '"');
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
        mkdir(Extraction_Directory);
    end
    RAR_Command = strcat(RAR_Command, " x ", '"', Archive_Path, '" "', Extraction_Directory, '"');
    Extraction_Unsuccessful = system(RAR_Command);
    if(~Extraction_Unsuccessful)
        Success = true;
    else
        Success = false;
    end
end