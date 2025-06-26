local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")

local os = import("os")

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
    
    filemanagerbuffer = NewBuffer("filemanagerbuffer", "")
    filemanagerbufpane = micro.CurPane():VSplitIndex(filemanagerbuffer, false);
    micro.Log(ScanDirectory(os.Getwd()));
    
end

function onSetActive(bufpane)

end

function init()
    OpenFileManager();
end
