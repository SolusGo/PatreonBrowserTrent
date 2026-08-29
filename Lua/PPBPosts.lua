-- Fictional, offline creator-feed data shared by gameplay and UI contexts.
-- Visible strings are localization keys defined in SQL/10_PPB_Text.sql.

PPB_CLIP_MORE = "MORE"
PPB_CLIP_THEORY = "THEORY"
PPB_CLIP_BODY_HOP = "BODY_HOP"
PPB_CLIP_MAIN_HOST = "MAIN_HOST"
PPB_CLIP_LOYAL = "LOYAL"

PPBClipData = {
    MORE = {
        nameKey = "TXT_KEY_PPB_CLIP_MORE",
        helpKey = "TXT_KEY_PPB_CLIP_MORE_HELP",
        icon = "[ICON_PEACE]"
    },
    THEORY = {
        nameKey = "TXT_KEY_PPB_CLIP_THEORY",
        helpKey = "TXT_KEY_PPB_CLIP_THEORY_HELP",
        icon = "[ICON_RESEARCH]"
    },
    BODY_HOP = {
        nameKey = "TXT_KEY_PPB_CLIP_BODY_HOP",
        helpKey = "TXT_KEY_PPB_CLIP_BODY_HOP_HELP",
        icon = "[ICON_MOVES]"
    },
    MAIN_HOST = {
        nameKey = "TXT_KEY_PPB_CLIP_MAIN_HOST",
        helpKey = "TXT_KEY_PPB_CLIP_MAIN_HOST_HELP",
        icon = "[ICON_GREAT_GENERAL]"
    },
    LOYAL = {
        nameKey = "TXT_KEY_PPB_CLIP_LOYAL",
        helpKey = "TXT_KEY_PPB_CLIP_LOYAL_HELP",
        icon = "[ICON_STRENGTH]"
    }
}

local function Choice(clipType, suffix)
    return {
        clipType = clipType,
        labelKey = "TXT_KEY_PPB_COMMENT_" .. suffix .. "_LABEL",
        quoteKey = "TXT_KEY_PPB_COMMENT_" .. suffix .. "_QUOTE"
    }
end

