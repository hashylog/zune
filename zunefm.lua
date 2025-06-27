local os = import("os")
local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")

filemanagerbuffer = nil;
filemanagerbufpane = nil;


-- Creates a NewBuffer
local function NewBuffer(name, text)
    return buffer.NewBuffer(text, name);
end

-- List entire directory
local function ScanDirectory(directory)
    local i, t, popen = 0, {}, io.popen
    local pfile = popen('ls -a "'..directory..'"')
    for filename in pfile:lines() do
        i = i + 1
        t[i] = filename
    end
    pfile:close()
    return t
end

function OpenFileManager()
    -- Create 
    filemanagerbuffer = NewBuffer("filemanager", "")
    filemanagerbufpane = micro.CurPane():VSplitIndex(filemanagerbuffer, false);
    
    -- Resize File Manager
    filemanagerbufpane:ResizePane(20)
end

function HandleOnCloseFileManager()
    filemanagerbufpane = nil
    filemanagerbuffer = nil
end

function CloseFileManager()
    filemanagerbufpane:Quit()
    filemanagerbuffer:Close()
    HandleOnCloseFileManager();
end

-- Called when running "zune" command
function ToggleFileManager()
    
    micro.Log("Open!")
    
    if (not filemanagerbufpane) then
        micro.Log("Open!")
        OpenFileManager();
    else
        micro.Log("Close!")
        CloseFileManager();
    end
    
end

function onQuit(bufpane)
    if (bufpane == filemanagerbufpane) then
        HandleOnCloseFileManager();
    end
end

function onSetActive(bufpane)

end

function postinit()
    
    -- Commands for toggling the File Manager
    config.MakeCommand("zune", function(bp) ToggleFileManager() end, config.NoComplete);
    config.MakeCommand("zunefm", function(bp) ToggleFileManager() end, config.NoComplete);
    config.MakeCommand("fm", function(bp) ToggleFileManager() end, config.NoComplete);
    config.MakeCommand("filemanager", function(bp) ToggleFileManager() end, config.NoComplete);
    
    config.MakeCommand("zlog", 
    function(bp) 
        micro.InfoBar():Message(filemanagerbuffer);
    end, 
    config.NoComplete);

end
