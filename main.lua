function love.load()
    love.window.setTitle("Love2D Terminal by ElliNet13")
    love.window.setMode(800, 600, {
        resizable = true
    })

    terminal = Terminal:new()
    setupKeyboard()

    cursorTimer = 0
    cursorVisible = true
    cursorBlinkInterval = 0.5  -- Blink interval in seconds
end

function love.update(dt)
    cursorTimer = cursorTimer + dt
    if cursorTimer >= cursorBlinkInterval then
        cursorTimer = cursorTimer - cursorBlinkInterval
        cursorVisible = not cursorVisible  -- Toggle cursor visibility
    end
end

function love.draw()
    love.graphics.clear(0.2, 0.2, 0.2)  -- Background color

    terminal:draw()
    drawKeyboard()

    -- Draw cursor if visible
    if cursorVisible and terminal.inputting then
        local inputLine = "> " .. terminal.input
        local cursorX = 10 + love.graphics.getFont():getWidth(inputLine)
        love.graphics.line(cursorX, 455, cursorX, 475)
    end
end

function love.keypressed(key)
    if key == "return" then
        -- Process the current input as a command
        terminal:processInput()
    elseif key == "backspace" then
        -- Remove the last character from input
        terminal:removeLastCharacter()
    end
end

function love.textinput(text)
    -- Append typed characters to the input string
    terminal:textinput(text)
end

function love.mousepressed(x, y, button)
    checkKeyboardClicks(x, y)
end

-- Terminal object
Terminal = {}
Terminal.__index = Terminal

function Terminal:new()
    local this = {
        input = "",
        output = {},
        maxLines = 20,  -- Maximum number of lines to keep in the output buffer
        fontSize = 16,
        lineHeight = 20,
        inputting = true,  -- Flag to indicate if input is active
        interactiveMode = true,  -- Flag to enable interactive command output
        commandResult = ""
    }
    return setmetatable(this, Terminal)
end

function Terminal:processInput()
    local trimmedInput = self.input:match("^%s*(.-)%s*$")  -- Trim leading and trailing spaces
    if trimmedInput == "clear" then
        self:clearTerminal()
    elseif trimmedInput ~= "" then
        -- Display current input in output (echo)
        self:addOutput("> " .. self.input)

        -- Execute command and capture output and error
        local success, output, errorOutput = self:executeCommand(trimmedInput)

        -- Display command output or error
        if success then
            self:addOutput(output)
        else
            self:addOutput("Error: " .. errorOutput)
        end
    end

    -- Clear input after processing
    self.input = ""
end

function Terminal:executeCommand(command)
    -- Execute the command using io.popen and capture output and error
    local handle = io.popen(command .. " 2>&1", 'r')  -- Redirect stderr to stdout
    if not handle then
        return false, "", "Failed to execute command."
    end

    local result = handle:read("*a")
    handle:close()

    return true, result, ""
end

function Terminal:removeLastCharacter()
    -- Remove the last character from input
    if #self.input > 0 then
        self.input = string.sub(self.input, 1, -2)
    end
end

function Terminal:textinput(text)
    -- Append typed characters to the input string
    self.input = self.input .. text
end

function Terminal:addOutput(line)
    -- Add a line to the output buffer
    table.insert(self.output, line)

    -- Trim excess lines if necessary
    if #self.output > self.maxLines then
        table.remove(self.output, 1)
    end
end

function Terminal:clearTerminal()
    -- Clear all output lines
    self.output = {}
end

function Terminal:draw()
    love.graphics.setColor(1, 1, 1)  -- Text color (white)
    love.graphics.setFont(love.graphics.newFont(self.fontSize))

    -- Draw all output lines
    local startY = 30
    for i, line in ipairs(self.output) do
        love.graphics.print(line, 10, startY + (i-1) * self.lineHeight)
    end

    -- Draw current input line
    local inputLine = "> " .. self.input
    love.graphics.print(inputLine, 10, 455)

    -- Draw cursor if visible
    if cursorVisible and self.inputting then
        local cursorX = 10 + love.graphics.getFont():getWidth(inputLine)
        love.graphics.line(cursorX, 455, cursorX, 475)
    end
end

-- Onscreen Keyboard
local keyboard = {
    { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" },
    { "q", "w", "e", "r", "t", "y", "u", "i", "o", "p" },
    { "a", "s", "d", "f", "g", "h", "j", "k", "l" },
    { "z", "x", "c", "v", "b", "n", "m", "Go", "Bs" },
    { ">", "<", "/", "\\", "|", "=", "!", "?" },  -- Symbols row
    { " " }  -- Space bar
}
local keyWidth = 30
local keyHeight = 30
local keyPadding = 10
local keyboardX = 10
local keyboardY = 200  -- Adjusted for symbols and space row

function setupKeyboard()
    for row, keys in ipairs(keyboard) do
        for col, key in ipairs(keys) do
            local x = keyboardX + (col - 1) * (keyWidth + keyPadding)
            local y = keyboardY + (row - 1) * (keyHeight + keyPadding)
            keyboard[row][col] = { key = key, x = x, y = y, width = keyWidth, height = keyHeight }
        end
    end
end

function drawKeyboard()
    love.graphics.setColor(0.5, 0.5, 0.5)  -- Keyboard background color
    love.graphics.rectangle("fill", keyboardX - keyPadding, keyboardY - keyPadding, #keyboard[1] * (keyWidth + keyPadding), (#keyboard - 1) * (keyHeight + keyPadding))

    love.graphics.setColor(1, 1, 1)  -- Text color (white)
    love.graphics.setFont(love.graphics.newFont(16))

    for row, keys in ipairs(keyboard) do
        for col, key in ipairs(keys) do
            love.graphics.rectangle("line", key.x, key.y, key.width, key.height)
            love.graphics.printf(key.key, key.x, key.y + key.height / 2 - 8, key.width, "center")
        end
    end
end

function checkKeyboardClicks(mx, my)
    for row, keys in ipairs(keyboard) do
        for col, key in ipairs(keys) do
            if mx >= key.x and mx <= key.x + key.width and my >= key.y and my <= key.y + key.height then
                if key.key == "Go" then
                    terminal:processInput()
                elseif key.key == "Bs" then
                    terminal:removeLastCharacter()
                elseif key.key == " " then
                    love.textinput(" ")
                else
                    love.textinput(key.key)
                end
            end
        end
    end
end