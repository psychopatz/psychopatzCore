-- Modular, data-driven English NLP helper for PsychopatzCore Semantics.
-- Provides shorthand/contraction expansion, elongation collapse, lightweight
-- lemmatization, filler stripping, tone detection, and phonetic skeleton keys.
-- Pure Lua 5.1 / Kahlua2-safe; future language packs plug into NLP.Packs[lang].

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local NLP = Semantics.EnglishNLP or {}
Semantics.EnglishNLP = NLP

NLP.VERSION = 1
NLP.Packs = NLP.Packs or {}

NLP.Packs.EN = {
    shorthand = {
        -- Gaming / chat shorthand (including <4-char tokens fuzzy matcher skips)
        u = { "you" },
        ur = { "your" },
        ya = { "you" },
        yall = { "you", "all" },
        ["y'all"] = { "you", "all" },
        r = { "are" },
        y = { "why" },
        k = { "okay" },
        kk = { "okay" },
        ok = { "okay" },
        oki = { "okay" },
        okey = { "okay" },
        okie = { "okay" },
        aight = { "alright" },
        ight = { "alright" },
        alr = { "alright" },
        pls = { "please" },
        plz = { "please" },
        thx = { "thanks" },
        ty = { "thanks" },
        tyvm = { "thanks" },
        tysm = { "thanks" },
        sry = { "sorry" },
        srry = { "sorry" },
        mb = { "sorry" },
        idk = { "i", "do", "not", "know" },
        gimme = { "give", "me" },
        lemme = { "let", "me" },
        wanna = { "want", "to" },
        gonna = { "going", "to" },
        gotta = { "have", "to" },
        outta = { "out", "of" },
        tryna = { "trying", "to" },
        kinda = { "kind", "of" },
        sorta = { "sort", "of" },
        prolly = { "probably" },
        imma = { "i", "am", "going", "to" },
        dunno = { "do", "not", "know" },
        cmon = { "come", "on" },
        cmere = { "come", "here" },
        lets = { "let's" },
        goo = { "go" },
        noo = { "no" },
        yess = { "yes" },
        heyy = { "hey" },
        plss = { "please" },
        waitt = { "wait" },
        stopp = { "stop" },
        runn = { "run" },
        comee = { "come" },
        nvm = { "never", "mind" },
        brb = { "wait" },
        meds = { "medicine" },
        medkit = { "medicine" },
        bandages = { "bandage" },
        bandies = { "bandage" },
        grub = { "food" },
        chow = { "food" },
        smokes = { "cigarettes" },
        cigs = { "cigarettes" },
        booze = { "alcohol" },
        mags = { "ammo" },
        zed = { "zombie" },
        zeds = { "zombies" },
        zombs = { "zombies" },
        zomboid = { "zombie" },
        zomboids = { "zombies" },
        walker = { "zombie" },
        walkers = { "zombies" },
        biter = { "zombie" },
        biters = { "zombies" },
        shambler = { "zombie" },
        shamblers = { "zombies" },
        -- Dropped-apostrophe contractions & common typos
        whats = { "what", "is" },
        wats = { "what", "is" },
        whos = { "who", "is" },
        wheres = { "where", "is" },
        hows = { "how", "is" },
        ive = { "i", "have" },
        ["i've"] = { "i", "have" },
        id = { "i", "would" },
        youre = { "you", "are" },
        ["we're"] = { "we", "are" },
        weve = { "we", "have" },
        ["we've"] = { "we", "have" },
        theyre = { "they", "are" },
        ["they're"] = { "they", "are" },
        theyve = { "they", "have" },
        ["they've"] = { "they", "have" },
        hes = { "he", "is" },
        ["he's"] = { "he", "is" },
        shes = { "she", "is" },
        ["she's"] = { "she", "is" },
        dont = { "do", "not" },
        doesnt = { "does", "not" },
        didnt = { "did", "not" },
        cant = { "can", "not" },
        wont = { "will", "not" },
        isnt = { "is", "not" },
        arent = { "are", "not" },
        wasnt = { "was", "not" },
        werent = { "were", "not" },
        ["weren't"] = { "were", "not" },
        hadnt = { "had", "not" },
        ["hadn't"] = { "had", "not" },
        havent = { "have", "not" },
        hasnt = { "has", "not" },
        couldnt = { "could", "not" },
        wouldnt = { "would", "not" },
        shouldnt = { "should", "not" },
        ["what's"] = { "what", "is" },
        ["who's"] = { "who", "is" },
        ["where's"] = { "where", "is" },
        ["how's"] = { "how", "is" },
        ["you're"] = { "you", "are" },
    },
    irregularLemmas = {
        ate = "eat", eaten = "eat", eating = "eat",
        drank = "drink", drunk = "drink", drinking = "drink",
        bled = "bleed", bleeding = "bleed",
        ran = "run", running = "run",
        bit = "bite", bitten = "bite", biting = "bite",
        fought = "fight", fighting = "fight",
        gave = "give", given = "give", giving = "give",
        took = "take", taken = "take", taking = "take",
        got = "get", gotten = "get", getting = "get",
        shot = "shoot", shooting = "shoot",
        dying = "die", died = "die", dead = "dead",
        slept = "sleep", sleeping = "sleep",
        went = "go", gone = "go", going = "go",
        came = "come", coming = "come",
        saw = "see", seen = "see", seeing = "see",
        heard = "hear", hearing = "hear",
        found = "find", finding = "find",
        lost = "lose", losing = "lose",
        kept = "keep", keeping = "keep",
        left = "leave", leaving = "leave",
        brought = "bring", bringing = "bring",
        held = "hold", holding = "hold",
        stood = "stand", standing = "stand",
        sat = "sit", sitting = "sit",
        hid = "hide", hidden = "hide", hiding = "hide",
        broke = "break", broken = "break",
        fell = "fall", fallen = "fall",
        felt = "feel", feeling = "feel",
        knew = "know", known = "know",
        told = "tell", telling = "tell",
        said = "say", saying = "say",
        made = "make", making = "make",
        bandaged = "bandage", bandaging = "bandage",
        healed = "heal", healing = "heal",
        wounded = "wound", injured = "injure",
        starving = "starve", starved = "starve",
        zombies = "zombie", walkers = "walker", biters = "biter",
        enemies = "enemy", supplies = "supply", berries = "berry",
        bodies = "body", bandages = "bandage", pills = "pill",
    },
    fillers = {
        uh = true, um = true, erm = true, hmm = true,
        like = true, literally = true, actually = true, basically = true,
        just = true, maybe = true, kinda = true, sorta = true,
        bro = true, dude = true, man = true, yo = true, pal = true,
    },
    politeWords = {
        please = true, thanks = true, thank = true, appreciate = true,
        sorry = true, pardon = true, excuse = true, kindly = true,
    },
    urgentWords = {
        quick = true, quickly = true, hurry = true, now = true, asap = true,
        fast = true, emergency = true, help = true, run = true, watch = true,
        bleeding = true, bitten = true, horde = true,
    },
    hostileWords = {
        shut = true, idiot = true, stupid = true, moron = true,
        bastard = true, asshole = true, bitch = true, fuck = true,
        piss = true, useless = true, coward = true, liar = true,
        loser = true, pathetic = true, jerk = true,
    },
    dismissiveWords = {
        whatever = true, buzz = true, scram = true, beat = true,
        nobody = true, care = true,
    },
    skepticalWords = {
        really = true, seriously = true, bullshit = true, doubt = true,
        sure = true, lying = true, lie = true, prove = true,
    },
    casualWords = {
        hey = true, yo = true, bro = true, dude = true, man = true,
        sup = true, buddy = true, pal = true,
    },
    confirmWords = {
        yes = true, yeah = true, yep = true, sure = true, okay = true,
        alright = true, fine = true, deal = true, agreed = true,
    },
    denyWords = {
        no = true, nah = true, nope = true, never = true, cancel = true,
        forget = true, stop = true,
    },
    thankWords = {
        thanks = true, thank = true, appreciate = true,
    },
    apologyWords = {
        sorry = true, apologize = true, pardon = true,
    },
    numberWords = {
        one = 1, two = 2, three = 3, four = 4, five = 5,
        six = 6, seven = 7, eight = 8, nine = 9, ten = 10,
        eleven = 11, twelve = 12, thirteen = 13, fourteen = 14, fifteen = 15,
        sixteen = 16, seventeen = 17, eighteen = 18, nineteen = 19, twenty = 20,
        couple = 2, pair = 2, few = 3, several = 4, dozen = 12,
    },
}

