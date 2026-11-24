-- Shared O(1) English grammar & morphology engine for both NLU and NLG.
-- Classifies pronouns (person, number, case, gender), kinship nouns, tense
-- (present/past/future), and mood (indicative/subjunctive/imperative), and
-- inflects pronouns, copula ("be"), auxiliaries ("have"/"do"), regular and
-- irregular verbs, indefinite articles ("a"/"an"), and possessives.
-- Pure Lua 5.1 / Kahlua2-safe, zero regex backtracking, zero per-tick cost.

PsychopatzCore = PsychopatzCore or {}
PsychopatzCore.Semantics = PsychopatzCore.Semantics or {}

local Semantics = PsychopatzCore.Semantics
local Grammar = Semantics.EnglishGrammar or {}
Semantics.EnglishGrammar = Grammar

Grammar.VERSION = 1

-- O(1) pronoun classification table: person (1|2|3), number ("sg"|"pl"),
-- case ("subj"|"obj"|"poss"|"poss_pron"|"refl"), gender ("male"|"female"|"neutral"|"any").
Grammar.PRONOUNS = {
    i          = { person = 1, number = "sg", case = "subj",      gender = "any" },
    me         = { person = 1, number = "sg", case = "obj",       gender = "any" },
    my         = { person = 1, number = "sg", case = "poss",      gender = "any" },
    mine       = { person = 1, number = "sg", case = "poss_pron", gender = "any" },
    myself     = { person = 1, number = "sg", case = "refl",      gender = "any" },

    we         = { person = 1, number = "pl", case = "subj",      gender = "any" },
    us         = { person = 1, number = "pl", case = "obj",       gender = "any" },
    our        = { person = 1, number = "pl", case = "poss",      gender = "any" },
    ours       = { person = 1, number = "pl", case = "poss_pron", gender = "any" },
    ourselves  = { person = 1, number = "pl", case = "refl",      gender = "any" },

    you        = { person = 2, number = "sg", case = "subj_obj",  gender = "any" },
    your       = { person = 2, number = "sg", case = "poss",      gender = "any" },
    yours      = { person = 2, number = "sg", case = "poss_pron", gender = "any" },
    yourself   = { person = 2, number = "sg", case = "refl",      gender = "any" },
    yourselves = { person = 2, number = "pl", case = "refl",      gender = "any" },

    he         = { person = 3, number = "sg", case = "subj",      gender = "male" },
    him        = { person = 3, number = "sg", case = "obj",       gender = "male" },
    his        = { person = 3, number = "sg", case = "poss",      gender = "male" },
    himself    = { person = 3, number = "sg", case = "refl",      gender = "male" },

    she        = { person = 3, number = "sg", case = "subj",      gender = "female" },
    her        = { person = 3, number = "sg", case = "obj_poss",  gender = "female" },
    hers       = { person = 3, number = "sg", case = "poss_pron", gender = "female" },
    herself    = { person = 3, number = "sg", case = "refl",      gender = "female" },

    it         = { person = 3, number = "sg", case = "subj_obj",  gender = "neutral" },
    its        = { person = 3, number = "sg", case = "poss",      gender = "neutral" },
    itself     = { person = 3, number = "sg", case = "refl",      gender = "neutral" },

    they       = { person = 3, number = "pl", case = "subj",      gender = "any" },
    them       = { person = 3, number = "pl", case = "obj",       gender = "any" },
    their      = { person = 3, number = "pl", case = "poss",      gender = "any" },
    theirs     = { person = 3, number = "pl", case = "poss_pron", gender = "any" },
    themselves = { person = 3, number = "pl", case = "refl",      gender = "any" },
}

