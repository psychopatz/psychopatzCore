local Typography = {}

local function copyColor(theme, color, alpha)
    color = color or theme.colors.text
    return {
        r = color.r or 1,
        g = color.g or 1,
        b = color.b or 1,
        a = alpha == nil and (color.a or 1) or alpha,
    }
end

function Typography.Install(theme)
    function theme.CopyColor(color, alpha)
        return copyColor(theme, color, alpha)
    end

    function theme.Color(name, alpha)
        return copyColor(theme, theme.colors[name] or theme.colors.text, alpha)
    end

    function theme.Font(scale, emphasis)
        scale = tonumber(scale) or 1
        if emphasis == "title" then
            return scale >= 1.12 and UIFont.Large or UIFont.Medium
        end
        if emphasis == "body" and scale >= 1.15 then
            return UIFont.Medium
        end
        return UIFont.Small
    end

    function theme.FontHeight(font)
        if getTextManager and getTextManager()
            and getTextManager().getFontHeight
        then
            return getTextManager():getFontHeight(font or UIFont.Small)
        end
        return 14
    end

    function theme.TextWidth(font, value)
        if getTextManager and getTextManager()
            and getTextManager().MeasureStringX
        then
            return getTextManager():MeasureStringX(
                font or UIFont.Small, tostring(value or ""))
        end
        return #tostring(value or "") * 7
    end
end

return Typography