local function packFor(lang)
    return NLP.Packs[string.upper(tostring(lang or "EN"))] or NLP.Packs.EN
end

-- Collapse 3+ consecutive identical letters: "heyyyyy" -> "hey", "helpppp" -> "help".
-- Preserves standard English double letters ("need", "food", "keep", "blood").
function NLP.CollapseElongation(word)
    word = tostring(word or "")
    if #word < 3 then return word, false end
    local out = {}
    local prev = nil
    local run = 0
    local changed = false
    for i = 1, #word do
        local ch = string.sub(word, i, i)
        if ch == prev then
            run = run + 1
            if run <= 2 then
                out[#out + 1] = ch
            else
                changed = true
            end
        else
            prev = ch
            run = 1
            out[#out + 1] = ch
        end
    end
    local collapsed = table.concat(out)
    -- If trailing repeated letter collapsed from 3+ to 2 (e.g. "heyy", "helpp", "noo"),
    -- trim to single when it's not a common English double ending (ee, oo, ll, ss, ff, zz).
    if changed and #collapsed >= 3 then
        local last = string.sub(collapsed, -1)
        local prevLast = string.sub(collapsed, -2, -2)
        if last == prevLast and last ~= "e" and last ~= "o" and last ~= "l" and last ~= "s" and last ~= "f" then
            collapsed = string.sub(collapsed, 1, -2)
        end
    end
    return collapsed, changed
end

function NLP.ExpandTokens(tokens, lang)
    local pack = packFor(lang)
    local map = pack.shorthand or {}
    local expanded = {}
    local didExpand = false
    local didCollapse = false
    for i = 1, #(tokens or {}) do
        local raw = tostring(tokens[i] or "")
        local w, collapsed = NLP.CollapseElongation(raw)
        if collapsed then didCollapse = true end
        local repl = map[w] or map[raw]
        if type(repl) == "table" then
            didExpand = true
            for j = 1, #repl do
                expanded[#expanded + 1] = repl[j]
            end
        elseif w ~= "" then
            expanded[#expanded + 1] = w
        end
    end
    return expanded, didExpand, didCollapse
end

function NLP.Lemmatize(word, lang)
    local w = string.lower(tostring(word or ""))
    if #w <= 3 then return w end
    local pack = packFor(lang)
    local irr = pack.irregularLemmas and pack.irregularLemmas[w]
    if irr then return irr end
    if #w > 5 and string.sub(w, -3) == "ing" then
        local stem = string.sub(w, 1, -4)
        if #stem >= 3 and string.sub(stem, -1) == string.sub(stem, -2, -2) then
            stem = string.sub(stem, 1, -2)
        end
        return stem
    end
    if #w > 4 and string.sub(w, -3) == "ies" then
        return string.sub(w, 1, -4) .. "y"
    end
    if #w > 4 and string.sub(w, -2) == "ed" and string.sub(w, -3) ~= "eed" then
        local stem = string.sub(w, 1, -3)
        if #stem >= 3 and string.sub(stem, -1) == string.sub(stem, -2, -2) then
            stem = string.sub(stem, 1, -2)
        end
        return stem
    end
    if #w > 4 and (string.sub(w, -3) == "ses" or string.sub(w, -3) == "xes" or string.sub(w, -4) == "ches" or string.sub(w, -4) == "shes") then
        return string.sub(w, 1, -3)
    end
    if #w > 3 and string.sub(w, -1) == "s" and string.sub(w, -2) ~= "ss" and string.sub(w, -2) ~= "us" and string.sub(w, -2) ~= "is" then
        return string.sub(w, 1, -2)
    end
    return w
end

function NLP.LemmatizeTokens(tokens, lang)
    local out = {}
    for i = 1, #(tokens or {}) do
        out[i] = NLP.Lemmatize(tokens[i], lang)
    end
    return out
end

function NLP.StripFillers(tokens, lang)
    local pack = packFor(lang)
    local fillers = pack.fillers or {}
    local out = {}
    for i = 1, #(tokens or {}) do
        local w = tokens[i]
        if not fillers[w] then
            out[#out + 1] = w
        end
    end
    if #out == 0 then return tokens or {} end
    return out
end

local function detectShouting(raw)
    local upper, alpha = 0, 0
    for i = 1, #raw do
        local b = string.byte(raw, i)
        if b >= 65 and b <= 90 then
            upper = upper + 1
            alpha = alpha + 1
        elseif b >= 97 and b <= 122 then
            alpha = alpha + 1
        end
    end
    return alpha >= 6 and (upper / alpha) >= 0.75
end

function NLP.DetectTone(rawText, tokens, lang)
    local pack = packFor(lang)
    local raw = tostring(rawText or "")
    local hasBang = string.find(raw, "!", 1, true) ~= nil
    local hasQuestion = string.find(raw, "?", 1, true) ~= nil
    local isShouting = detectShouting(raw)
    local hostile, urgent, polite, casual, skeptical = 0, 0, 0, 0, 0
    for i = 1, #(tokens or {}) do
        local w = tokens[i]
        if pack.hostileWords and pack.hostileWords[w] then hostile = hostile + 1 end
        if pack.urgentWords and pack.urgentWords[w] then urgent = urgent + 1 end
        if pack.politeWords and pack.politeWords[w] then polite = polite + 1 end
        if pack.casualWords and pack.casualWords[w] then casual = casual + 1 end
        if pack.skepticalWords and pack.skepticalWords[w] then skeptical = skeptical + 1 end
    end
    local lowerRaw = string.lower(raw)
    if string.find(lowerRaw, "get lost", 1, true)
        or string.find(lowerRaw, "none of your business", 1, true)
        or string.find(lowerRaw, "mind your own business", 1, true)
        or string.find(lowerRaw, "who asked", 1, true)
    then
        hostile = hostile + 1
    end
    if hasBang then urgent = urgent + 1 end
    local isRude = hostile > 0 or (isShouting and polite == 0)
    local isPolite = polite > 0 and not isRude
    local isSkeptical = skeptical > 0 and (hasQuestion or hostile == 0)
    local tone = "neutral"
    if isRude then tone = "hostile"
    elseif urgent >= 2 or (urgent >= 1 and hasBang) then tone = "urgent"
    elseif isSkeptical and polite == 0 then tone = "skeptical"
    elseif isPolite then tone = "polite"
    elseif casual > 0 then tone = "casual" end
    return tone, hasQuestion, hasBang, {
        isRude = isRude,
        isShouting = isShouting,
        isPolite = isPolite,
        isSkeptical = isSkeptical,
    }
end

function NLP.ClassifyDialogueAct(tokens, rawText, lang)
    local pack = packFor(lang)
    tokens = type(tokens) == "table" and tokens or {}
    local n = #tokens
    if n == 0 then return nil end
    local first = tokens[1]
    local joined = table.concat(tokens, " ")
    if joined == "never mind" or joined == "forget it" or joined == "cancel" then
        return "DENY"
    end
    if joined == "tell me more" or joined == "what happened" or joined == "go on" or joined == "and then" then
        return "ASK_ELABORATE"
    end
    if n <= 3 then
        if first == "why" then return "ASK_WHY" end
        if first == "where" then return "ASK_WHERE" end
        if first == "who" then return "ASK_WHO" end
        if pack.confirmWords and pack.confirmWords[first] then return "CONFIRM" end
        if pack.denyWords and pack.denyWords[first] then return "DENY" end
        if pack.thankWords and pack.thankWords[first] then return "THANK" end
        if pack.apologyWords and pack.apologyWords[first] then return "APOLOGIZE" end
        if pack.skepticalWords and pack.skepticalWords[first] then return "CHALLENGE" end
    end
    return nil
end

-- Consonant-skeleton phonetic key for O(1) phonetic fuzzy matching:
-- "medisin" / "medicine" -> "mdsn", "zomby" / "zombie" -> "zmb", "frend" / "friend" -> "frnd".
function NLP.PhoneticKey(word)
    local w = string.lower(tostring(word or ""))
    if #w < 3 then return "" end
    -- Normalize common English phonetic clusters
    w = string.gsub(w, "ph", "f")
    w = string.gsub(w, "ck", "k")
    w = string.gsub(w, "ce", "se")
    w = string.gsub(w, "ci", "si")
    w = string.gsub(w, "cy", "sy")
    w = string.gsub(w, "c", "k")
    w = string.gsub(w, "q", "k")
    w = string.gsub(w, "z", "s")
    w = string.gsub(w, "x", "ks")
    -- Keep first letter, drop interior vowels (a,e,i,o,u,y,h,w), dedupe adjacent consonants
    local first = string.sub(w, 1, 1)
    local out = { first }
    local prev = first
    for i = 2, #w do
        local ch = string.sub(w, i, i)
        if ch ~= "a" and ch ~= "e" and ch ~= "i" and ch ~= "o" and ch ~= "u"
            and ch ~= "y" and ch ~= "h" and ch ~= "w"
            and ch >= "a" and ch <= "z"
            and ch ~= prev
        then
            out[#out + 1] = ch
            prev = ch
        end
    end
    return table.concat(out)
end

function NLP.ExtractQuantity(tokens, lang)
    local pack = packFor(lang)
    local numWords = pack.numberWords or {}
    tokens = type(tokens) == "table" and tokens or {}
    local n = #tokens
    for i = 1, n do
        local w = tokens[i]
        -- Handle "half a dozen" -> 6
        if w == "half" and tokens[i + 1] == "a" and tokens[i + 2] == "dozen" then
            return 6
        end
        local numeric = tonumber(w)
        if numeric and numeric >= 1 and numeric <= 999 and math.floor(numeric) == numeric then
            return numeric
        end
        local mapped = numWords[w]
        if mapped ~= nil then
            -- Avoid false positives on idioms like "one of" or "someone"
            if not (w == "one" and tokens[i + 1] == "of") then
                return mapped
            end
        end
    end
    return nil
end

return NLP