PPBPosts = {
    {
        titleKey = "TXT_KEY_PPB_POST_01_TITLE",
        textKey = "TXT_KEY_PPB_POST_01_TEXT",
        likes = 81, comments = 9,
        choices = {
            Choice(PPB_CLIP_MORE, "MORE_01"),
            Choice(PPB_CLIP_THEORY, "THEORY_01"),
            Choice(PPB_CLIP_LOYAL, "LOYAL_01")
        }
    },
    {
        titleKey = "TXT_KEY_PPB_POST_02_TITLE",
        textKey = "TXT_KEY_PPB_POST_02_TEXT",
        likes = 104, comments = 13,
        choices = {
            Choice(PPB_CLIP_MORE, "MORE_02"),
            Choice(PPB_CLIP_THEORY, "THEORY_02"),
            Choice(PPB_CLIP_BODY_HOP, "HOP_01")
        }
    },
    {
        titleKey = "TXT_KEY_PPB_POST_03_TITLE",
        textKey = "TXT_KEY_PPB_POST_03_TEXT",
        likes = 126, comments = 14,
        choices = {
            Choice(PPB_CLIP_MORE, "MORE_03"),
            Choice(PPB_CLIP_THEORY, "THEORY_03"),
            Choice(PPB_CLIP_MAIN_HOST, "MAIN_01")
        }
    },
    {
        titleKey = "TXT_KEY_PPB_POST_04_TITLE",
        textKey = "TXT_KEY_PPB_POST_04_TEXT",
        likes = 143, comments = 18,
        choices = {
            Choice(PPB_CLIP_MORE, "MORE_04"),
            Choice(PPB_CLIP_MAIN_HOST, "MAIN_02"),
            Choice(PPB_CLIP_LOYAL, "LOYAL_02")
        }
    },
    {
        titleKey = "TXT_KEY_PPB_POST_05_TITLE",
        textKey = "TXT_KEY_PPB_POST_05_TEXT",
        likes = 97, comments = 11,
        choices = {
            Choice(PPB_CLIP_BODY_HOP, "HOP_02"),
            Choice(PPB_CLIP_THEORY, "THEORY_04"),
            Choice(PPB_CLIP_MORE, "MORE_05")
        }
    },
    {
        titleKey = "TXT_KEY_PPB_POST_06_TITLE",
        textKey = "TXT_KEY_PPB_POST_06_TEXT",
        likes = 119, comments = 16,
        choices = {
            Choice(PPB_CLIP_THEORY, "THEORY_05"),
            Choice(PPB_CLIP_BODY_HOP, "HOP_03"),
            Choice(PPB_CLIP_MAIN_HOST, "MAIN_03")
        }
    },
    {
        titleKey = "TXT_KEY_PPB_POST_07_TITLE",
        textKey = "TXT_KEY_PPB_POST_07_TEXT",
        negativeKey = "TXT_KEY_PPB_POST_07_NEGATIVE",
        likes = 88, comments = 22,
        choices = {
            Choice(PPB_CLIP_LOYAL, "LOYAL_03"),
            Choice(PPB_CLIP_MORE, "MORE_06"),
            Choice(PPB_CLIP_THEORY, "THEORY_06")
        }
    },
    {
        titleKey = "TXT_KEY_PPB_POST_08_TITLE",
        textKey = "TXT_KEY_PPB_POST_08_TEXT",
        likes = 131, comments = 17,
        choices = {
            Choice(PPB_CLIP_MAIN_HOST, "MAIN_04"),
            Choice(PPB_CLIP_BODY_HOP, "HOP_04"),
            Choice(PPB_CLIP_MORE, "MORE_07")
        }
    },
    {
        titleKey = "TXT_KEY_PPB_POST_09_TITLE",
        textKey = "TXT_KEY_PPB_POST_09_TEXT",
        likes = 76, comments = 8,
        choices = {
            Choice(PPB_CLIP_THEORY, "THEORY_07"),
            Choice(PPB_CLIP_MAIN_HOST, "MAIN_05"),
            Choice(PPB_CLIP_LOYAL, "LOYAL_04")
        }
    },
    {
        titleKey = "TXT_KEY_PPB_POST_10_TITLE",
        textKey = "TXT_KEY_PPB_POST_10_TEXT",
        likes = 155, comments = 24,
        choices = {
            Choice(PPB_CLIP_MORE, "MORE_08"),
            Choice(PPB_CLIP_BODY_HOP, "HOP_05"),
            Choice(PPB_CLIP_LOYAL, "LOYAL_05")
        }
    },
    {
        titleKey = "TXT_KEY_PPB_POST_11_TITLE",
        textKey = "TXT_KEY_PPB_POST_11_TEXT",
        likes = 169, comments = 27,
        choices = {
            Choice(PPB_CLIP_MAIN_HOST, "MAIN_06"),
            Choice(PPB_CLIP_THEORY, "THEORY_08"),
            Choice(PPB_CLIP_MORE, "MORE_09")
        }
    },
    {
        titleKey = "TXT_KEY_PPB_POST_12_TITLE",
        textKey = "TXT_KEY_PPB_POST_12_TEXT",
        negativeKey = "TXT_KEY_PPB_POST_12_NEGATIVE",
        likes = 201, comments = 31,
        choices = {
            Choice(PPB_CLIP_MAIN_HOST, "MAIN_07"),
            Choice(PPB_CLIP_BODY_HOP, "HOP_06"),
            Choice(PPB_CLIP_LOYAL, "LOYAL_06")
        }
    }
}

function PPB_GetPostTemplate(templateID)
    return PPBPosts[tonumber(templateID) or 0]
end

function PPB_GetClipData(clipType)
    return PPBClipData[tostring(clipType or "")]
end