-- Kinship & family nouns with grammatical number and default gender.
Grammar.KINSHIP = {
    dad          = { person = 3, number = "sg", gender = "male" },
    father       = { person = 3, number = "sg", gender = "male" },
    mom          = { person = 3, number = "sg", gender = "female" },
    mother       = { person = 3, number = "sg", gender = "female" },
    parent       = { person = 3, number = "sg", gender = "any" },
    parents      = { person = 3, number = "pl", gender = "any" },
    brother      = { person = 3, number = "sg", gender = "male" },
    brothers     = { person = 3, number = "pl", gender = "male" },
    sister       = { person = 3, number = "sg", gender = "female" },
    sisters      = { person = 3, number = "pl", gender = "female" },
    sibling      = { person = 3, number = "sg", gender = "any" },
    siblings     = { person = 3, number = "pl", gender = "any" },
    husband      = { person = 3, number = "sg", gender = "male" },
    wife         = { person = 3, number = "sg", gender = "female" },
    spouse       = { person = 3, number = "sg", gender = "any" },
    partner      = { person = 3, number = "sg", gender = "any" },
    lover        = { person = 3, number = "sg", gender = "any" },
    son          = { person = 3, number = "sg", gender = "male" },
    sons         = { person = 3, number = "pl", gender = "male" },
    daughter     = { person = 3, number = "sg", gender = "female" },
    daughters    = { person = 3, number = "pl", gender = "female" },
    child        = { person = 3, number = "sg", gender = "any" },
    children     = { person = 3, number = "pl", gender = "any" },
    kid          = { person = 3, number = "sg", gender = "any" },
    kids         = { person = 3, number = "pl", gender = "any" },
    grandpa      = { person = 3, number = "sg", gender = "male" },
    grandfather  = { person = 3, number = "sg", gender = "male" },
    grandma      = { person = 3, number = "sg", gender = "female" },
    grandmother  = { person = 3, number = "sg", gender = "female" },
    grandparents = { person = 3, number = "pl", gender = "any" },
    uncle        = { person = 3, number = "sg", gender = "male" },
    aunt         = { person = 3, number = "sg", gender = "female" },
    cousin       = { person = 3, number = "sg", gender = "any" },
    cousins      = { person = 3, number = "pl", gender = "any" },
    family       = { person = 3, number = "sg", gender = "any" },
}

local PAST_AUX = {
    was = true, were = true, did = true, had = true,
    could = true, would = true, should = true,
}

local FUTURE_AUX = {
    will = true, shall = true, gonna = true,
}

local SUBJUNCTIVE_TRIGGERS = {
    ["if"] = true, wish = true, suppose = true, imagine = true,
    though = true, although = true,
}

local IRREGULAR_VERBS = {
    be     = { past = "was",     pastPl = "were",    pres3 = "is",     part = "being" },
    have   = { past = "had",     pres3 = "has",      part = "having" },
    ["do"] = { past = "did",     pres3 = "does",     part = "doing" },
    go     = { past = "went",    pres3 = "goes",     part = "going" },
    come   = { past = "came",    pres3 = "comes",    part = "coming" },
    see    = { past = "saw",     pres3 = "sees",     part = "seeing" },
    tell   = { past = "told",    pres3 = "tells",    part = "telling" },
    say    = { past = "said",    pres3 = "says",     part = "saying" },
    know   = { past = "knew",    pres3 = "knows",    part = "knowing" },
    give   = { past = "gave",    pres3 = "gives",    part = "giving" },
    take   = { past = "took",    pres3 = "takes",    part = "taking" },
    get    = { past = "got",     pres3 = "gets",     part = "getting" },
    make   = { past = "made",    pres3 = "makes",    part = "making" },
    find   = { past = "found",   pres3 = "finds",    part = "finding" },
    lose   = { past = "lost",    pres3 = "loses",    part = "losing" },
    keep   = { past = "kept",    pres3 = "keeps",    part = "keeping" },
    leave  = { past = "left",    pres3 = "leaves",   part = "leaving" },
    bring  = { past = "brought", pres3 = "brings",   part = "bringing" },
    hold   = { past = "held",    pres3 = "holds",    part = "holding" },
    stand  = { past = "stood",   pres3 = "stands",   part = "standing" },
    sit    = { past = "sat",     pres3 = "sits",     part = "sitting" },
    run    = { past = "ran",     pres3 = "runs",     part = "running" },
    eat    = { past = "ate",     pres3 = "eats",     part = "eating" },
    drink  = { past = "drank",   pres3 = "drinks",   part = "drinking" },
    sleep  = { past = "slept",   pres3 = "sleeps",   part = "sleeping" },
    hear   = { past = "heard",   pres3 = "hears",    part = "hearing" },
    feel   = { past = "felt",    pres3 = "feels",    part = "feeling" },
    grow   = { past = "grew",    pres3 = "grows",    part = "growing" },
    live   = { past = "lived",   pres3 = "lives",    part = "living" },
    die    = { past = "died",    pres3 = "dies",     part = "dying" },
    fight  = { past = "fought",  pres3 = "fights",   part = "fighting" },
    shoot  = { past = "shot",    pres3 = "shoots",   part = "shooting" },
    hide   = { past = "hid",     pres3 = "hides",    part = "hiding" },
    fall   = { past = "fell",    pres3 = "falls",    part = "falling" },
    ["break"] = { past = "broke", pres3 = "breaks",  part = "breaking" },
}

