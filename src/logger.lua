--[[
==================================================================================================
    LOGGER MODULE
    Configurable logging system with namespace support
==================================================================================================
]]

-- Logger storage
_HarnessInternal.loggers = {}
_HarnessInternal.defaultNamespace = "Harness"

--- Internal function to format messages
---@param namespace string The namespace for the log message
---@param message string The message to log
---@param caller string? Optional caller identifier
---@return string formatted The formatted log message
local function formatMessage(namespace, message, caller)
    if not caller then
        return string.format("[%s]: %s", namespace, message)
    end
    return string.format("[%s : %s]: %s", namespace, caller, message)
end

--- Create a new logger instance for a specific namespace
---@param namespace string? The namespace for this logger (defaults to "Harness")
---@return table logger Logger instance with info, warn, error, and debug methods
---@usage local myLogger = HarnessLogger("MyMod")
---@usage myLogger.info("Starting up")
function HarnessLogger(namespace)
    if not namespace or type(namespace) ~= "string" then
        namespace = _HarnessInternal.defaultNamespace
    end
    
    -- Return existing logger if already created
    if _HarnessInternal.loggers[namespace] then
        return _HarnessInternal.loggers[namespace]
    end
    
    local logger = {
        namespace = namespace
    }
    
    --- Log an info message
    ---@param message string The message to log
    ---@param caller string? Optional caller identifier
    function logger.info(message, caller)
        env.info(formatMessage(namespace, message, caller))
    end
    
    --- Log a warning message
    ---@param message string The message to log
    ---@param caller string? Optional caller identifier
    function logger.warn(message, caller)
        env.warning(formatMessage(namespace, message, caller))
    end
    
    --- Log an error message
    ---@param message string The message to log
    ---@param caller string? Optional caller identifier
    function logger.error(message, caller)
        env.error(formatMessage(namespace, message, caller))
    end
    
    --- Log a debug message
    ---@param message string The message to log
    ---@param caller string? Optional caller identifier
    function logger.debug(message, caller)
        env.info(formatMessage(namespace .. " : DEBUG", message, caller))
    end
    
    _HarnessInternal.loggers[namespace] = logger
    return logger
end

-- Create internal logger for Harness use
_HarnessInternal.log = HarnessLogger("Harness")

-- Create global Log object that can be configured with a namespace
-- Projects should call: Log = HarnessLogger("MyProject")
-- Or if they just use Log without configuration, it defaults to "Script"
Log = HarnessLogger("Script")