local os = import("os")
local micro = import("micro")
local config = import("micro/config")
local buffer = import("micro/buffer")

-- Global Variables
filemanagerbuffer = nil;
filemanagerbufpane = nil;
currentdirectory = nil;

local function utf8_icon(hex)
    local code = type(hex) == "string" and tonumber(hex, 16) or hex
    if code < 0x80 then
        return string.char(code)
    elseif code < 0x800 then
        return string.char(
            0xC0 + math.floor(code / 0x40),
            0x80 + (code % 0x40)
        )
    elseif code < 0x10000 then
        return string.char(
            0xE0 + math.floor(code / 0x1000),
            0x80 + (math.floor(code / 0x40) % 0x40),
            0x80 + (code % 0x40)
        )
    else
        return string.char(
            0xF0 + math.floor(code / 0x40000),
            0x80 + (math.floor(code / 0x1000) % 0x40),
            0x80 + (math.floor(code / 0x40) % 0x40),
            0x80 + (code % 0x40)
        )
    end
end

-- Icons
folder_icon = utf8_icon('f07b');
file_icon = utf8_icon('f15b');

-- Creates a NewBuffer
local function NewBuffer(name, text)
    return buffer.NewBuffer(text, name);
end

-- List entire directory
local function ScanDirectory(path, maxDepth, currentDepth)
    
    maxDepth = maxDepth or 10
    currentDepth = currentDepth or 0

    if currentDepth > maxDepth then return {} end

    local entries = {}
    local p = io.popen('ls -a "'..path..'"')
    if not p then return entries end

    for entry in p:lines() do
        if entry ~= "." and entry ~= ".." then
            local fullpath = path .. "/" .. entry
            local attr = io.popen('test -d "'..fullpath..'" && echo dir || echo file'):read("*l")

            local item = {
                name = entry,
                path = fullpath,
                type = attr == "dir" and "directory" or "file",
            }

            if item.type == "directory" then
                -- Recursively scan subdirectory
                item.children = ScanDirectory(fullpath, maxDepth, currentDepth + 1)
            end

            table.insert(entries, item)
        end
    end

    p:close()
    return entries
end


-- Display the current Directory to a Buffer Pane
function DisplayDirectoryToBufpane(directorytable, indent, bufpane)
    
    for key, value in pairs(directorytable) do
        local icon = value.type == "directory" and folder_icon or file_icon
        filemanagerbuffer:Write(indent .. icon .. " " .. value.name .. '\n')

        if value.children then
            DisplayDirectoryToBufpane(value.children, indent .. "    ", bufpane)
        end
    end

end

-- Opens the File Manager
function OpenFileManager()

    -- Create the Buffer Pane and the Buffer
    filemanagerbuffer = NewBuffer(" ", "")
    filemanagerbufpane = micro.CurPane():VSplitIndex(filemanagerbuffer, false);
    
    -- Disable writing and saving
    filemanagerbuffer.Type.Readonly = true
    filemanagerbuffer.Type.Scratch = true
    filemanagerbuffer.Type.Kind = 2

    -- Resize File Manager
    filemanagerbufpane:ResizePane(20)

    -- List current Directory in the Buffer Pane
    DisplayDirectoryToBufpane(currentdirectory, "", filemanagerbufpane);

end

-- Clear references when closing File Manager
function HandleOnCloseFileManager()
    filemanagerbufpane = nil
    filemanagerbuffer = nil
end

-- Close the File Manager
function CloseFileManager()
    filemanagerbufpane:Quit()
    filemanagerbuffer:Close()
    HandleOnCloseFileManager();
end

-- Called when running "zune" command
function ToggleFileManager()
        
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

function postinit()
    
    -- Get the Current Directory
    currentdirectory = ScanDirectory(os.Getwd(), 2);

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