local IRREGULAR_PAST_LOOKUP = {}
for base, forms in pairs(IRREGULAR_VERBS) do
    if forms.past then IRREGULAR_PAST_LOOKUP[forms.past] = base end
    if forms.pastPl then IRREGULAR_PAST_LOOKUP[forms.pastPl] = base end
end

local AN_EXCEPTIONS = {
    hour = true, hours = true, honest = true, honor = true, honour = true,
    heir = true, herb = true, herbs = true,
}

local A_EXCEPTIONS = {
    uni = true, user = true, useful = true, usual = true, one = true,
    once = true, european = true, utensil = true,
}

local function isVowel(ch)
    return ch == "a" or ch == "e" or ch == "i" or ch == "o" or ch == "u"
end

function Grammar.ClassifyPronoun(word)
    return Grammar.PRONOUNS[string.lower(tostring(word or ""))]
end

function Grammar.ClassifyKinship(word)
    return Grammar.KINSHIP[string.lower(tostring(word or ""))]
end

-- Single-pass O(n) grammar analyzer for NLU tokens.
function Grammar.AnalyzeTokens(tokens)
    tokens = type(tokens) == "table" and tokens or {}
    local tense = "present"
    local mood = "indicative"
    local pronouns = {}
    local kinship = {}
    local subjectPerson, subjectNumber, subjectGender = nil, nil, nil
    local sawSubjunctiveTrigger = false
    local hasPluralConjunction = false

    for i = 1, #tokens do
        local tok = string.lower(tostring(tokens[i] or ""))
        if SUBJUNCTIVE_TRIGGERS[tok] then
            sawSubjunctiveTrigger = true
        end
        if tok == "were" then
            tense = "past"
            if sawSubjunctiveTrigger then
                mood = "subjunctive"
            end
        elseif PAST_AUX[tok] or IRREGULAR_PAST_LOOKUP[tok] then
            tense = "past"
        elseif #tok >= 5 and string.sub(tok, -2) == "ed" then
            tense = "past"
        elseif FUTURE_AUX[tok] and tense == "present" then
            tense = "future"
        end

        local p = Grammar.PRONOUNS[tok]
        if p then
            pronouns[#pronouns + 1] = {
                token = tok,
                index = i,
                person = p.person,
                number = p.number,
                case = p.case,
                gender = p.gender,
            }
            if subjectPerson == nil and (p.case == "subj" or p.case == "subj_obj") then
                subjectPerson = p.person
                subjectNumber = p.number
                subjectGender = p.gender
            end
        end

        local k = Grammar.KINSHIP[tok]
        if k then
            kinship[#kinship + 1] = {
                token = tok,
                index = i,
                person = k.person,
                number = k.number,
                gender = k.gender,
            }
            if subjectPerson == nil then
                subjectPerson = k.person
                subjectNumber = k.number
                subjectGender = k.gender
            end
        end

        -- Compound subject detection: "my dad and I", "she and he" -> plural
        if tok == "and" and i > 1 and i < #tokens then
            local prevTok = string.lower(tostring(tokens[i - 1] or ""))
            local nextTok = string.lower(tostring(tokens[i + 1] or ""))
            if (Grammar.PRONOUNS[prevTok] or Grammar.KINSHIP[prevTok])
                and (Grammar.PRONOUNS[nextTok] or Grammar.KINSHIP[nextTok])
            then
                hasPluralConjunction = true
            end
        end
    end

    if hasPluralConjunction then
        subjectNumber = "pl"
        if subjectPerson == 3 then
            for _, pr in ipairs(pronouns) do
                if pr.person == 1 then subjectPerson = 1; break end
            end
        end
    end

    return {
        tense = tense,
        mood = mood,
        subjectPerson = subjectPerson,
        subjectNumber = subjectNumber,
        subjectGender = subjectGender,
        pronouns = pronouns,
        kinship = kinship,
    }
