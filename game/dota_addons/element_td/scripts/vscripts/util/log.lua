LOG_LEVEL = 0;
LOG_FILE = nil;

TRACE = 1;
DEBUG = 2;
INFO = 3;
WARN = 4;
ERROR = 5;

Log = {};

function Log:SetLogLevel(level)
    LOG_LEVEL = level;
end

function Log:trace(msg)
    Log:log("[TRACE] " .. msg, TRACE);
end

function Log:debug(msg)
    Log:log("[DEBUG] " .. msg, DEBUG);
end

function Log:info(msg)
    Log:log("[INFO] " .. msg, INFO);
end

function Log:warn(msg)
    Log:log("[WARNING!] " .. msg, WARN);
end

function Log:error(msg)
    Log:log("[ERROR!] " .. msg, ERROR);
end

function Log:log(msg, level)
    if level >= LOG_LEVEL then
        print(msg);
    end
end