end

-- NLG Surface Inflection Helpers --------------------------------------------

local PRONOUN_FORMS = {
    ["1:sg:any"]     = { subj = "I",    obj = "me",   poss = "my",    poss_pron = "mine",   refl = "myself" },
    ["1:pl:any"]     = { subj = "we",   obj = "us",   poss = "our",   poss_pron = "ours",   refl = "ourselves" },
    ["2:sg:any"]     = { subj = "you",  obj = "you",  poss = "your",  poss_pron = "yours",  refl = "yourself" },
    ["2:pl:any"]     = { subj = "you",  obj = "you",  poss = "your",  poss_pron = "yours",  refl = "yourselves" },
    ["3:sg:male"]    = { subj = "he",   obj = "him",  poss = "his",   poss_pron = "his",    refl = "himself" },
    ["3:sg:female"]  = { subj = "she",  obj = "her",  poss = "her",   poss_pron = "hers",   refl = "herself" },
    ["3:sg:neutral"] = { subj = "it",   obj = "it",   poss = "its",   poss_pron = "its",    refl = "itself" },
    ["3:sg:any"]     = { subj = "they", obj = "them", poss = "their", poss_pron = "theirs", refl = "themselves" },
    ["3:pl:any"]     = { subj = "they", obj = "them", poss = "their", poss_pron = "theirs", refl = "themselves" },
}

function Grammar.Pronoun(person, number, gender, case)
    person = tonumber(person) or 3
    number = (number == "pl" or number == "plural") and "pl" or "sg"
    case = tostring(case or "subj")
    local g = "any"
    if person == 3 and number == "sg" then
        local gl = string.lower(tostring(gender or "any"))
        if gl == "male" or gl == "m" then g = "male"
        elseif gl == "female" or gl == "f" then g = "female"
        elseif gl == "neutral" or gl == "it" then g = "neutral" end
    end
    local row = PRONOUN_FORMS[tostring(person) .. ":" .. number .. ":" .. g]
        or PRONOUN_FORMS["3:pl:any"]
    return row[case] or row.subj
end

function Grammar.Copula(person, number, tense, mood)
    person = tonumber(person) or 3
    number = (number == "pl" or number == "plural") and "pl" or "sg"
    tense = string.lower(tostring(tense or "present"))
    mood = string.lower(tostring(mood or "indicative"))

    -- Past subjunctive ("If I were you", "If he were here") ALWAYS uses "were".
    if mood == "subjunctive" then
        return "were"
    end
    if tense == "past" then
        if number == "pl" or person == 2 then return "were" end
        return "was"
    end
    if tense == "future" then
        return "will be"
    end
    if number == "pl" or person == 2 then return "are" end
    if person == 1 then return "am" end
    return "is"
end

function Grammar.Conjugate(verb, person, number, tense, mood)
    local base = string.lower(tostring(verb or ""))
    if base == "" then return "" end
    person = tonumber(person) or 3
    number = (number == "pl" or number == "plural") and "pl" or "sg"
    tense = string.lower(tostring(tense or "present"))
    mood = string.lower(tostring(mood or "indicative"))

    if base == "be" then
        return Grammar.Copula(person, number, tense, mood)
    end
    if tense == "future" then
        return "will " .. base
    end
    local irr = IRREGULAR_VERBS[base]
    if tense == "past" then
        if irr then
            if number == "pl" and irr.pastPl then return irr.pastPl end
            return irr.past
        end
        if string.sub(base, -1) == "e" then return base .. "d" end
        if string.sub(base, -1) == "y" and #base >= 2 and not isVowel(string.sub(base, -2, -2)) then
            return string.sub(base, 1, -2) .. "ied"
        end
        return base .. "ed"
    end
    if tense == "progressive" then
        if irr and irr.part then return irr.part end
        if string.sub(base, -1) == "e" and string.sub(base, -2) ~= "ee" then
            return string.sub(base, 1, -2) .. "ing"
        end
        return base .. "ing"
    end
    -- Present indicative: 3rd person singular takes -s/-es/-ies
    if person == 3 and number == "sg" then
        if irr and irr.pres3 then return irr.pres3 end
        local last1 = string.sub(base, -1)
        local last2 = string.sub(base, -2)
        if last1 == "s" or last1 == "x" or last1 == "z" or last2 == "ch" or last2 == "sh" or last1 == "o" then
            return base .. "es"
        end
        if last1 == "y" and #base >= 2 and not isVowel(string.sub(base, -2, -2)) then
            return string.sub(base, 1, -2) .. "ies"
        end
        return base .. "s"
    end
    return base
end

function Grammar.Article(noun)
    local s = string.lower(tostring(noun or ""))
    s = string.gsub(s, "^%s+", "")
    if s == "" then return "a" end
    local word = string.match(s, "^(%a+)") or s
    if AN_EXCEPTIONS[word] then return "an" end
    if A_EXCEPTIONS[word] or string.sub(word, 1, 3) == "uni" or string.sub(word, 1, 2) == "eu" then
        return "a"
    end
    if isVowel(string.sub(word, 1, 1)) then return "an" end
    return "a"
end

function Grammar.Possessive(name)
    local s = tostring(name or "")
    s = string.gsub(s, "%s+$", "")
    if s == "" then return "" end
    local last = string.lower(string.sub(s, -1))
    if last == "s" then return s .. "'" end
    return s .. "'s"
end

-- Build a flat token table for TokenFormatter / .convo templates from a subject spec:
--   spec = { person = 1|2|3, number = "sg"|"pl", gender = "male"|"female"|"any",
--            tense = "present"|"past"|"future", mood = "indicative"|"subjunctive" }
function Grammar.BuildSubjectTokens(spec, prefix)
    spec = type(spec) == "table" and spec or {}
    local p = prefix or "subj"
    local person = tonumber(spec.person) or 3
    local number = (spec.number == "pl" or spec.number == "plural") and "pl" or "sg"
    local gender = spec.gender or "any"
    local tense = spec.tense or "present"
    local mood = spec.mood or "indicative"
    -- Note: singular "they" ("3:sg:any") takes plural verb agreement in English ("they are", "they were").
    local verbNumber = (person == 3 and number == "sg" and gender == "any") and "pl" or number
    return {
        [p .. ".pron"]      = Grammar.Pronoun(person, number, gender, "subj"),
        [p .. ".obj"]       = Grammar.Pronoun(person, number, gender, "obj"),
        [p .. ".poss"]      = Grammar.Pronoun(person, number, gender, "poss"),
        [p .. ".poss_pron"] = Grammar.Pronoun(person, number, gender, "poss_pron"),
        [p .. ".refl"]      = Grammar.Pronoun(person, number, gender, "refl"),
        [p .. ".be"]        = Grammar.Copula(person, verbNumber, tense, mood),
        [p .. ".be_past"]   = Grammar.Copula(person, verbNumber, "past", mood),
        [p .. ".have"]      = Grammar.Conjugate("have", person, verbNumber, tense, mood),
        [p .. ".do"]        = Grammar.Conjugate("do", person, verbNumber, tense, mood),
    }
end

return Grammar
