pico-8 cartridge // http://www.pico-8.com
version 36
__lua__
-- pico-wordle :)
-- ported by sam
function wordlegridempty()
    for y = 0, 5 do
        for x = 0, 4 do
            draw_blank_tile(x,y)
        end
    end
end


-- set wordle palette
function set_wp()
    pal({139, 3, 8, 135, 9, 4, 136, 7, 6, 13, 141, 1, 129, 0, 130,11}, 1)
end

b = {[false] = 0, [true] = 1}

letter_masks = {0b11111111 ,0b11101111, 0b11110111, 0b11000011}
-- draws a white letter
-- frame: 0 - full letter, 1 - tilt back/up, 2 - tilt forward/down, 3 - very squish
function draw_letter(x,y, letter, frame)
    local start_x = 28+(x*16)
    local start_y = 11+(y*14)
    if(frame == 2) start_y += 1
    if(frame == 3) start_y += 2
    pal({[7] = 8})
    local spr_x = ((32+letter) % 16) * 8
    local spr_y = (flr(letter/16) + 2) * 8
    local line_count = 0
    for l = 0, 7 do
        if ((letter_masks[frame+1] >> l) & 1 == 1) then
            sspr(spr_x, spr_y + l, 8, 1, start_x, start_y+line_count)
            line_count += 1
        end
    end
end

response_frame_sprs = {0, 1, 3}
response_to_letter = {0,2,3}
-- draws a letter tile (letter is offset - a=0, b=1,...)
-- frame: 0 - full in, 1 - mid in, 2 - coming in
function draw_tile_response(x, y, state, letter, frame)
    clear_tile(x,y)
    pal({[7] = state*4, [6] = (state*4)+1, [13] = (state*4)+2})
    spr(frame, 24+(x*16), 8 + (y*14), 1, 2)
    spr(frame, 24+8+(x*16), 8 + (y*14), 1,2, true)
    pal({[7] = 8})
    -- spr(32+letter, 28+(x*16), 11+(y*14))
    draw_letter(x,y,letter, response_to_letter[frame+1])
    pal(0)
end

function draw_blank_tile(x,y)
    clear_tile(x,y)
    if(y == onGuess) then
        pal({[6] = 12, [1] = 12})
    else 
        pal({[6] = 13, [1] = 13})
    end
    spr(7, 24+(x*16), 8 + (y*14), 1, 2)
    spr(7, 24+8+(x*16), 8 + (y*14), 1,2, true)
    pal(0)
end

function clear_tile(x,y)
    rectfill(24+(x*16), 8+(y*14), 39+(x*16), 22+(y*14), 14) -- was 13
end

-- 0 is normal, 1 is a bit smaller, 2 is very squished, 3 is pressed in
function draw_tile_in(x, y, letter, frame)
    clear_tile(x,y)
    pal({[6] = 9, [1] = 12, [7] = 8})
    if frame == 3 then
        spr(8, 25+(x*16), 8 + (y*14), 1, 2)
        spr(8, 24+7+(x*16), 8 + (y*14), 1,2, true)
        draw_letter(x,y,letter, 3) -- play with this value a bit
    else 
        spr(7+frame, 24+(x*16), 8 + (y*14), 1, 2)
        spr(7+frame, 24+8+(x*16), 8 + (y*14), 1,2, true)
        draw_letter(x,y,letter, response_to_letter[frame+1])
    end
    -- spr(32+letter, 28+(x*16), 11+(y*14))
    pal(0)
end


-- just draws a rectangle, going_in = true means state color on bottom, false means on top
function draw_frame_rects(x,y, state, dist_down)
    clear_tile(x,y)
    pal(0)
    local left_x = 25+(x*16)
    local top_y = 8 + (y*14)+7
    rectfill(left_x, top_y, left_x+13, top_y+2, 12)
    rectfill(left_x, top_y+dist_down, left_x+13, top_y+2, state*4)
end

-- ordered list of keys
-- keyMap = {"Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P", "A", "S", "D", "F", "G", "H", "J", "K", "L",
-- "Z", "X", "C", "V", "B", "N", "M"}
keyMap = {16, 22, 4, 17, 19, 24, 20, 8, 14, 15, 0, 18, 3, 5, 6, 7, 9, 10, 11,
25, 23, 2, 21, 1, 13, 12}
keyMapInverse = {10, 23, 21, 12, 2, 13, 14, 15, 7, 16, 17, 18, 25, 24, 8, 9, 0, 3, 11, 4, 6, 22, 1, 20, 5, 19}

-- what color should key background be
-- 1 - default, 2 - blank, 3 - yellow, 4 - green
-- 5 - selected, 6 - blank selected, 7 - yellow selected, 8 - green selected
-- keyStates = {6, 5, 9, 3, 12, 1, 10, 11}
keyStates = {9, 15, 5, 2, 10, 11, 4, 1}

currentKey = 0

fpkf = 8-- frames it takes to switch key flashes
function draw_key(key_index, state, clicked, evodfr)
    local x = 0
    local y = 0
    if key_index == 26 then
        draw_enter_key(state, evodfr, clicked)
        return
    elseif key_index == 27 then
        draw_back_key(state, evodfr, clicked)
        return
    elseif key_index <= 9 then
        y = 98
        x = 20 + (key_index * 9)
    elseif key_index <= 18 then
        y = 98+9 -- go through and compress these down to save tokens later
        x = 24 + ((key_index-10) * 9)
    else 
        y = 98 + 18
        x = 24 + ((key_index-18) * 9)
    end
    rectfill(x,y,x+7,y+8, 14)
    if (state >= 5) then 
        -- selected
        for xp = 0, 7 do
            for yp = 0,7 do
                local which_color = ((xp % 2 == 0) ~= (yp%2 == 0)) ~= evodfr
                local this_color = keyStates[state]
                if (which_color) this_color = keyStates[state-4]
                pset(x+xp, y+yp+b[clicked], this_color)
            end
        end
    else 
        rectfill(x, y + b[clicked], x+7, y+7, keyStates[state])
    end
    pal({[7] = 8})
    spr(32+keyMap[key_index+1], x, y+b[clicked])
    pal(0)
end

-- 1 - default, 5 - selected, 
function draw_back_key(state, evodfr, clicked)
    local x = 96
    local y = 116
    if (state >= 5) then 
        -- selected
        for xp = 0, 12 do
            for yp = 0,7 do
                local which_color = ((xp % 2 == 0) ~= (yp%2 == 0)) ~= evodfr
                local this_color = 3
                if (which_color) this_color = 7
                pset(x+xp, y+yp, this_color)
            end
        end
        palt(6, true)
        pal({[7] = 8, [13] = 9})
        sspr(33, 0, 2, 8, 97-b[clicked], 116)
        sspr(35, 0, 8, 8, 99, 116)
    else 
        -- rectfill(x, y + b[clicked], x+10, y+7, keyStates[state])
        pal({[7] = 8, [6] = keyStates[state]})
        spr(4, 96, 116)
        spr(5, 104, 116)
    end
    pal(0)
end



local baby_pulse_maps = {
    [0] = {[8] = 5, [9] = 5},
    {[8] = 4, [9] = 5},
    {[8] = 5, [9] = 4},
    {[8] = 4, [9] = 5}
}
pulse_map = {[0] = 8, 9, 10, 11, 12, 13, 14, 15, 1}
function draw_enter_key(state, evodfr, clicked)
    local x = 20
    local y = 116
    if (current_valid_state == 1) then
        -- valid word, ready to submit
        if state >= 5 then
            -- selected / full pulse
            -- local base_num = flr((frame_num % 18) / 2)
            local base_num = (frame_num*4) % 10
            for l = 0, 8 do 
                local is_on = (base_num+l) % 5 == 0
                pal(pulse_map[l], 5-b[is_on])
            end
            pal({[7] = 8})
            spr(20, 20, 116)
            spr(21, 28, 116)
        else 
            -- baby pulse, 0 - none, 1 - mid, 2 - full, 3 - mid
            local base_num = flr((frame_num % 16) / 4)
            pal(baby_pulse_maps[base_num])
            for l = 2, 8 do 
                pal(pulse_map[l], 5)
            end
            pal({[7] = 8})
            spr(20, 20, 116)
            spr(21, 28, 116)
        end
    else
        -- not ready to submit, or not a valid word
        if state >= 5 then
            -- selected and not ready - want to flash grayed out
            for xp = 0, 11 do
                for yp = 0,7 do
                    local which_color = ((xp % 2 == 0) ~= (yp%2 == 0)) ~= evodfr
                    local this_color = 15
                    if (which_color) this_color = 11
                    pset(x+xp, y+yp, this_color)
                end
            end
            palt(1, true)
            for c = 8, 15 do
                palt(c, true)
            end
            pal({[7] = 8})
            spr(20, 20, 116)
            spr(21, 28, 116)
        else
            -- just print kinda grayed out
            pal(1, 11)
            for c = 8, 15 do
                pal(c, 11)
            end
            pal({[7] = 8})
            spr(20, 20, 116)
            spr(21, 28, 116)
        end
    end
    pal(0)
end


moveMap = {} -- moveMap[direction][fromKey-1] = toKey -- direction 1 = left, 2 = right, 3 = up, 4 = down
--guide    : { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27}
moveMap[1] = { 9, 0, 1, 2, 3, 4, 5, 6, 7, 8,18,10,11,12,13,14,15,16,17,26,19,20,21,22,23,24,27,25}
moveMap[2] = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 0,11,12,13,14,15,16,17,18,10,20,21,22,23,24,25,27,19,26}
moveMap[3] = {26,19,20,21,22,23,24,25,27,27, 0, 1, 2, 3, 4, 5, 6, 7, 8,11,12,13,14,15,16,17,10,18}
moveMap[4] = {10,11,12,13,14,15,16,17,18,18,26,19,20,21,22,23,24,25,27, 1, 2, 3, 4, 5, 6, 7, 0, 9}


currentWord = {}
currentWordLength = 0
onGuess = 0
isword = false

-- 0 = default, 1 = blank, 2 = yellow, 3 = green
letter_states = {} -- remember to init to zero

function init_letter_states()
    for l = 1,28 do
        letter_states[l] = 0
    end
end

function add_letter(key_clicked) 
    if (currentWordLength >= 5) return
    letterToAdd = keyMap[key_clicked+1]
    draw_tile_in(currentWordLength, onGuess, letterToAdd, 0)
    currentWordLength+=1
    add(currentWord, letterToAdd)
    if(currentWordLength == 5) then
        isword = check_word(currentWord)
        if(isword) then
            last_valid_state = current_valid_state
            current_valid_state = 1
            fsv = 0
            -- draw_valid_mark(1)
        else
            last_valid_state = current_valid_state
            current_valid_state = 2
            fsv = 0
            -- draw_valid_mark(2)
        end
    end
end


function backspace()
    if (currentWordLength <= 0) return
    deli(currentWord)
    if(currentWordLength==5) then
        last_valid_state = current_valid_state
        current_valid_state = 0
        fsv = 0
        -- draw_valid_mark(0)
    end
    currentWordLength-=1
    draw_blank_tile(currentWordLength, onGuess)
end

-- frames since valid mark
fsv = -1
current_valid_state = 0
last_valid_state = 0
vc_map = {[0] = 9, 1, 3}
function draw_valid_mark(state, frame, old_state)
    -- just get rid of it all, will need to clean this up later
    rectfill(104, 8, 110, 91, 14)
    -- if(state == 0) pal({[6] = 9, [7] = 8})
    -- if(state == 1) pal({[6] = 1, [7] = 8})
    -- if(state == 2) pal({[6] = 3, [7] = 8})
    pal({[6] = vc_map[state], [5] = vc_map[old_state], [7] = 8})
    spr(10+frame, 104, 8 + (onGuess*14)+4)
    pal(0)
end


-- main function to deal with giving out solutions - both should be tables with 0-25
function grade_word(answer_word, guess_word)
    -- need to deal with repeated values
    -- first handle right letter right place
    isRightPlace = {0,0,0,0,0}
    for i=1,5 do
        if (answer_word[i] == guess_word[i]) then 
            isRightPlace[i] = 1
        end
    end
    -- now deal with right letter, wrong place
    wrongPlace = {0,0,0,0,0} -- which of guess is yellow
    
    for i=1,5 do -- going through answer_word, want to find yellow bits
        if (isRightPlace[i] == 1) goto next_letter -- not yellow if it's green
        -- want to look through guess_word and check for this letter
        for g=1,5 do 
            if (isRightPlace[g] == 1) goto next_guess_letter -- this one already used
            if (wrongPlace[g] == 1) goto next_guess_letter -- also already used
            if (answer_word[i] == guess_word[g]) then
                wrongPlace[g] = 1 -- not used yet, is the right letter in wrong place
                break
            end
            ::next_guess_letter:: 
        end
        ::next_letter::
    end
    for l=1,5 do -- handle keyboard color
        if isRightPlace[l] == 1 then
            letter_states[keyMapInverse[guess_word[l]+1]+1] = 3
        elseif wrongPlace[l] == 1 then
            if (letter_states[keyMapInverse[guess_word[l]+1]+1] == 0) letter_states[keyMapInverse[guess_word[l]+1]+1] = 2
        else 
            if (letter_states[keyMapInverse[guess_word[l]+1]+1] == 0) letter_states[keyMapInverse[guess_word[l]+1]+1] = 1
        end
    end
    -- draw_graded_guess(onGuess, isRightPlace, wrongPlace, guess_word)
    saw = true
    fss = 0
    last_word = guess_word
    last_green_tab = isRightPlace
    last_yellow_tab = wrongPlace
    last_guess_num = onGuess
    keyboard_draw()
    if (onGuess < 5) then
        onGuess+=1
        currentWord = {}
        currentWordLength = 0
        isword = false
        fsv = 0
        last_valid_state = current_valid_state
        current_valid_state = 0
        -- draw_valid_mark(0)
    end



end



function draw_graded_guess(guessNum, greenTab, yellowTab, guess_word)
    for i=0,4 do
        tile_state = 2
        if greenTab[i+1] == 1 then
            tile_state = 0
        elseif yellowTab[i+1] == 1 then
            tile_state = 1
        end
        draw_tile_response(i, guessNum, tile_state, guess_word[i+1])
    end
end

-- used to get the keyboard there and also to update it
function keyboard_draw()
    for key = 0, 27 do
        this_letter_state = 1+letter_states[key+1]
        if(key == currentKey) this_letter_state+=4
        draw_key(key, this_letter_state, false, false)
    end
end

today_word = {0, 12, 14, 13, 6}

-- frames since submit(ting word)
fss = 0
-- still animating word
saw = false
last_word = {}
last_guess_num = 0
last_green_tab = {}
last_yellow_tab = {}

let_delay = 8 -- 4 frame delay between
fpf = 3.5 -- frames per frame ? just a way to slow down animation if we need to
function draw_response_frames()
    -- submit -> flipping our tile_in -> few frames of rectangle -> flipping response in -> finished
    -- 0      ->         2?           ->   2?                    ->     3 ?
    
    local sframe = flr(fss/fpf) -- scaled frames
    if(sframe >= flr(let_delay*4/fpf) + 8) then 
        saw = false
        for l=0,4 do
            draw_blank_tile(l, onGuess)
        end
    end
    for i=0,4 do
        local dsframe = sframe - flr(i*let_delay/fpf) -- add in delay
        if (dsframe < 0) goto continue_frames
        local tile_state = 2
        if last_green_tab[i+1] == 1 then
            tile_state = 0
        elseif last_yellow_tab[i+1] == 1 then
            tile_state = 1
        end
        if (dsframe < 3) then -- need to flip it in
            draw_tile_in(i, last_guess_num, last_word[i+1], dsframe)
        elseif dsframe < 5 then -- dropped from 6 to 5, bump back up to 6 and adjust accordingly for a fuller side-rectangle
            draw_frame_rects(i, last_guess_num, tile_state, 5-dsframe)
        elseif dsframe < 8 then
            draw_tile_response(i, last_guess_num, tile_state, last_word[i+1], 2-(dsframe-5))
        else 

        end
        ::continue_frames::
    end
    fss+=1
end

-- less for counting, more for tracking loops 
-- figure out max later, probably based on how many frames we want for background
-- use it for even/odd type stuff too though
frame_num = 0
fsc = -1 -- frames since clicked


fsb = -1 -- frames since back
function _update()
    -- assume just the one screen/state for now, add title/share screen stuff later?
    -- handle movement 
    local was_clicked = fsc ~= -1
    local clicked_back = fsb ~= -1
    for b=0, 3 do
        if btnp(b) then
            -- fine to handle clearing previous key up here
            draw_key(currentKey, letter_states[currentKey+1]+1, false, false)
            currentKey = moveMap[b+1][currentKey+1]
            -- draw_key(currentKey, 5+letter_states[currentKey+1], false, flr(frame_num / fpkf) % 2 == 0)
        end
    end
    if btnp(5) then
        if currentKey == 26 then -- enter
            -- test_word = {0, 12, 14, 13, 6 } -- among :)
            if currentWordLength == 5 and isword then
                grade_word(today_word, currentWord)
            end
        elseif currentKey == 27 then -- backspace
            backspace()
            was_clicked = true
            fsc = 0
            fsb = 0
            clicked_back = true
        else 
            if (onGuess <= 6) then
                add_letter(currentKey)
                was_clicked = true
                fsc = 0
            end
        end
    elseif btnp(4) then
        if onGuess <= 6 then
            backspace()
            was_clicked = true
            fsc = 0
            fsb = 0
            clicked_back = true
        end
    end

    -- handle all the graphics stuff down here, use flags and whatnot
    if (saw) then
        draw_response_frames()
        -- fss+=1
    end

    if(clicked_back) then
        draw_key(27, 5+letter_states[currentKey+1], fsb < 3, flr(frame_num / fpkf) % 2 == 0)
        reset_back = true
    else 
        draw_key(currentKey, 5+letter_states[currentKey+1], was_clicked, flr(frame_num / fpkf) % 2 == 0)
        if (reset_back and currentKey ~= 27) then
            draw_key(27, 1, false, flr(frame_num / fpkf) % 2 == 0)
            reset_back = false
        end
    end

    if(fsv ~= -1) then
        draw_valid_mark(current_valid_state, flr(fsv/2), last_valid_state)
    end

    if(current_valid_state == 1 and currentKey ~= 26) then
        draw_key(26, 1, false, flr(frame_num /fpkf) % 2 == 0)
    end

    if (fsc ~= -1) fsc += 1
    if (fsc >= 4) fsc = -1
    if (fsb ~= -1) fsb += 1
    if (fsb >= 4) fsb = -1
    if (fsv ~= -1) fsv += 1
    if (fsv >= 12) fsv = -1
    frame_num+=1
    if (frame_num >= 320) frame_num = 0 -- 288 so it can be divisible by 9?, 320 so divisible by 10?
end


-- ^^^^^
-- interface code
------------
-- wordle-y code
-- VVVVV

--functions from chloe :)) - returns table ["q"] = quotient (also in raw_bits form), ["r"] = remainder
function div26(raw_data) -- taking raw_bits as full 32 bit integer instead of 16:16 format
    q = 0
    r = 0
    for i=31,0,-1 do
        q <<= 1
        r <<= 1
        if ((raw_data & ((1>>16) << i)) ~= 0) r += 1
        if (r >= 26) q += (1 >> 16)
        r %= 26
    end
    return {["q"] = q, ["r"] = r}
end

-- return word
function decode_answer(raw_data)
    word = {}
    for l = 1,5 do
        local divd = div26(raw_data)
        word[l] = divd["r"]
        raw_data = divd["q"]
    end
    -- ?word[1]
    -- ?word[2]
    -- ?word[3]
    -- ?word[4]
    -- ?word[5]
    return word
end

-- index from zero ?
function get_answer(index) -- where 0 is the first word
    encoded_word = sub(nyt_answer_encoded, (3*index)+1, (3*index)+3)
    -- print(encoded_word)
    -- upperb10 = ord(encoded_word, 1)
    -- lowerb10 = ord(encoded_word, 3)
    -- lowerb10+= (ord(encoded_word, 2) << 8)

    -- reversing bit stuff to get it to start with the right thing
    raw_bits = ((ord(encoded_word, 3)) >> 16)
    raw_bits += ((ord(encoded_word, 2)) >> 8)
    raw_bits += (ord(encoded_word, 1))


    raw_bits_orig = raw_bits -- just incase we need that
    word = decode_answer(raw_bits)

    -- ?word[1]
    -- ?word[2]
    -- ?word[3]
    -- ?word[4]
    -- ?word[5]
    return word
end


-- returns true if date_1 was before date_2, just a helper function for neater code - compress if needed
function is_day_earlier(d_1, d_2)
    if (d_1["y"] == d_2["y"]) then
        if(d_1["m"] == d_2["m"]) then
            return (d_1["d"] < d_2["d"])
        else
            return (d_1["m"] < d_2["m"])
        end
    else
        return (d_1["y"] < d_2["y"]) 
    end
end

-- how many days before each month, add in 1 if it's a leap year and past febuary
day_month_starts = {
    0,
    31, -- january is 31 days
    59, -- feb is 28
    90, -- march is 31
    120, -- april is 30
    151, -- may is 31
    181, -- june is 30
    212, -- july is 31
    243, -- august is 31
    273, -- september is 30
    304, -- october is 31
    334, -- november is 30
}

-- get days between 2 dates - expects {["d"] = 1-31, ["m"] = 1-12, ["y"] = whatever}
function days_between(date_1, date_2)
    earlier_date = date_2
    later_date = date_1
    did_reverse = false
    if (is_day_earlier(date_1, date_2)) then
        earlier_date = date_1
        later_date = date_2
        did_reverse = true
    end
    -- leap years pain
    years_between = later_date["y"] - earlier_date["y"]
    leap_years = flr(years_between/4)
    if (later_date["y"] % 4 ~= 0 and (years_between%4) >= (later_date["y"]%4)) leap_years+=1
    -- could add in more complex handling for leap years, if anyone is still playing this in 80+ years and wants their days more aligned, add that code in here
    days_between_years = years_between*365 + leap_years

    later_day_of_year = day_month_starts[later_date["m"]] + later_date["d"]
    if(later_date["y"] % 4 == 0 and later_date["m"] > 2) later_day_of_year+=1
    earlier_day_of_year = day_month_starts[earlier_date["m"]] + earlier_date["d"]
    if(earlier_date["y"] % 4 == 0 and earlier_date["m"] > 2) earlier_day_of_year+=1

    total_days_between = days_between_years + later_day_of_year - earlier_day_of_year
    if did_reverse then
        return total_days_between
    else 
        return -total_days_between
    end

end


-- gives #wordle_num - 1
function wordle_index(from_date)
    first_wordle = {["y"] = 2021, ["m"] = 6, ["d"] = 19}
    return days_between(first_wordle, from_date)
end

function get_today_num()
    today_date = {["y"] = stat(90), ["m"] = stat(91), ["d"] = stat(92)}
    return wordle_index(today_date)
end

-- equivalent to l_word - r_word ish
-- l_word == r_word -> 0
-- l_word > r_word -> >0
-- l_word < r_word -> <0
function cmp_words(l_word, r_word)
    for l=1,5 do
        if(l_word[l] ~= r_word[l]) return l_word[l] - r_word[l]
    end
    return 0
end

function string_word(in_word)
    local string_tp = ""
    for l=1,5 do
        string_tp ..= chr(97+in_word[l])
    end
    return string_tp
end

-- sees if it's a word
-- temp function for now I guess, want to rework/compress storage method
function check_word(in_word)
    local start_index = valid_up_counts[in_word[1]+1]
    if (in_word[2] == 0) goto is_a
    for i=0,in_word[2]-1 do
        local count_index = i + in_word[1]*26 + 1
        start_index += ord(sub(valid_counts, count_index, count_index))
    end
    ::is_a::
    local end_count_index = in_word[1]*26 + in_word[2] + 1
    -- ?ord(sub(valid_counts, end_count_index, end_count_index))
    local end_index = start_index + ord(sub(valid_counts, end_count_index, end_count_index))+1

    -- end index should never actually be read, S==E then we've checked everywhere and it's not it
    while (end_index ~= start_index) do
        local mid_index = flr((end_index+start_index)/2)
        -- need to actually get the word
        local this_word = {in_word[1], in_word[2]}
        local encoded_sec = sub(valid_encoded, mid_index*2+1, mid_index*2+2)
        if (encoded_sec == "") return false -- 'zzzzz' was breaking it, this fixes
        local this_word_raw = (ord(encoded_sec, 1) << 8) + ord(encoded_sec, 2)
        this_word[3] = (this_word_raw & 31)
        this_word[4] = (this_word_raw >>> 5) & 31
        this_word[5] = (this_word_raw >>> 10) & 31
        -- ?("["..start_index.."|"..end_index.."] -> (".. mid_index.. "):"..string_word(this_word))
        local cmp_result = cmp_words(in_word, this_word)
        if(cmp_result == 0) return true
        if cmp_result > 0 then -- in_word > this_word
            start_index = mid_index+1
        else -- in_word < this_word
            end_index = mid_index
        end
    end
    return false
end


-- fine for now, just so I don't lag out vscode
nyt_answer_encoded = "vあむ웃チmて]む4ワ⁷゛ˇᶜ5セ/Lむi、ひ^Lミ1!はf5ヘW'nほMエひ³dウINH、はヲ✽す⁸1{} ュキ\\WMzc▮5ヘS5に◆웃●😐Pいス^✽z ま*て‖▤✽⁵ンてさ%、ゃ!🐱}ᵇけこ+EニT$6▤wろ[◀ᶜjk∧░Rいメbく¥、N.なᶠさwスFせ▒ˇ●の• ◜tFyナ゛た☉▮7ム「お³Vᵉっ[タか✽にヒ5なリせろ♪6◀=웃}み「iまちj-てᶠゅそ2🐱☉ᶠく_5x\\アイ、?れ⌂\000HMヘは🐱Xて゜R⁙Lりt。$`zyヌQZF!Rラ◀	○⁵5ヤFZ3Tリᵇwれ*☉゜oᶜ⬇️チて‖い゜AホMメワ웃\rX✽い wらvTツテてこ⧗つ✽ん「お⁵●つd-j⬇️³W∧zMヤ✽とま▮Oす。な✽つ⁴Z♥しぬ▮Fホ‖⁸N ョTせン☉せ♥ュせ⌂ナ」き?「sナ⁶ュ&▶レ∧FD\nz~ノ゜●テ1⌂リwをれ\nf웃て$/●nへ1v51😐ワ☉[K◀\nに✽にモ☉-➡️³Cを◀\n`🐱∧jRらス-i+[ャネな4M、スモ「ᶜウ。へrFZ0vきミ░☉█vやZつ~{웃AG웃QnたAk\\ヨっwソAn•っ!RふちTし웃ᶜけたm#そ\\NOもら^⬆️S²ほョwよセwょなcア。。へ}1●•1⬅️e!#█Fj⁸、オ' あ`!てゃ-iれ!さ★░♥x゜3\000♥す★wね⁘1○B‖²。Eをミe1OLニy▮;\" フさ▮;2Lヒり、o]-iユ1Y7kオ☉^▥-゛⬆️⬅️Fyメ\"あd \000ヲつホ&ちᵉ7!1もて‖ン、ゃ,xサ◝OイとそんN🐱ネ]웃ve🐱♪♪。⬅️けwとkLサ⁵l⁵オI8ノ。な●つレPIN⁵z🐱みそnテた▶シ▮9れvそあ 웃PとつY☉ᶠS☉A▒FZセ、…ゅkヒてOイ<vう²FDも☉/\000ち5k「⁘す-웃☉●m{ ツカ웃f▤」{ ░♥メ✽ン🅾️Oや゛wしゆ゜。トzl◝ ムヤwこ*⁴る●\\エ1▮<&³^★Hヌち゛⧗▤。웃⬅️OゆV●すょwね(_Zみ!てイ゛まフ▶HゃOやき♥ンp゛ま█。 ˇてく♪_k@⁘ロv゜wこ6ᵉ\000」{ょ✽いな6ᵇひ トほ1⬅️²せbミ🐱ヒン♥{B ま⬅️wウテ゛Bl!1あえFむあうイxむた5ゃh。に+웃[H☉egとつ¥4ワu「えンOせぬ!と\000ち☉G웃◝て ▮ツwシ5RあヘLハホ³X◜せ♥コ sなxねPFEᶠ‖!のLル♪Ilぬ、…ら゜、ヘFス☉゜\000Lxぬswツ▒cgへ、ゃも♥ンハ!うT웃▶Bあ∧<웃e◆`の\000てけ¹5し\r⁵ウほci%てᶠきつョエ\\アツwやク。☉。웃Xっちヲ^゜vぬdS&、あy-☉ヘてUエLヒP▶ホナ!こ○-hq|ᶜn🐱X⁘wもfhわ¥そ◆ム。こ[Y\rけ1◆■✽ら,⁴…ᵇ☉🅾️T◆uカOイウzmきEをムとeぬ まコ6ᵉか6ᶠヤW⬆️ᶜ「キ{●こ=6‖けて}g テz░けKzo³゜♥なdメた^ˇj`のWaさ*wイに⌂²F░けLR @IN³!⁙\"そ'ニてこ▥f`とOイえちB.1😐ャfソ⬅️✽もTᵉ▮⁷wケお▶ホイ$j⬅️゜マひ、░1⁘ワら6‖5Sひま●m}「hシwケ◝。☉あちほコち\rnFjᵇつンキ!⁙し▶$r웃➡️-。☉ヲwスC ▮21{ヒfマュkロっ✽よラ$j♥kカ😐웃\rpち♪●6゛<゜\\Gた⁷Q[ウなvˇマ●ぬ\nてさ3-i(Zね░Mっ◝ち,s:wオwま⧗Mュナ、░◝-U7/a,░☉♪!,V●ウっ[ヨfそ2}`のXちュるwすふ\"イ~$⁵っ✽よま\"に➡️9☉カX<きちkキwオ6l~ノ☉-いつリつ🐱X▮゜'yて█こ²(ん\"よ\r²	R゜\\I░ワ▶wゃこ!2@F[▮、░}゛たᵉhえね☉\rマてᵉろ ◜x●りnJしKた⁶をm]オ▶テな_Z6!●{゜x7-j⁸2くえ5オ06ᵉ▮そIエz[ョそc³つ3ゅ▶-➡️▮;(Lマ$zq[1⌂モ、はオ\\シき웃gzJa\000Uルよ!てらMツ⁸ちは$♥さ=た⁶み웃◝kて‖🅾️Eを⬆️Mゃエは☉*ち█jそ◆S☉♪ラ¥nffツ‖Sみ\r゛セx!⁙>QD<wほ」 ~り5‖ア1○3つ♥ょOは▮ちk5 モW1wソ♥さMちV◀あせと✽あ⬇️!♥っ゜b\"Fiぬ!♥ろ!⁙p!こ)kヒ⁶Uク ちミ9てこ⬆️!l○そ/g<おh ウマ-hさ✽つヨY ⬆️웃「\nFzら웃ト■1wナ ∧*゜R。゛ハ♪☉.ロ{メキLフ[웃\\`¹フXwエGそ^Hwコいwたロ✽ん%ちッi゛み□「お\000!JのZな6Zふほ゜x6゛モすてこ🅾️jリさ2くに゜んを▒E⁸✽んのZん◆wさ◜1}'웃Q゜せ☉d¹ゆP。⁘`て○かF[(!,O[ユむ✽り>[ヘセZア☉ち⁸⬇️「~▤!のモ テ○ちTへ♥● ゜\000あFE そ◆フLサセ[れっ゛6オてˇ(FZ@せょw'mD♥{…1Z.☉ま∧。こf、░y`♪スつョイそゆコちにAFEユ ツらiへPzTヒちヲi、xョな4bそIク、oPfマWI9(SみᶜLマh、ス³zha゛ヘけ²♪」そ1x まっちtイ゜♥웃N◝█웃ᵇん、は\000wよシ^▤B^}█✽あ…N¹シ1🅾️◜てJkN¹コ゛メヌ゛みモFセ😐、◆ヤ゛フT☉Rサ[ヒ6♥●➡️◀¹ぬ」|⬆️🐱}しR4vそMヌ`のワcロ[[らg▶2/!□ッ4ワsそを:●m|✽ゆカ●カツfヘモ フᵇzrヨFjさ!⁙そちッv5ホ_$5P、っ☉wたXW…りkカオて▶\nOゆ⁸_Z$-i🅾️たkほwもswウネ²Gき゛む⁴`♪ャ✽マヒ゛モラ1●uちᶠkwそ◝ち8y웃uひwのョvなw1{ッ tア フ	 モSき🅾️りwけコ1♥ほ♥qる웃◜bと2ウ]	K▮;エ◀⁘みせwヒl⁵Xち*o🐱c<wウナ、ヘ*゛ト2てさ◜゜\rふ^ˇ\\✽ねか、nやせけC5セ=Nホとく|VIMg-☉スVけ▮n•ろIMhせッ¹。🐱0せ_3!はawのリ✽ケ@Iけ░Zね█³★`。☉ョN¹ホ゜BpFz$-hDちムらz[ンNソT`の[▶⁙% テカI7ヨつ☉o。⌂%wき)そEュそb◝Mキ<FEやそ/fOは…つ▒⁙wみょ あなv♪-\000yゆ░あケwツ3つ⁴_^∧⬆️-iw゜☉Xちu😐vそ⬆️つマス✽ゆり!N⁸$Jス▮'D、さ-웃1ヘは▒フ✽¥ラQZG ハq³9	[マき。けˇJさ\\M◝7⁷ᶜ⁵▥lひ³Hあ웃◝ナ!はi9ソむ-j{▶C	\\アょそ1ml⁵i^|fそIウ」き⁸\\ッ▥1✽ぬ¥ヲTzOおち😐゛ち9て\\イ▮ちiん🐱bかgBc-웃ま゜\n♥wめコJひB「♪エ=IJwチ•▶Fcてさ7 ▤す゛=へ⁴★M。と‖そおXwキかwしlIく…wコ⁵と□1MヲハJしOc^➡️`⁙1 ちる!●●゛,B「お⁶!て$▶□+ ᶠVち♪ヘwコくせ⌂チZぬけW⬆️⁷ ◜zwウフ[ケZち%◜FPP♥|7 ョヘFE:▶.ッ\"▥ナN⁸[웃fユちk9、O⁴☉ᵉャ モ]O■6⁵Hハき}レwコ★!うF1cみてさˇ🐱m/Lむy[ミ,ちk3●mtwま♪、…を☉⁵n!r>☉.Pwケワwイは웃~fiほnそ⌂J◀\n、゜2★そね;Wおハ、➡️ヤ uhそ◝s!い>xコ\000「クX゛み`co□せvワ。お\rLゆ∧mlナ\"なBち█W2き;!➡️zFj⁷♥ン,゜ミス テ▒そTc◀⁙まRいツてBsてす;⌂⁸4☉'しjチWFZアOヒお[ロ■zz1ち⁙ᵉ2くお!い5LセpJpら。ワ⁵て∧TFO8゜3	🐱Xつwオラて▶▥z♪U✽■2✽、をちu⬆️|⁷K⁵?☉[ヤミO▮fv∧モl⁶\\2くかMョゅ^vモ^░゛。⌂1TムK1⬅️ょ_\\>O²こMイラちョ\000\\イへk\000あ[わ「⌂\000‖o&76⁘オXbナOᶜ🐱wろ_wオ2▶ル@☉せNznpてさ)ち9せ!♥れ✽てね゜2p☉ᵉュ⁘ワ♪Lら@Lろ¹웃\\おつレ^ち7⁸ t0 ▥ヲ웃f⧗Wてふwら^wオスちm;M◜7ᵉ⁙マ웃ョ⁙♥●☉³☉キ✽あ(ᶜ⬇️Zそ⁵)ちせぬQCOちjす1♥゜c]ワ²MV゛タTそ(@⁘ワ{vきヤ\\WYつョょOゆ 🐱}さ「ク⁙wくovˇh●キsI8G³■)I7ユた⁶'Eをヤ1nて-y「LみeOの@「⁘む•レ6。と゜8ᶠツちャう モ「たkた ニ¥^🅾️F。R⁴1◆ᵇ☉D|゜aレ`のルZちB、っもせw⁵、んr³」‖0フE▥∧Dちj❎5さュ🐱X(」…AFZツz○♥そMラᵇゆ'$⁶オbX⬅️ ~ろて\\マ1Y)³ねj▮8~◀3らiへチ!,B\"あh$jアFjせ‖ᵉロImふ-yた▶?gMキナ!こ•wテ」SFた゛モあOのる。█~て▶ᵉてく⧗Lむo、ひ⁵1{ホ[アらLや⁘☉-🅾️!て ✽⁶サ_Z>웃Q}FP「Gミ8て]ひ☉/Hl○|ておミ1◆ᶠ²2█、ョdせ☉゛6゛6▶8!ちj5Hネゆ웃a*Lまowス?웃\\L░웃ᵉwくを ▤なそTo;²な1😐eW⬆️そ1Z=1⬅️れ-웃<\\W◜そ'ヨ「🅾️ohをケ。%タVきq!d1X>6wちt[ユ^wツイつホ{ち♪コI8ハ▶=☉そ'フ⁵#カfタや゛G•6ᵉヲ⬇️⁴¹♥p0゜⬇️⧗「s█Y<ᶠ▶レ➡️e、G%タナ。웃⧗-j\"X<aLヌ²[ス16◀NVくタwつ>웃「「z⌂て▶7▤、っ|。🐱「 ウつそIツFyxI8ヨたju6ᵉ_wね゛!てやwむ□5マ6☉ᶠス゛メd░😐qちuソ-T「☉jWv★\rby$ uさ^웃V✽ホ`wやC▥●ツY7>。$♪Eん0ᵉ⁸fJ_ぬ☉.せつ웃ᵇLサ{웃fˇちッe゜マナ✽か■Mカて☉😐ヒ☉/☉゛◜pな{つ ▥「゛っれ☉bソ░けGちkイ ソエwろNwそさwソセb⁵I。さ❎、o(Nタ□웃1「m]「Lル♥웃!い⁶ワK1|🐱eろネl○コ ョハ゛ソメIm%R6JつR6iほ ゛メ4゛⬆️オOはほ!♥d」zり テる%645さ⌂N◝こ t😐!つった⁵Iちね、kキ゛-x◜せぬ」wておFF⁸░ののち	t●さ○。け… ョウ6ᵇ」웃●Ekカえ_k`Lも▮f4,MゃmI8K_5kxほI゛◝ そカヒ●り▥$k(wオひ웃PsR\" 1⬅️Y ムヌ[キヒえF8てrl。Hるち😐ナwけ	Rらニ$⁵セ_A☉て9[ちᵉコ✽いに웃e6 ⌂  ▮オ■マょて_⬅️ち⬇️UてきMて♥⬇️゛テ&5むなwケッ[ろゃM◜-|⁷S✽コ5 ▮@つ>Vc]◝EをOてさワち{すv★f。とフ`のヲ、ナ◆PいˇFy☉☉れ$\\ムゅFjヘてョ⁸🐱ヒ◝wし🐱◀\n•!⁙ユ。<@。ゅ\"kヒᶠ\\WK「s。▮(にhこ8、っz▶!) コ!Lサ}、…[そc\r☉c \"▥んつSz ホ⁙$⁶ょwケ▥웃0j モXちᶠlち'6つル\r²-きImわ웃P█vˇらImᵉk⬅️nてさレwしn²ルな✽っO!Qの゜(lwをfOやっwエ^wりNwき…1Y9ちPコてあオ◀	ヲてUる{ムヨFj2⁘ワ}。と☉웃~メ⁴-~て☉Pち⁸スwコ❎Pくを웃1ひ「カ6☉\rツ☉-◆|\rKxぬ⁸さT7あせて ソト◀⁘。JKナち{しM◝=[レB▮>Xち5eは▒Gそめり▮Fよて^フN¹フ♥●きえF⁵c]レつ◆を5さャ゜●⁶웃Q○Mレチそ▶の!^▒、░Hzo⁷!3⁵m'ナそa➡️9レやOチウちャわ!rろwて⧗Oはを゜wへて\\テLゅえ⁴ふCwわヒ1⌂ワ●m●FZょて•Mちk7Lみc🐱XぬFDま³I'wコうwちOwきキ▮K wは😐-j♪‖ᶜY!2つeイ+JJ…wは♪ るっ゛ホYつ▮3Hな…웃Pmそ1}Lも⁙'lゆMュチ░♥トLも○5セ@[スあそJのてこ⬅️ちiサe}らそTカN\000セ゜●☉゛スD[ソ❎ ムッ!SEえ,V\ng|てOは5らゅn$v ハo!☉\"웃ン⁶-⌂⁶゛⬆️♪◀\n゜ 웃\n웃!@⌂\000⁸ちU\000。ワフ▶■えちは•W⬆️こ「}ワ1♥#ちえF\\ょて-j⬅️ち8ᶠwエッwテむ゛タˇ▒Xゆ、ゃ⁙PたfzPリせけ?웃PiW⬇️fwオテ れi6%●X=⁶ みウた¹\"Im…wわ+ちL◜「³すて○いFYって▤nLサ⁶ちミル5さp゛⬆️ヘ☉ᶠM☉🅾️ヒ、ヘカてャほ▶ホテ゜<=fけC\"とケ゛ス@あせ*。%\\ち.R$J░☉³🅾️、は\\☉⁴ナX❎y゛みっwわ-●しチ³んヒ♥●∧⬇️¹◝5スス゛ソ/J`2-yぬてCホ웃▶⁶ちミユ ョソ\\ャ■゛ョ<1}#N³ミvそ❎Mンヤ」くお░♥ナc]0\000fqそら⁙ちj▥ちjˇ5こは웃◝h、◆フ ◜ヘ✽⬆️。:カ…☉\rフwよトcリᵉて◆◀cウ⁘゛⬆️4゛ソ!EナまMョカ웃AらfフWちなm5さc◀9Nちyき_j█そ2●l⁶き ま⬇️てし\nつ○モ&わ▮wよ◀「sg⁴ユモFYセておラ▮9ら t♥	Tキ^♪…、Oた゜ロdFEL、いハ웃チ_wすd!,G5ラリ☉³ノ[りBちb⁘、⬇️ナ☉N★5さ`zz5「キw、シJえV=て☉~☉uは☉♪っl○ハ u\000wシB ハ³5³さ<ヒBち\rkPいp^♥•そMヘく∧へ\\タQなQン1⌂ャwウラつ▒•\\ミᵉ¹せを●りャせきトc░ア゜⁷オ$Jウ○シホI8U。と➡️1😐YRいチてc❎\\ア@▮、ᵉ イAFEら、ゃf웃f➡️bカ2wす²z}き!yM¥Jᶠつ😐Cl~^\nG0wち][り☉JUxv♪゜ちiシ▮+ウ_J¥゛ロかR6░ちjい、ヘろ웃ᶜテ゛シゆwしっ\\ア=XH▮ちムネ☉@゛`0M웃\\そm🐱う「えレ●に\r`♪ョ!⁙ラたAVwせヲMサ)🐱c🅾️‖■ネW✽f」{▮⌂\000モ♥ン+5オ+ ヒ◜¥o■-jV゜w|!,S⬇️	ヤb⁵Fwよナ[ろらX▒H▶8フ▮@{zlち5セょ゜b░Lヌそ◀¥ロ●さ•て^Ewほ$ち9こなPよ。ワトIけ⬇️なOレて█¹ ソテ♥ン🅾️ち{へLれャLハニIm•Zへ■゜❎aOそ2♥ンヘ$Yサ⬇️ᵉこちン9そし²wわ1[キミLヌᶜ!Rみ-jR[ケWて、*6ᵉMwオ]、っ▮\\セfちャ゛2█レUレ0^░█◀	もつ c³	セ゛リ2えW.たkひ、?コ まzwて😐6‖え4シ⁸wさヲ⁴も♥」◆ロ◀⁘やFE▮ziむ2くと2█◜웃ト◜゛トojム⁘✽コ4⬇️³pそr;Zスト▶▶ょv…=🐱c=1⬅️よてWb⁵Hᶠそゆᶠ゜。Cl█f&ろ∧●m🐱゛み⬇️つホ#웃ᶜ▮てに∧そUテwそ⁸wろよそえ!。かEz🐱をkオユち,qち★カ▮Uい「is\nfメた「❎!0メOやわ ¹⁵iぬたznᶠOやア ヒv³9え³웃◆IM■cロ]⁴⧗:O⁸yY7\n◀/a゜●✽웃A∧Mヒ²&わA」zんMシzLヒSてそC\nフメ、hTLヒI,*、゜w█웃◝▮✽∧ゆf3\\そ◜ょ},ᵉwゃし。こU「t‖てす9☉🐱{🐱mH●ら⁘5♪ヲ5ユむvとヌwスG^⧗ハwケ➡️wケ:JK`゛&レl○HMユF!\"ッwみや!つ¥6◀Ewたッ♥ヲ◜Oやん5し|FETRよ^Nソに✽マUb⁴⁙、…QMンル、➡️ッEん\000M◜=^░゜zb)♥{Tdに🅾️゛⧗リ/6◆、ス🐱゜2ュ!こ&웃◜🅾️!EDち+C!☉⁸!QMFiき●mubむQ゜♥ら1Y;✽ト(웃vほ`🅾️	て▤]웃go¹6z$Kま⁶ふˇ。☉◆Eん○」{わ♥ッx▮゜ら^lI゛ソ゛RいタIm(つ🅾️ヨY85゜♥}[セけ🐱フう웃Qmそ0ネ[ヨRzmᵇwクM5ホまOそヘSみPLょ&wょつちaタNソや。ゅョちM,、░り^●웃l⁵イて◀\000Nソ⁙Lタ[░♥😐て‖レwス6✽■ウ!3Cた⁵め \000うあえ6wのヒちヲクつ▒」ちiコ⁴⧗「つヘモTっろ🐱}そZや□◀\n \\ョN▮;3²タ⬇️$K、▶HよJKっl⁶mそ0: メYebん▶7⌂!#っO▮エ[クは🐱}ᶜwチ◀✽も。 ウた「hチ♥oク-i8zm	⁴いL2▒I¹よれ t⬅️「お\n!□さち'%、ヘッ ヒg\000ほ⁶そ/sさ%おなPり\\アオ웃「B。に.Sまt゛ルメg]を5セア●シ◝つ♥⁶wほ+✽⁷M゜x「ち゛っI8フそ2▒6⁵ゃX🐱(!●wb³D●m▒I8H웃●え[ソ3゜◆」Iけ`、けrwき😐。ワᶠ░た◀wょ²てかにち♪Hけ⧗fつ8ソ☉\rミiふヘち+>ちs2!むノ-☉タ●b(◀⁘にNタ⁸☉/Cちそ@と*6そ{ッ タE、けょ ◜まmm█ち%ヲ^❎Y✽コ8そIテ!,AJ◆⧗。☉⬅️ちzr5し🅾️そ◆ニ  Vえ1キz]サ1vJ、はW●m⬇️ れᵉwイ⁘6‖そ¥nhLへV1cれ テ(6\nほZつ◆●っ%Nソぬ゜●ナ エ>4ラec]7そ055◜Rwス@。6O%/モ゜ミコ5レヨI8ら\"▥ア☉[⌂Fz♪Eッ\n⬇️ᵉ	てくャ。゛ワちkカLシ웃f`そて▶∧「ixd+。^~vN⁸や{ムむ\\ょっLネEそ★⌂wむ➡️、oKせwち▮、•[ヤレ⁘ロメ5さ▤ち	31}(ちkエ-i▮-hカIMxて▶い✽テカ_Zまちこほ1{%-iス^♥# ▥(³Wう\"よ_wシ=゜「ス テ█▮Jテ`のレZへ%🐱b8つ웃²^}●wケ❎て▶³。▒pせきウ▶Fョ✽⁷ソ6゛✽そˇ+v∧8◀⁘て゜1ヲちュもImヲ▶1³1⌂メ。ふ⁶z~ホFEて!ひロ!.ヤ1⬅️キ1}。MモeO■へつ`サwエP6ᵉいちTぬ◀⁘と゜kお`の⬆️³Gろ웃vuZん²-xた1}+てく◆つ■◆⁘ワ、QXろ▶8。-T⁸wとソ!うハそシ2Nソ,▮Hュ$khiへ?wし}\000◆ᶜcヌえn'へfき■5しX³ね]ちは゛つ●ャち♥Eて^ハ▮4ハ⁵こサてさ5。⌂)|⁷Mm<ユ!+\r8#f゜vひてさいちk6●けえFOこ^░y」ぬあ`のリY7♪🐱ヒ]5し@つモ[wイ゛⁵<ツz{と☉-⬅️。$\nMヤ,●こて🐱cI ツケb□♥l█「Eをった▶オ-j|✽と6゜♥| シ3て^P▶□p、…S1{リそ/トちkテ ▥ろ[ナメとfL▮Kz-iz1Y36゛0「えャl⁵らLシ⬇️☉N	O⁶K、x◝゜。?!1◆◀⁘☉▶」るfa🅾️Lネ9bむホ」|fwた@ち★シkオ◀Sセマちo「dに⧗☉-えZほpLニ¹FjD⁴れなb…あ☉🐱Vちjち²イ▶^すq웃!🅾️5ョ\rfく⁙1⌂ヲそ▮(▶8♥Fセ\000wイ」⌂ゆほ、n⁷5セ3てさ&\\チ_✽▮◜wな⁵Lム⁵゛=□●に。⁵Fっ♥さ●。⌂-wスEてa6Lヌと!●オせけ9░▥t³▮ねちaテて‖⧗てく♥f8k。⬅️いLヒ゛ wRwチ゜6ᵉ^✽よゆ●よヌ●るくちヲa⬇️□セ1😐レHにスFE⁙え1b{ン▮"
valid_up_counts = {0,736,1644,2564,3245,3548,4143,4780,5268,5433,5635,6010,6585,7278,7603,7865,8722,8800,9428,10988,11803,11992,12234,12645,12661,12842,12947}
valid_encoded = "ᶜ♥!ᵇ、カ\"q\000@ @(@H@Lき¹@=█\rき□@゛@*@□`³\000H¹ᶜ▒H▒`▒Mり▮🐱0⁴D⁴■dJ$JdEん▮hH☉ᶜ⬅️D⬅️H⬅️L⬅️Yょ8ム▮n0モ-ᵉ¹🅾️5ウᵉ.□.N.N🅾️□な0■`■1■5■I■`★M□¹ひ■ひ□TJtg4H▤2XJXI\000\" H²aる⁶$J$²dD⁷ᶜ♥H♥9んHh`h」そ!そ▮⌂D⌂H😐	ᶜᶜ♪H♪(N\rn6.ᶜ➡️H➡️\r■Iカᶜ⧗5⁙5クEク□tIx▮らMナJらK\000Mり\\³ᶜ⬇️D⬇️9³■c0░Mノ4⁷P☉IっJh4ᶜ4😐5ᶜMᶜ]ᶜ▮.8.Mモ□.6.6ウ⁙.ᶜ■ᶜ➡️2★!TMt	ひNTXˇ²xᶜ▥H▥¹²H⬇️I⁶Iな■■IカE□\r`² J D⁴]⁵□($ᵇMウ□..🅾️M■IカD⧗5\000¹█!█■ナJ N@□`□き⁙ ■さMさJ$D●■⁶\"&:&b&H⁷¹h■h」そIっ2HNH²h▮⬅️L⬅️`⬅️9ょYょJ⬅️Hᶜ▮ウ■なIなaな\rウ▮➡️¹■5■Iカᶜ⬆️H⬆️¹ひ\"tᶜ⁴<⁴Mさ、っ\rそ」そMそ\rn-tR4H³ᶜ⬇️D⬇️H⬇️!れIれb$H⁶Lヒᶜ⬅️ᶜ😐D😐▮♪\000イ!nᶜ➡️D➡️Iね゛qJq■r、SJ⧗Dˇ▮▤■yH☉²そ\000ケ4◀H░¹d■さ」そ²hH\n<\000(@9█\rき■き」きIきMき¹ナIナ2 b □`K\000H¹▮▒2▒\r²Iる\000⬇️D⬇️-れ(DHDHさLさ。ノN$Jろ⁙⁴H⁵▮⁶,⁶H⁶\r⁶5⁶Eを2●H⁸ (4☉Hそ4っ■H■そNH□そ³⁸■\nIゅᶠ\n/\n`ᵇ▮⬅️,⬅️`⬅️Iᵇ\rょMょYょaょ/ᵇ、ᶜHᶜ、😐H😐ᵉ😐¥😐Hnᶜ🅾️H🅾️Lな\000モ5ᵉ■な」な‖ウIウᵉ🅾️□ウ\000ヤD⁙D⧗8リIク¹tI⬆️□4D‖`◀Hナ5\000J@□`N█⁙ 4¹D▒M¹■aIりb!\000$D░\rさ■さIさMさH⁸▮H H▮h8hHhH☉\000っ8っ■そ9そIそJ(JHbhHᵇ4ᶜ5アIア¹\r	\r9\rIN■n」なN.F🅾️□なNウᶜ◆■oao.◆M■(T□TIx¹き²`8ヌ■b5る:#D⁴■dMさH⁶,●D●■f9fb&NF、っ■hIh¹☉■☉!☉5っ□HD⌂Hマ■jJ⌂Hᵇ,\rH\rL\r\\♪aイ.♪Hᵉ▮n■na🅾️▮□▮⁙D⁙H⁙ᶜ⧗H⧗	⁙I⁙²3□3bS²4-‖5ス²q▮@▮ら\r\000N ᶠ\000K\000(⁴(░J$N$b$D⁶\r⁷I⁷4⁸」そ-っ゛H2H\000♪▮nHn=ウN.,ᶠ`ᶠ,◆■oao:/\"◆b◆H➡️5カH★I□Iキᶜ⧗D⧗as▮⁘H⁘\000 I@■█J H¹Eりᶜ🐱 ヌIるJ🐱⁴⬇️Eれ\"#ᶜ⁴▮⁴,⁴D⁴H⁴\000Dᶜd▮d`さ	⁴¹さ■さ¹ノ□$□dJdNd,⁶4⁶-⁶■f-を5をMを□●J●L⁷H⁸,☉!HIhMっ□H゛Hᶜ⌂ᶜ⬅️H⬅️ᶜ😐D😐L😐-ᶜEアH\rN♪\000.\000モ\rᵉ¹🅾️□NHᶠ4◆、■H■`■L➡️I■Yカeカᶜ★H★`★I□5キ,⁙,⧗	⁙I⁙bS▮ルI⬆️,‖▮ˇIコIx¹き5るMるJ🐱	³ᶜ♥4♥H♥L♥▮hᶜ⌂D⌂X⌂!ゅIゅ4◆D◆	ᶠ■ᶠIᶠ:/ □0□`□H★L★d★MキD⧗E⁙6⧗²4`◀1◀¹xIナbナ っMha☉Hᵇ4ᶜHᶜIアHN■NIN-nI🅾️a🅾️■なaなaモ¹■=■<⁙D⁙	⁙H⁘ᶜ³9³M³D●LヒF●Hᵇ	ᵇ!ょIょ-ᶜH♪Jmbm▮■,■D■H■ ➡️H➡️	■I■2➡️Iク5▶-\000■`MきN@IdIさJ$N$H⁶4⁸■そ5っ□H:H⁙(\rᵉJウ⁙8M\000■@ᵉ □ 6 ゛@:`□きK\000Ic,░:d.✽」そb,ᶜ♪D♪■NIn*.Id,⁸■hIh」そ1っ5っ□hᶜ⬅️H⬅️4ᶜ4😐\rᵉ■なIなHナ³\000=d□&IそMなH➡️■■Iき▮h8h■そ5ょ	ᵉ■nIな□n゛n!T□464b4`ス■▤I▤ᶜ█I`H¹,▒H▒¹A9り.▒J▒\000B8B`B\000ヌHヌIB5る`c▮れacIdHし`しJe,●`をHヒ■⁶JgJ♥N♥Ih6(²H゛hJh³(⁙(4	²)\")J웃ᶜ⌂4⌂D⌂H⌂²*HᵇHk`kᶜ⬅️D⬅️H⬅️IKaKIkakI⬅️a⬅️9ょ²K\"k6⬅️J⬅️ ,(\r,\r8MHM\000m、mHm`mᶜ♪H♪Hイ¹\r9-IMIとJmRmbm³\rJ◆▮1H1`1\000Q▮q8qHq`qᶜ➡️D➡️H➡️ ねHね▮カ	■IQaQI➡️a➡️Iねaね5カIヨ²1□1:1b1⁙■,□4□ᶜ★4★D★H★8ラ	□%□-□5□I□IR5キ□R\"R:RbR²r□r\"r:rJr、Sᶜ⧗H⧗▮リHリ)⁙5ク²sJsRsbsHtIT)tJ45‖Hv`vIVIvIへJ6bvᶜ▤D▤H▤■xQスJxD」9セ、@H```I@a@I`I█a█9きIきaきᵉ □ J N@゛`J`b`J█N█^█=り<²■BIBᶜ³,⬇️H⬇️X⬇️1³⁙³、D dHさ`さIノJ$b$JdM⁵」わᶜ⁶4⁶D⁶L⁶0●L●5⁶Mを2●6●▮っ`っ」そIそ、\n、ᵇDᵇ`ᵇ、K▮⬅️\000ょ■ᵇ■kIkak5ょYょJkᶜᶜHᶜ]ᶜᵉ😐、MHm`mH♪L♪\000イI\r■と!とaと:mJmbmLᶠ`■H➡️L➡️Hカ9QIQ■➡️I➡️⁵カb1゛q/■L□X□▮★H★L★M□1キMキ\"rJrH⁙ᶜ⧗,⧗H⧗Hリ\r⁙5ク²sbs,ˇDˇEコ□ˇbふL∧」◀,▥H▥-」c9I\000! 」きJ`IdMウ¹ひJt、@!`a`H!H▒■a`B<🐱H🐱`cᶜ⬇️D⬇️H⬇️L⬇️I³5れ\rdJ$8しHし`し\r⁵▮⁶Hを`を\000ヒLヒafIをMをQゃᶜ⌂D⌂H⌂■\n8+`+ᶜ⬅️H⬅️▮ょ`ょIKIkak、ᶜHᶜ8,,\r mHmD♪H♪▮イ8イHイ`イM\rIMJmHウ■🅾️Mな²nᶜ◆\rエ、QHqIQ■qIqIカJ1□QbQ゛qH★IR1キ5キD⧗H⧗IクQクbS□sJsbs¹‖bふH▥;9c9H (@▮`H```D█H█⁘きHらHナ5\000■█I█\rき)き□ N □@゛@N@□`J`N`ᵉ█6らJらK\000⁙ (⁴D⁴L⁴H$、Dᶜ░<░H░\rさMさN$JDNDJdK⁴=☉a☉\rそ」そ!そ)そIそaそIヘJHNH□hJhfh□そLᵉH.(NHNHウ■N\rな\rウ)ウ1ウ=ウ□.Jn6ウJウbウH4▮tHt`tᶜ⬆️D⬆️H⬆️L⬆️`⬆️⁘ひ\r⁘■⬆️)ひMひ⁶4J4N4゛T■ヲH I@ᵉ J N N@J`⁸¹(¹H¹`!-りIり\000B▮B B▮ヌIBᶜ⬇️H⬇️▮れ ネ■cIノJd◀░8しHし4⁶`●`を■⁶■f□●J●\000♥IんIh」そ)そ□hᶜ⌂、⌂H⌂IゅDᵇHᵇHkH⬅️]ᵇIkIょJkJ⬅️Hᶜ▮,8,H,▮MHmᶜ♪D♪H♪`♪8イHイ■\rIM■とaとJ♪³-⁙- ᵉ`ᵉH.`.`nᶜ🅾️`な`ウHモINaNInI🅾️a🅾️」なIなᵉ.J.□NNN゛nJnbn⁙.c.aヤ(■,■H■\\■▮qHqᶜ➡️▮➡️,➡️D➡️H➡️8カ	■IQI➡️¹ね■ね5カJqbqfq■□IRaR1キ5キbR6★H⁙、S,⧗H⧗`リ□sJsbs▮ケ、ケIT■tMt\rひIひᵉ4¥464□TbTJt\r‖L◀ᶜ∧,∧D∧H∧L∧■◀Iv■へJ6□Vᶜ❎4❎D❎H❎¹wbwD「P「ᶜ▤HまHス¹xIスbXIセ \000▮@、@(@L@H`H█Hら\r\000-\0005\000■@I@a@■█\rき■き)きIきMき゛@J@N@J`²き□き\"き:き.ら6らJらbナK\000³ ⁙ ᶜ⁴(⁴0⁴▮dHdᶜ░0░D░H░\r⁴I⁴■░IさMさ□$J$□さJろK⁴D⁸▮((H▮h⁘☉D☉H☉Hっ!HIH-hI☉■そ」そ)そIそaそIっ□H*HJH゛hJhNh⁙(ᶜᵉ、N(NHn、ウHウ-ᵉ■N■🅾️9🅾️	な\rな\rウ)ウ-ウ1ウIウ□NbN゛n6ウJウ、ケ5⁘M⁘■t■⬆️」ひMひ゛T*TNT□tJtJ`⁙ ,¹H¹\000!▮!`!J▒Pヌ9BIBQBH³`c▮れI³Iれ\000し▮し し8しHし`しIわbe`を■fIgJ'IH\rhMhNHH⌂H+▮ょ`ょIKaK¹kIkak□K8,Hて。ムIムaムH\r▮M、M8M▮m、mHmLmPm`mHイ`イ¹\r■-a-9MIMIとaとJmbm³\rKᵉaヤ4■H■H1HqL➡️ ね、カHカ5■¹Q■QIQIqaqIねMね9カIヨ²■:1J1b1²Q□QNQ`2ᶜ★H★`ラIRaRRR\"rJrbr、S8⧗H⧗■s。ク□sJsbsN⧗/⁙1シD▤c9¹き# ᶜ⬇️H⬇️ᶜ⌂H⌂XᵇH➡️Iq\"RH⧗`◀ᶜ█,¹H¹`!D▒5¹■a⁵り	り□!8²H²▮ヌIBaB\"b`c▮⬇️H⬇️L⬇️▮れ`れ■³I³□#\000D□DH✽Hしᶜ●D●H●`●MをYんHhIそᵉ(6(5ゃ6웃ᶜ⌂H⌂`⌂Hつ\rᵇ‖ᵇ]ᵇIK¹kIkI⬅️a⬅️Iょ¹ミIミ□つ_ᵇ4ᶜHᶜ,😐8😐H😐IᶜIア!ム9ムIムaムJ😐,\r`mᶜ♪、♪D♪H♪Hイ\r\r¹とIとaと■イ5イ:MNM:mJmbmHᶠᶜ◆D◆H◆\\◆Hヤeᶠ■o5エIエMエ\"/.◆N◆<■L■81H1`1 qHq`qᶜ➡️D➡️H➡️L➡️\\➡️8カIQ■qIqIねaね⁵カ-カ1カ5カ!ヨIヨJ1b1□Q²q□qJq□ねbねH□8Rᶜ★H★IRaR□rJrJ★、SD⧗H⧗bs\000tIT\rt)tItI⬆️Iル\"4²T□TH‖ᶜˇ,ˇDˇHˇ■‖-‖ᶜ∧IV5シ□@⁙ \r¹,²2🐱D³ᶜ⬇️D⬇️H⬇️I³\000(!hIh⁴⬅️¹k!k9kIk1ょJk□M:mJmRm..H◆ Qᶜ➡️H➡️▮カ¹■	■■ね	カIカJqbq□R²r\"rH⧗/⁙□み▮@(@8@8`H`▮き⁘きLき5\000E\000I\000)`I`=█I█¹き」き)きMきIら■ナIナMナ² ᵉ □ * 2 F J N b □@2@J`□きJき*らJら³\000K\000<⁴L⁴(D(░<░D░Hさ¹D¹d=d9░I░□$N$JDND゛dbさJろbろ8⁸H⁸H(\000H、H(H8HHH▮h⁘☉,☉IH\rh■h!h-h⁵☉■☉9☉=☉¹そ■そ」そ9そIそIヘ*(.(2(:(>(F(N(R(Jh□そJそbそg((N8NHN▮nHウ-ᵉEᵉ■N9NaN¹n!n9n=🅾️Iな‖ウ)ウ1ウ5ウIモᵉ.□.□N²nNnN🅾️^🅾️*ウJウH4(T\000ひ⁘ひHケ=⬆️I⬆️)ひ.464F4□T□tJt■x■▤\rま-りᶜ⬇️D⬇️H⬇️IdD⁶`を¹ᵇIkDᶜ\\😐、MLMH♪J\rIな!ヤ\000QHQH➡️Iq\"18RbRJr,⁙ᶜ⧗D⧗H⧗HˇLˇ	‖■‖-‖bふ、@(@▮`H`H█Hら1\000■█=█I█」き)きIきIナMナ: N b ゛@>@J@N@J`N█□き\"きJらK\0004⁴D⁴L⁴(D(░<░HさLさHろ)⁴I░■ノMノ*$□さJろ(Hᶜ☉H☉⁘そLそ⁵☉■☉■そ」そ)そMそ■ヘIヘMヘJh(ᵉ0ᵉ(NHn⁘なHウ■N⁵🅾️=🅾️■な)なIな=ウMウIモ□N□n゛nJnᵉ🅾️F🅾️J🅾️N🅾️□な6ウJウ⁙ᵉKᵉ⁙.H4(Tᶜ⬆️H⬆️`⬆️=⬆️」ひ)ひ■ヲ\000h、@L@``¹`I`a`Mナ⁶ N@□`\"`J`H!`!¹¹■a²!³!H² B8BIBaB¹るIるH³⁸⬇️ᶜ⬇️4⬇️D⬇️H⬇️\\⬇️5れHdHし■⁶5を□●⁴⁷4♥■ん」んIんHそ4っIhIそJ(Jhᶜ⌂H⌂Hᵇ`+Hkᶜ⬅️H⬅️`⬅️	ᵇ5ᵇIkak」ょ5ょEょJk³+▮ᶜ,ᶜHᶜ▮, ,8,H,`,D😐H😐L😐`て	ᶜ]ᶜ¹😐9😐I😐a😐9ムIムMム□lJ😐、M8mᶜ♪H♪`♪Hと\000イ▮イ8イ¹\r	\r5\rIMaM■とIと□m:mJ♪:と、Nᶜ🅾️▮🅾️D🅾️`🅾️HなINaNInan⁵🅾️I🅾️a🅾️IモMモNNJn⁙.,ᶠ`ᶠᶜ◆4◆D◆H◆aヤ²/□ObO\"…,■0■▮1`1Hqᶜ➡️D➡️H➡️`➡️ カ¹■IQaQI➡️!ね9ねIねQねaねIヨ□Q:Q⁸★ᶜ★H★L★`★■□²r□rJr4⁙ᶜ⧗H⧗Hリ²sJs、T▮t、ケ\rtMひ■ルIル⁶4ᵉ4□4J4N4²t゛tᶜˇ4ˇDˇHˇLˇ`ˇ5‖,◀4◀ᶜ∧D∧IVIvIロb6▮▶,▶ᶜ❎H❎⁵▶P「ᶜ▤D▤axQヲᶜ▥4▥H▥`▥■」,\000H (@LきHら	\000」\000■@■█=█I█■き)きIき■ナIナaナ□ ゛@J@□`□き.らJらK\000⁙ c (⁴0⁴8dHdᶜ░(░,░<░H░■░I░¹さ■ノIノMノaノJDND□ろJろH⁸H((Hᶜ☉D☉H☉■☉=☉I☉■そIっ■ヘIヘ□H>H゛hJh(ᵉ N(NHNLなHウ⁵🅾️■🅾️■な)なIなaな)ウ-ウ5ウIモ□.JNNN>🅾️N🅾️ᵉウ6ウJウ⁙.(T▮t8tHt`t,⬆️H⬆️L⬆️Lひ⁵⬆️=⬆️)ひEケ²4□T゛TNTbT□ひ゛vD▤Mヲ■さ`!⁴▒ᶜ▒D▒H▒	¹M¹`c8しHしHそ」そ゛HJhH⌂、KL⬅️\\⬅️IkakI⬅️¹ミ\"kJkbk⁸😐5ᶜ`m ♪M\rJm,◆\rᶠ¹ヤaヤL■H1、QHq`qᶜ➡️D➡️H➡️L➡️Hね¹■■■9■!qIqaqIねaねJ1b1□Q\"QNQ□ねbね⁸★`ラIRIラaラ:R2★、SD⧗H⧗`⧗■⁙5⁙I⁙:sbs>⧗▮ˇH▥、S9きIきD▒ᶜ²H²■b9bD⬇️]ᵇ▮ᶜDᶜHᶜH😐-ア	\rJrH⧗5クJ I`\000!H🐱\000ヌIB、³H³`cIれHし`し\000を`をIをIg9Hah■そMそb(bHD⌂ᶜ⬅️H⬅️Iᵇ■kakJk4ᶜDᶜH😐■😐IてIムaム▮M`M`mHイ9\rIMaとJm⁘■H1`Qᶜ➡️D➡️H➡️\000カHカ	■I■IQIね□1Jq#1 ラ`ラ,⁙ᶜ⧗D⧗H⧗Iク:s2⧗▮4H4`4HtMtMひJ4Jt4ˇM‖、◀Hvᶜ∧4∧IVIへJv4「、XMまᶜ▥D▥H▥H`E\000I`M`Iき□ 6 J b ゛@゛`□きJらbら「¹D¹`!,▒H▒M¹Jaᵉ▒¥▒F▒J▒N▒⁙¹ᶜ²⁘²,²4²`²9BIBEるIるaるb\",³Hd`dadI░IさIノ□$J$Jd□さJさL⁵D✽8しI⁵」わH⁶2●J●▮HHh`そ4っIh2HNHbhᶜ⌂H⌂9J`ᵇᶜ⬅️H⬅️HつLつIᵇIkakIょ。ミ²kJk□つ4ᶜH😐	ᶜMᶜ⁵ア!ア5アIアMムF😐D\r`\r、MH♪L♪1\rI\r□MJmbモMエ゛oL■`■`1ᶜ➡️H➡️」■¹➡️I➡️IねaねIカ:1b1゛qJね\\★ ラI□IR□RD⧗]ク▮TH‖,ˇ-‖I‖5コIコMコ4◀D◀\\◀ᶜ∧H❎■▶\000 I@I`EH .■n-nIn\"nJウ\"tL@I`■きb ; H!ᶜ🐱D🐱H🐱`🐱LヌIBaBMる²bJbbb`c■³IれNCH$Id■さJdHしLヒM⁶H\nᶜ⌂D⌂H⌂`⌂8k!kIkak8,D😐H😐alIムD\rᶜ♪D♪H♪▮イ8イHイ`イ	\rIMaM¹とIイJm▮nIn²naヤ:O0■D➡️▮カ■QIQIqJqbqH□ R8RHR`ラIR■★,⁙H⁙、Sᶜ⧗H⧗bS:sJsbsc34‖H‖ᶜˇDˇHˇI‖¹ふIコMコbふ4◀■▶M▶H「4▥c95そIそH J``!H▒■¹¹a²!:!LヌIBIるJ🐱`c▮れ`れIれIDJ$ND゛dHし4⁶H●`●8を`を■⁶¹●;⁷Mhah」そJhIゃ▮K Kᶜ⬅️H⬅️¹ᵇIkak¹⬅️EょIょJk,ᶜᶜ😐H😐	ᶜ、\rH\r▮♪D♪\000イHイ9M¹と■とaとEイbMN♪H.▮N`nIN■nInanI🅾️a🅾️¹な6.J.c.Hᶠᶜ◆D◆H◆`◆ᶜ■\0001H1▮➡️H➡️	■I■IQaQI➡️a➡️IヨJ1²Q□QJqbq □H□ᶜ★、★D★H★\000ラ,⁙ᶜ⧗D⧗H⧗bsD⁘L4▮THT、ケIT¹t¹⬆️I⬆️Iル²4□TJtᶜˇ4ˇDˇHˇ■‖D◀Hv`vᶜ∧,∧D∧■◀■vIvav¹へIへaへIロb6□VJvᶜ❎H❎■▶4▤axᶜ▥4▥D▥H▥H (@8@⁘きLきHら-\0005\000■@¹█I█)きMき■ナIナJ`□き.ら6らJらK\000ᶜ⁴0⁴D⁴(Dᶜ░D░H░HろIDMさ□$JDNDK⁴H(▮Hᶜ☉D☉H☉Lそ-hah)そIヘMヘ□そ\rᵉ-ᵉMᵉ■N■n-n■🅾️■なaな⁵ウ」ウ)ウ-ウ=ウIモMモJN*🅾️□な6ウJウH4Hケ\r⁘I⬆️)ひ■ル□TbTbルᶜ「H「D▤ax8.9🅾️H`I`IきJ 8!,²L²H🐱`ヌIBaBJb`cᶜ⬇️H⬇️IdJdNdHしJ✽」そJhH\nᶜ⌂H⌂¹J▮KH⬅️¹ᵇIkak□KHᶜ8,H,¹LaLa😐Iムaム0\r▮M、MH♪Hイ`イIM9とaと゛MJm!🅾️9🅾️ᶜ◆D◆H◆■oaoaヤ,■H■ᶜ➡️H➡️`カIね	カIカaカ²1J1b1NQ2➡️#1IRaRJrbr、SLˇH❎,\000■`1`I█」き◀ 2█⁴░-dMd■h■そH`J$」そ5ゅ,♪H♪IんD●■f□&ᶜ⬅️H⬅️ᶜ♪Hqᶜ➡️IqaqIねMねNQ゛qᶜ★,★D★H★■rJr4⧗D⧗▮リᶜˇHˇᶜ▒L▒Iなaな)ウH`ᶜ♥H♥IんLᵇJ➡️¹░ᶜ●D●H●LH`そ■hJh▮TLTM	bM■■4ˇIふᶜ✽H`J$NDD⁶ᶜ●D●HᶜL➡️」そD⬇️IれLヒ■すᶜ⌂5ゅHk,★LD8h」そH\n5\000\rきIき□`Yり ヌD⬇️5³LD`ろ!░ᶜ✽5⁵ᶜ⁸▮hMそ□h4😐▮ウ`ウ5ᵉ■モIモ▮◆5□▮t□t4‖4ˇDˇHˇH@-\000D¹`¹ᶜ▒D▒」りYり]りJ▒▮🐱D░\rさ¥$b$J░HHJ(JhHᶜD😐L😐X😐Kᶜ!.」な□n□なJobo■t□4▮xHxL@2 □`ᶜ⬇️D⬇️X⬇️Yれ□⬇️¹░a░Jろ]⁵⁸⁸aゃMᵇX😐」イ\"♪!NIn2.Jウ-カX★aR□★D⧗¹⁙b3□464!コaコ3」Iq5□L@H░、⁷H⁷\rんEんHH、N▮nMモbモI■,⁘H⬆️\r⁘=⁘□@¹¹LDJさ5をIをMをJ♥\000H(HHH」そᶜ♪H♪▮n□Nᶜ➡️EカH★LT8ケMルJひ4ˇ-‖D²Mる■hD\nD⌂H♪`□H★D⧗	ク=ク:3▮ら■ナJ`Iさ,⁷D♥	⁷■せIん/⁷HHH\r5⁙■s▮tI⁘▮∧¹▤Hヒᶜ⌂ᶜᶠIカ-キ▮`IさMさN$b$Jd■んLHIh□h▮モ■NJ$NDYんᶜ⌂L@M`I█,🐱L⁴HD0░■░N$-⁵H☉■h■そ」そNHJh▮n■🅾️IなLᶠ,◆Iエ-ク²3▮tItMt⁶4J@J$」そJnH■H➡️■■E■■そ`!■aᶜ🐱D🐱H🐱L🐱¹²²bJb`cᶜ⬇️D⬇️H⬇️▮れIれ¹さb$Hし`し5⁶IHIh■そIそMそJ(b(゛hᶜ⌂D⌂H⌂`⌂■\nE\n$ᵇIk□Kᶜ😐H😐,\r`MHmH♪\000イ8イHイIMaと5イIイ2♪E▮ᶜ■▮Q Q`QHqᶜ➡️D➡️H➡️■qIqI➡️Iカ:1□QJq R\"rJr,⁙ᶜ⧗H⧗as:Sbs²ク、ケ\rtMt¹ひIひᵉ4Jt□ひH‖,ˇDˇHˇEコJˇIへaへᶜ❎H❎ᶜ▤D▤■ま□8ᶜ▥H▥I`□ J N □@N@J`⁙ ,²H🐱LヌM²IB\\⬇️H$HdIdIさJ$□D⁙$■♥4っMそNH、K\rᵇ¹kIkak5ょJkbk,ᶜH😐■😐a😐F😐▮MHm`mI\rIMaとJmHn⁘な,■D➡️H➡️¹■aq!➡️I➡️Iねaねb1□R²rJrbr,⁙H⁙、Sᶜ⧗H⧗\r⁙Eク²sJsJ⧗²クD⁘Htᶜ⬆️DˇD∧ᶜ▤D▤axH▥c9J J`D▒:!H🐱▮ヌPヌ5²IるJ🐱H⬇️▮れIれHさ\rd\rさMさ□$J$b$NDᶜ✽D✽H✽I⁵゛ebe`をLヒIをᶜ⌂H⌂Dᵇ、Kᶜ⬅️D⬅️H⬅️L⬅️!ᵇIK■k9kIkak!⬅️I⬅️a⬅️Iょ゛k2⬅️,\r\000M、MHmᶜ♪D♪H♪I\rIMaとIイᵉ.Hユ□…ᶜ➡️D➡️H➡️■■IQI➡️Iねb1NQ゛qHR`ラIRJrbr、Sas¹は□sJsDˇHˇᶜ❎D❎H❎M▶c9\rdᵉ.H (@⁘きHら-\000E\000■@I@a@■█1█I█a█■き)きIきIナ□ b ゛@*@J`²き6らJらbらbナK\0000⁴H⁴(D(░D░H░L░Hろ■░゛DF░Jろ\"ノ:ノK⁴(HHHᶜ☉D☉H☉=☉I☉」そMそIヘJ(N(*H□hJhNhLᵉH.(NHNH🅾️Hウ」な\rウEウIモ².J.b.゛NJN²n□nF🅾️N🅾️6ウJウH4ᶜ⬆️H⬆️`⬆️⁘ひ\r⁘■TaT■⬆️=⬆️」ひ)ひEケF4゛T□tbtO⁘`8D▤■ヲ□xI`I█a█,²J🐱4ノ`●`を■⁶■fQをIせHhIhIそNHHk`⬅️¹ᵇ	ᵇ■ᵇ9ᵇIKaKakH😐\000mHmPmH♪amJmHn`nInJnbn0■`■H1`1▮Q8qHq,➡️H➡️\\➡️▮カ8カIQaQ■➡️I➡️□q゛qJqbq2➡️³1⁙1²R□RL⁘HtD⬆️L⬆️■tIt\rひMひJ4゛t\000ˇIv゛vᶜ❎H❎■▶D▤■x■まH (@L@Hら-\0001\000■█	き)き■ナIナJ@□`\"`J`ᵉ█J█K\000(⁴ᶜ░D░H░L░M⁴\r░¹さ5ろ□$゛DJdD⁸H(ᶜ☉D☉H☉Hっ-h□H*HNH゛hJhNhfh⁙(g((NH🅾️Hウ\rなIなMな□.6.b.゛NNN゛n6ウJウbウ⁙.HケM⁘=⬆️゛TNTD▤D¹`!bAIBJ🐱`c▮れ`れId:$Hし`し,⁶`を■⁶9⁶■faf□●J●I	Ikakᶜ😐D😐H😐L😐 mHm`m イ8イHイIMaMaと,■4■\000QIq-カEカJ1b1゛q⁙1c1ᶜ★▮★,★H★-□IRbRJrbr5クᶜ▥▮▥H▥-」c9H🐱ᶜ⌂H⌂H⬅️Hq□s\000!`!■a cH⬇️▮れ\r³I³■#9#:C▮しHしᶜ●D●H●HhahIそJ(²hJhNhIゃ、ᵇHᵇ\\ᵇ\000⬅️ᶜ⬅️H⬅️Ikak=ょN⬅️:つHᶜ`ᶜ\000,▮,8,H,ᶜ😐D😐H😐`😐	ᶜ5ᶜ¹😐■😐a😐IムN😐、M`m⁘♪T♪Hイ¹-‖イJmInᶜ◆D◆H◆Iエaヤ▮181H1\000qH➡️I■I➡️!ね□1゛q2➡️H★IラaラbRJr、Sᶜ⧗D⧗H⧗HリEク、T`THt`t▮ケ■4MtI⬆️a⬆️MひIルJ4JT⁙4c4,ˇMコ`VHvIVaVIロbV,「D▤ax,」D」ᶜ▥D▥H▥5セ9セI`Iき□ J J`F▒9BIBIDaDIノ□DNDNHJhHk▮⬅️\rᵇakJk,😐¹😐a😐Mア,\rH\rH♪L♪	\r■\r!\r=\raと¹イ1イ□-:-Jmbm²♪J♪▮n\rᵉ、■▮1H➡️■qI➡️a➡️■ね□R:R□rJrH⁙>⧗I⬆️4「D▤N@J`N█# H░NDNN.🅾️-xMきᶜ▒,▒D▒H▒!aJ▒`cJeH⁶▮ヒMを□●HᵇHkL⬅️IkakaミJk,😐■😐Iムaム、M▮イHイIMaと;-5エ9ヤaヤbOHqIqaqIね5カIカJ1゛Q゛qJq9★I★Jr、SH⧗NTᶜˇ4ˇDˇHˇ9▥▮@▮`H```)\000E\000I█\rきIき□ b J@2█F█⁙ c 0⁴4⁴\000$▮$`$▮dHdᶜ░(░H░L░I⁴IさMさK⁴,⁸H⁸H(▮h⁘そLそ■H■☉I☉Mそ*HJhfh0ᵉLᵉ▮. .H.`.▮n「ウI🅾️1ウ=ウIモb.JNNNN🅾️□なJウ⁙.ᶜ⬆️D⬆️H⬆️`⬆️Hケ■⬆️I⬆️5ケ□tJt。ヲ. F J ゛@J`6らJら■🅾️JウH`HきI`b J`b`4¹D¹ !8!`!I¹IりL⬇️ac:CIdJ$ND゛dbdD✽Hし\000をIをD☉」そI	Hk`k0⬅️H⬅️Hつak■ミIミ8,D😐¹ムᶜ\r、M⁘♪D♪Hイ¹\r‖\rIM¹と‖イK\r;-`.Hn`n`🅾️Hな`なHウaN\rnInanIなaなIモaモJ.b.□NbN(ᶠ)ᶠ,■H■ᶜ➡️H➡️▮カI■I➡️a➡️Iヨ□QbQLラ□R、SHリ`リ²s、T▮ケIT²4ᵉ4Jtbt4◀HvHへIVIvIへH❎1「■x,\000H ▮@▮`H`⁘きLき-\0005\000=\000¹█■█=█I█¹き\rきIきMき■ナ。ナaナ>@J@□`□きJきbきK\000⁙ L⁴▮$8$▮Dᶜ░(░4░H░L░▮ろ8ろ5⁴Iさ□D□さJろK⁴▮H▮hHh⁘☉⁘そLそHっ■H-h■☉a☉\rそIそMっ■ヘIヘMヘaヘ□HNHbH゛hJh⁙(4ᵉLᵉ`nHウ5ᵉIN¹🅾️■な‖ウ1ウ■モJNfNJn◀🅾️>🅾️N🅾️□なbな.ウ6ウJウIq.1H4ᶜ⬆️,⬆️H⬆️▮ひ⁘ひ■⬆️=⬆️\rひMひ▮X▮x■X■ヲMヲ8@¹き9きIきᵉ J ²きIBaBH⬇️JDNDHしH⁶▮hHh\rh■hMh=☉:(□H「ᵇDᵇHᵇ、KH⬅️L⬅️Hつ`つIkak。ミIミaミ8,¹😐!😐a😐Iム`m▮イ`イIMaMaとaヤ5▮`q▮カIqaqIねb1゛QJ➡️`ラ¹r■r!rbR:rJrbrbS²sbsᶜ▤■xMス□X■そI`Iきᶜ▒H▒\rdIム▮\r■\raとIイ³.Iエ9ヤaヤbO,■ᶜ➡️H➡️5カIカJ➡️H⧗ᶜˇHˇHきJ M¹■aJ▒(🐱IB,³ᶜ⬇️H⬇️!#NCI░JdHしe⁵JeHをH⁷(H¹HIHQHIhahIそMそJ(b(゛hH웃I	!)0\nH\n\000⌂H⌂1\nJ⌂,ᵇᶜ⬅️D⬅️H⬅️\000つHつ\rᵇ9kIk¹⬅️I⬅️5ょIょ□KJk²つ□つ²ょ,ᶜ\000,ᶜ😐H😐a😐³,<\r▮M、MHm`m イHイIMaM²M□MJm■n¹🅾️\\ᶠao!ヤaヤJ◆0■Hq`qᶜ➡️0➡️H➡️1■IQIqI➡️IねIカIヨaヨb1゛QJq`ラIRIラ²r□rbr、Sᶜ⧗D⧗H⧗\000リHtHひ、ケ\rt1tItMtIひMひ□T□t4ˇDˇHˇ	コᶜ∧IVI∧□Vᶜ▤D▤`▤■x4」ᶜ▥,▥D▥H▥H```\r`I`■█Iナaナᵉ □ J N N@゛`J`□きbき4▒H▒LヌIBD⬇️▮れ`れHd`dId⁙$□eJebeHh、っIhJ(NH⁴	²)ᶜ⬅️H⬅️9ᵇ]ᵇ9kIkI⬅️IょMょIミ□つ,ᶜH😐	ᶜ5ᶜIムaム▮M、MHm▮イ¹とaとb-JmDᶠH1`1HqH➡️Iq¹➡️I➡️Iね5カIカb1□Qfq⁙■IラJrH⧗Hリ、T、ケ\000ˇᶜ∧D∧、サᶜ▶ᶜ❎D❎H❎/▶ᶜ▤MきIBᶜ⬇️D⬇️H⬇️I░HヒLヒ⁴	²)ᶜ⌂D⌂H⌂!ゅDᵇ、K9kIkakJk2⬅️J⬅️8,P\rHm▮イHイaMaとJmIᵉao9ヤaヤᶜ➡️▮➡️D➡️H➡️bRJr、S▮リᶜˇDˇHˇ4▥ᶜ█`らᵉ J b N@`!IりIBJ🐱ᶜ³¹#J$4⁶4●HをHヒᶜ♥(Hᶜ☉IH」そ□HNHH\nᶜ⌂H⌂`⌂I\nQJ2⌂Hkᶜ⬅️H⬅️`⬅️IK¹k9kak■⬅️I⬅️5ょIょJkHᶜᶜ😐D😐H😐`😐■ᶜ■😐4\r\000mHmᶜ♪D♪H♪`♪ イHイIMaMEイ、NHn`n`🅾️Hな¹NINaNanIなIモᵉ.J.゛NJnbn□な(ᶠᶜ◆D◆H◆aヤ、■,■H■▮qI■IQ■➡️Iねaね□QNQbQᶜ★,★4★D★H★`★²rJr、S,⧗4⧗asbs⁘ひHひ、ケ\rひ\"4J4□TJt\000ˇᶜˇ,ˇ4ˇDˇHˇ▮6`vH∧⁘へHへIVIv□6:Vᶜ❎H❎H「ᶜ▤■x`!IB¹こᵉ⬇️J$Hし`しD●`をJ♥H⁸HᵇH⬅️IKaK9kIkak4ᶜHᶜHて	ᶜ\rᶜEア。ムIムaムJ😐、MIMaMJmHqIqaq²1b1NQJq`ラIRaRIキbR、S¹⁙³9c9Ix²#:#¹さIさ▮を」そH⌂Hᵇ「⬅️H⬅️	ᵇ4😐Iて▮m\rᵉᶜ◆D◆H◆\000ヤ`ヤIエ\\■5キ▮リ ,H,)■J$ᶜ♥H♥EんD☉ah」そD⌂■jIな,⁙	⁙J⧗Mき,⁴H⁴H░Mさ1っMっᶜ⬅️D⬅️H⬅️¹nIn-xIxD⁙9ナᶜ●9ょJ⬅️0■IきJ`Iな⁸⁴,⁴2░J░⁸⁸ᶜ⁸,⁸2☉D⬅️゛k▮ら8らI█\" 2█D¹ᶜ▒□▒▮h8hHh■そ9そX😐Mᶜ]ᶜᶜ◆,◆IᶠaoMエ:/ ラ`ラ■きMナ2 ]り⁙¹,🐱■b」るF🐱J🐱N🐱X⬇️\\⬇️¹³■³-れYれ\"#□⬇️Mノ2$N$D✽]⁵Iわ²%4⁶■fMを5っᶜ⌂D⌂■j`ᵇL⬅️ᶜ♪D♪M\r⁶.N◆6➡️L★9ラ,⧗D⧗-⁙I⁙²3:3¹t□464NTD‖M◀	³\r³5³	\rH⁙5エ▮`□`Hh」そᶜ⌂9N■なIなaなH¹H♥ᶜ⬅️H⬅️L⬅️▮\r ★□★■s`ヌI░D♥ᶜ☉H☉b.H⁸`\r².■sᵉ J L」IナMり,²IBaBᶜ⬇️H⬇️H⁵\000しH⁶D●Hを`をE⁶²&IhD⌂H⌂`⌂<ᵇ=ょ▮,8,H,P,H😐a😐5アH♪Iとaとbm4ᶠᶜ◆D◆H◆IQIqIヨ²q.➡️`★■ラIラIクITMひIルH‖,ˇ4◀ᶜ∧■▶c9IきJ`,▒I³IdadIノJ$⁙$H✽Hしᶜ⁷J♥⁴ᵇ9kIkak▮,a😐aとIな\r■IQaQb1□RJrJ★H⧗5クbs■ひᶜ∧,∧■◀¹`Iら\000!H!ᶜ▒D▒H▒Hし`し`をMをᶜ⁷IkJka😐aム8イIM■と!とIとHq\000カ□1I★ᶜˇDˇHˇ`ˇ¹きᶜ▒H▒9BIBaBIる,⬇️K⁴IせIそMそNHᶜ⌂D⌂H⌂`⌂-ゅᶜ⬅️H⬅️IkakJkbk5アIアH♪HイbmIN0■2➡️H⁙bs6⧗,⁘HケIT■tJ4NTD◀ᶜ∧Ivavᶜ▤H¹H▒IるH³▮れ`れIれ,⁶2●▮H`HJ웃ᶜ⌂H⌂J⌂<⬅️Dᶜ8,`,Iムaム8MIMaM²m:mH◆5エ,■L■,➡️H➡️EカJrH⧗bsHˇ■‖¹█⁴¹D¹⁵り\000ヌIB ³H⬇️I³E⁵IをJ●,⁷(⁸HhH☉Hそ¹HIHIhI☉」そIそH\nI\n0ᵇH⬅️‖ᵇIᵇ¹ミHᶜH😐)ᶜIᶜ■😐▮\rH\r`m、♪H♪\000イHイ!-JmS-IなHᶠHヤ)エYエ¹ヤJ◆N◆H■L■IQ¹➡️Iね9カIカ\"1NQbQJqc1\000ラ■★,⁙H⁙I⁙\"s、ケ\"4R4b4,‖H‖H◀P◀ᶜ∧(「■xIスI」9セJ ⁴¹D¹⁵りIB▮れ`れ、DHさIDId¹░9さIさIノJd□さE⁵²♥J(<⬅️1ᵇIkakIミaミJkbk8,H,IムMムaム⁘\r、M8mIイ□mJmIᶠH1,➡️HねaQ¹➡️■ねIねIカb1□ねD□JrH⁙、SH⧗-ク,ˇ-‖H❎ᶜ▤D▤ `Hき!@Iき。ナJ`³\000# \000d゛dJd¹.J.2🅾️HtL\000(@」き▮! ! ▒H▒¹aIBaB8c`c,⬇️▮れHさJ$□さJさLヒ!ゅ`⬅️1ᵇIkIつIょIミJkbk8,H\r\000mHm`mH♪Hイ5\rIMaMIイ□.*NH◆¹ヤIヤ`1IQIね\"14□bRJrᶜ⧗D⧗H⧗▮リHリbs.⧗H‖I◀」きIナNd(H「☉IH」な‖ウ▮ケft(@HらIナ. J F█□き□らᶜ⁴ᶜ░,░H░-dMd▮そ゛HJh□そH.(N-nIモ>NJnN🅾️□ウ6ウJウH4.4F4J4Jt¹`IきIナ4¹IりIdHし²e,⁶H⁷4♥Ig■そI	0\nH\nD⌂²*2⌂HᵇIょP,P-8mIMINaN\".(◆Hヤ■/¹ヤ ■H■L■H➡️¹➡️Iカ6➡️J➡️H★、SIクYク²4,\000H LきI\000M\000」きIきeきN█K\000<░」さ□ろ-h¹な■な5ウ 4)ひJ ■¹IれJ⬇️S#I⁵,●H⁸\"*J⌂(ᵇ4ᵇHᵇ つIᶜKᶜI■□1²qJ➡️:RH⁙、SI⁙J⧗J▥J@-d¹d(@I@」きJ J`IりNCH⬅️■ᵇ5ᵇ]ᵇ■ょ▮mHmH◆■■H⧗▮リ\" \000a,▒¹¹I¹Eり²!ᶜ🐱D🐱H🐱L🐱`🐱IB`cᶜ⬇️4⬇️D⬇️H⬇️■cJ$:さ4⁶D●,⁷D⁷、HHHHh、っ¹HIHᵉ(J(b(゛hbhᶜ⌂D⌂H⌂Hマ5\n²J`kIkHᶜH,`,ᶜ😐D😐H😐¹ᶜa😐Iム \rH\r▮M、M▮mHmH♪IMaMJm,◆5ᶠIᶠ■/□O、QHq`q▮➡️H➡️▮カ8カI■IQaQIねMね2➡️²ねᶜ★D★H★\"R:RRRbRJr、⁙、Sᶜ⧗4⧗D⧗\\⧗▮リ リHリ`リ■S□sJ⧗4⁘、THtHひ、ケ\rひ²4,‖H‖ᶜˇDˇHˇ²5bふᶜ∧D∧5◀IVIへaへᶜ❎D❎H❎awᶜ▤D▤5「>▤D」ᶜ▥H▥Iセ#9;9、@H```Hき`きI@a@I█IきMきaきIナMナ□ 6 J b □@゛@N@J`□きbき⁙ 4▒`BH⬇️▮れ`れ2⬇️D⁴、DIDIノJ$b$□DJd⁙$□eJebe,⁶D●H●▮を8を`をM⁶J'²♥J(゛H4ᶜᶜ😐,😐H😐¹😐■😐5アF😐HmH♪HイI\rIイ□M\"m:m■なD◆\rᶠ²/²oᶜ➡️H➡️IヨH★Jr、S▮リ>⧗、T8THt、ケH‖▮ˇ,ˇDˇHˇ5‖I‖I◀H❎I▶H▥³9c9¹き■き」きᵉ J N ,▒D▒²!\"! ヌLヌM²IBD³IれHさ▮ろIさJ$J░□さD✽H✽Je4⁶D●▮をLヒ■すᶜ⌂4⌂D⌂H⌂5\n⁸ᵇIkIょJk4ᶜHᶜ\\ᶜ\000, ,8,H,`,ᶜ😐4😐H😐`😐Mᶜ¹😐IてIア¹ムIム⁸\r、MHm`mᶜ♪4♪D♪H♪`♪\000イ8イHイ`イ5\rIMaMIとaとIイJmbm2♪^♪IなHᶠH◆\rᶠ5ᶠIエaヤH■IQMカIR■rIラJr ⁙H⁙ᶜ⧗D⧗H⧗▮リ8リHリ□3ᶜˇ4ˇDˇHˇ\r‖Eコ□5¹█9き、@H`HきI█a█IきN@゛`□きD¹`!ᶜ▒H▒IりJ▒,²▮ヌHヌ■²I²IBIる2🐱J🐱4⬇️H⬇️▮れJDJebe4⁶H●`を¹⁶	⁶■⁶5⁶!を5をIを4⁷HhIそ■ヘJ(H⌂Ikak」ょHᶜᶜ😐H😐D♪\000イ▮イHイ`.ᶜ🅾️`🅾️\000なHな■ᵉINaNI🅾️IなaなIモaモᵉ.□NJnᶜ◆D◆H◆aヤ,■4■Hq`q,➡️H➡️	■I■b1ᶜ★,★4★D★H★bR、⁙H⁙H⧗	⁙Iク²S²s□s:sJ⧗ᶜ⬆️、ケ■⁘I⁘¹⬆️\rひIひ■ルIル□4J4b4□TbTJtL‖ᶜˇDˇHˇ`ˇ■‖4◀ᶜ∧D∧H∧av\rへ■へIへIロb6□VJvᶜ❎H❎,「4▥、@J█ᶜ▒H▒²!H🐱\r²IBaB□\"H⬇️	³Iれ\000しHしᶜ●D●H●IkJ⬅️Hᶜ ,4😐■😐a😐IムaムD\rH\r、MH♪L♪▮イ イHイIMJm5ᶠJ◆、Qᶜ➡️D➡️H➡️\\➡️ カ`カ\r■IQb1□ねD★`ラIRJrbrJ★\000⧗ᶜ⧗D⧗H⧗bふᶜ❎D❎H❎I⁴I█ᵉ N □@\000🐱▮🐱²\"」そH😐。ムH♪H➡️	■ᶜ★H★5□I□-キ²Rᶜ⧗H⧗▮リ	⁙²sᶜ█□ J H▒H²X²ᶜ🐱D🐱H🐱▮ヌ ヌ8ヌHヌIB■b5る:\"0³▮れ\r³ac□#.$¹⁵	⁵H●Hを	⁶¹●MをJ●■ん²♥²んHh9HIH■h-hIhI☉Iそ□(J(□HNH⁙(EゃD\nD⌂H⌂I\nIゅ0ᵇDᵇHᵇ\\ᵇH⬅️	ᵇ)ᵇIᵇIkI⬅️a⬅️JkbkJ⬅️²つ²ょHᶜ\000,8,▮😐`😐■ᶜ¹😐a😐H\rL\r m⁴♪ᶜ♪、♪H♪L♪\000イ▮イ8イHイ`イ¹\r	\rI\raMam¹とEイIイ□M²m:mbm.♪J♪Pᶠ■o\"…▮■、■H■、QHQ`qH➡️▮カHカ¹■\r■¹QIQ■qIqaqI➡️5カEカ²1\"1b1□Q゛QJqbねH□ᶜ★D★H★`ラIR5キ²R□RbRJrbrJ★ ⁙、Sᶜ⧗D⧗H⧗`⧗Hリ5⁙9s□sJs³3;3`4HtIt\rひ\"4bTJt□ひc44ˇ■‖5‖I‖ᶜ∧IVaVIへJ6ᶜ❎H❎1▶I▶4「H「▮8ᶜ▤EスIスNXᶜ▥D▥H▥`▥N▥²(H`I`a`■きIきMきaき□ □@゛`J`b`Iり\000BHヌIB,³¹³	³!³■cHdJ$JdHしIそMそaそ゛h¹JHᵇ\000+Hk▮⬅️	ᵇ)ᵇIk5ょJkbkH😐Iアᶜ\rHmᶜ♪H♪▮イHイ²M□M゛M²m:mJ♪J🅾️Jウ、QHQ`Q▮qᶜ➡️,➡️D➡️H➡️▮カ-■I■M■IQ■qIqb1□Q,□H□,★H★`ラ	□■の5キbR:r,⁙ᶜ⧗D⧗H⧗8リHリ	⁙‖⁙I⁙-ク□3:3□TᶜˇHˇᶜ∧IvMまH▥⁙9;9F.QらYら2@.█H²▮ヌLヌIBaBIる²\":\"`c▮れ`れI³NCIさ□さHし`しbeHをLヒH⁷I⁷ᶜ⌂H⌂²*²ち、KHkD⬅️H⬅️Hつ¹ᵇ9KIKaK■kIkEょIょ¹ミJkbkfkᶜ😐8😐D😐H😐	ᶜbL▮\rD\rH\r▮M`MHmᶜ♪D♪H♪▮イHイ`イ1\rI\r■MIMaとEイIイJmbmJ♪ᶜ➡️H➡️\\➡️\r■5■IQaQaqIカ゛qJね³1、R8rD★H★8キIキ²RbRJrbr、SD⧗H⧗I⁙□3Jsᶜ❎4❎D❎H❎□w>❎4▥c9■░IきJ``!H▒`▒■¹■a\000ヌ ヌHヌ`ヌIB,³,⬇️0⬇️D⬇️H⬇️▮れ!³J⬇️J$Iわ`を.●,♥IんJ'²♥F♥■hIh²(□(NHJhIゃH⌂I\nIゅ,ᵇDᵇHᵇHk`kᶜ⬅️H⬅️¹kIkak:kJkKᵇH😐¹😐a😐J😐ᶜ\r,\rH\r▮m8mD♪`♪8イHイ	\r■\rIMIイ□m゛mbmH.、NHn`nᶜ🅾️IN¹n!nInan」なIなaなIモJ.b.□NJn□なᶜ◆D◆H◆`◆aヤbOJ◆▮■,■H■L■`■,➡️H➡️¹■■ねIね5カ。ヨ²1:1□QJqᶜ★H★`★IR:RbR□rJrᶜ⧗,⧗4⧗H⧗L⧗`⧗Hリ`リ‖⁙I⁙Eク□s:sJsbsJ⧗³3、TH⬆️\rtItMt\rひMひIル64□TNTbT゛tᶜˇDˇHˇ■‖H◀ᶜ∧D∧²6H▶■▶H「■xIxᶜ▥H▥IセL➡️8ヌ	²\r²5²IBaBEる:\"J🐱`c▮れE³²#Hし\"e\000をHを`をagHhIhJ(NH)	、KLKᶜ⬅️H⬅️`⬅️\000ょ■ᵇ¹kIk□K゛KI😐a😐IムbLJ😐、M\000イ▮イ8イHイI\rJmRmIな,■H■ᶜ➡️H➡️\\➡️\r■IQaQIqaq²1□1\"1J1b1\"q²ねD□\000Rᶜ★D★H★L★\000ラ`ラ	□M□IRaRIキ□RbR゛rJrbr、Sᶜ⧗D⧗H⧗\000リI⁙5クJsᶜ❎H❎(」c9■t-`Dᵇ、\rH\r\rᵉ¹🅾️■モIモaモ゛1\r□ リHリ`リIシH░I█IきH▒I¹IA¹a⁵り▮ヌ8ヌ□\"H³E³□さ\"さHしH⁶`をEを,⁷ᶜ⁸HそIHIh²(R(□そᶜ⌂D⌂\000ちHᵇᶜ⬅️¹kᶜ😐D😐H😐¹😐J😐H\r▮M`MPm¹とaとIイ²♪Hᶠᶜ◆H◆9エ¹ヤ■ヤaヤH■8QHQHqH➡️	■I■IQaQ□1,□ ラbr,⁙、SH⧗I⁙bs、TMひ,‖D‖,ˇHˇXˇbふ⁴◀H▥E」I」¹4▮きI`IナJ ゛`J`(▒,▒IB`cHd`d\rd■d⁵░I░Iノ□D⁙$:&J●Hそ、っNH□そIᵇakHᶜIてMムH♪IなD◆Mᶠ,■Hq`q¹QIQ-カJqfq□ねbねJrH⧗=クJsbsIT■⬆️I⬆️,ˇDˇHˇJˇH6ᶜ∧,∧D∧■◀avbVJvJwJ❎9\000¹き\"`¹🅾️▮∧ᶜ²D🐱▮ヌLヌIB-る,³ᶜ⬇️H⬇️EれJ⬇️▮DHさ□さH✽Hし`しbeD●HヒLヒ-⁷⁴\n、\nP\nIk ,H,IムD♪H♪¹-aと5イ゛mHᶠaヤ⁴▮Iqaq ★□RJ★D⧗H⧗\r⁙5ク□3:3b3bs,‖ᶜ❎D❎H❎■▶0」\"NHナ`!■aaaIB,³`cH⬇️J⬇️IdHをYんIhahMそJ(□HbHH⬅️IkIょᶜᶜHᶜ4😐H😐	ᶜ!アIアH\r▮MH♪L♪HイI\raと/\rH.MᵉINaNIなIモ□N,ᶠ¹■I■IQ¹➡️I➡️゛qᶜ★D★H★`★,⁙、Sᶜ⧗D⧗H⧗2⧗\rt■tItIひaひIル▮‖H‖,ˇ2ˇ`◀ᶜ∧IvJvbv,▶H❎P「ᶜ▤H▤`!¹¹\000ヌ`cD⬇️H⬇️▮れ■³゜#Hし▮⁶ᶜ⌂H⌂¹kIkH,4😐a😐aとHq`qIqJ1□Q:SbSbs⁘き¹`」そ5ょ。ム²Rᶜ⌂4⌂D⌂2⌂ᶜ➡️H★I□Jr4⧗D⧗HリHˇ」き、⁴!d□DK⁴H⁸ᶜ☉M⁸JhL웃H🅾️■n!nIn0²F🐱4⁴D♥H♥□'b'D⌂\000➡️ᶜ⁙,⁙4⁙H⁙L⧗/⁙!tHナI`D⬇️ac5ろ2░2HNH2☉J.F🅾️■xIxK\000,⁵ᶜ✽D✽■⁵「ᵇ4⧗D⧗I█ᶜ░H░5⁶0⁷□そᶜ⬅️D⬅️H⬅️	ᶜH➡️H⁸」そ	ᶜ■な¹³ᶜ⬅️D⬅️IMJm■☉!ナK\000HノH■H⁙4⬇️D⬇️■³	⁴5⁴MさIろ2░Iっ□そHᵇTᵇD⬅️■ᵇ`ウ▮ᶠH◆²@D▒□!J▒\000ろIさJ$Jh、ᵇJな、■D🐱H🐱L🐱J🐱adJ$b$5っ2☉J⌂`ᵇᶜ♪L★	⁙M¹ᶜ♥。ムJmᶜ◆■■H★\r⁙ᶜ▥H▥HナI`Iさ■ノ²$■そ」そ2☉Iエ5□ᶜ⧗D⧗	⁙、@`@I`」きMき□`ᶜ▒M¹H²5²D⬇️Iれᶜ⁴H✽4⁶¹⁶	⁶□● (,☉²ヘH⬅️5ょ=ょD😐I\r5ᶠI■8リ,‖IセD²⁸⁷D☉	ᶜ-ア¹□¹⁙Q@b D♥D⁙D⧗IクM¹LヌIさLヒ¹(IKHᶜ▮M`mHᶠᶜ◆▮ヤHヤ■■,★Jr`38sᶜ⧗D⧗8ク□3:3²s,▥IセI`b □`IdIさJ$N$■そNH\rᵉ!n9n■t▮ヌH☉」そᶜ⬅️D⬅️L⬅️ᶜ♪D♪H➡️■■4★YりJ$⁙⁴▮hHhH☉■☉I☉=ᵇD⧗J$!D■な■」I`IきH²ᶜ🐱D🐱H🐱`🐱\000ヌIBIる²bJb`cI³■c¹⬇️□#\"#4⁴8d5ろ4⁶ᶜ●D●H●■f\rを\"&IHIhIそMそ□(J(²H□H¹JHᵇ`ᵇ\000⬅️ᶜ⬅️D⬅️H⬅️L⬅️Iᵇ!K¹kIkakI⬅️a⬅️!ミIミ²KbK¹ム\\\r▮M\000mHm`mᶜ♪,♪H♪\000イHイ	\r1\r9M■と!とbM:mJmbm!n9n,ᶠHᶠXᶠD◆H◆!ヤaヤ▮■H■、Q qHq`qᶜ➡️4➡️8➡️D➡️H➡️P➡️T➡️▮カ8カI■¹Q!QIQaQ■qaq¹➡️-カIヨ²1J1b1□Q\"qJqbq□ね:ね8★H★\000ラ0ラ¹Raラ□R²r□rJrbr、Sᶜ⧗4⧗D⧗H⧗Hリ5⁙9⁙¹SasbS□sbsJ⧗H⁘It□T4‖ᶜˇ4ˇDˇHˇ\r‖5‖I‖H◀X◀ᶜ∧D∧IVaVIvIへH❎ᶜ▤▮▤D▤EスᵉX▮@、@▮らHらI@a@I`Iき□ . J N □@J`b`bき⁙ H¹4²Hヌ■BIBaB,³H⬇️I³:#▮DIDIdIさaろ■ノIノJ$b$□さ`をHヒIそ□H⁙(4\nH⌂5\n■ゅHᵇPᵇH⬅️HつIk¹⬅️5ょ²kJk,\r▮MHmPmᶜ♪H♪8イ■\rI\rIM¹と■と!とaとJmIなaな¹oIエaヤ\"O ■▮Q、QHQPq`q\000➡️H➡️-■I■IQaQI➡️Iね」カIヨb1□QNQJq□ね:ねJねbねaRIキ:rJrbr,⁙D⁙D⧗M⁙□3\"3\"s:sbs▮∧M◀□X▮ら」き□ 2 □@D░■さ5ろ□D,⁸゛Hg(]ょ\000N■な9なIなaな:nJnLヤJt¹x■x!き9きIき,¹,²H²`BIBaBMる²\".🐱▮D\rさJ$N$²dJdbd;$`をLヒa●」そH\nP\nᶜ⌂D⌂H⌂`⌂I\n.⌂▮ᵇ⁘ᵇ8ᵇDᵇPᵇXᵇ、K\000⬅️ᶜ⬅️ ⬅️D⬅️H⬅️IᵇIkMょYょ2⬅️J⬅️HᶜIムH\r、Mᶜ♪H♪`♪8イHイ9MIMaM¹とaと5イMイ²m:mJm>♪IなaなJ🅾️⁙ᵉKᵉ,ᶠHᶠᶜ◆D◆H◆L◆IᶠMᶠaヤ.◆□… ■IqIね」カ8RH★aRIキbR□rH⁙、SHリ`リ5クMク²sI⬆️Mコ,❎H❎■▶ᶜ▥H▥³9H\000▮@(@▮ら\r\0005\000M\000■き)きIきMきIナ゛@2@N@□`J`N`b`³\000K\000³ ᶜ⁴H⁴L⁴▮$H$¹さ5ろ゛DJろ\000Hᶜ☉D☉H☉I☉」そ)そLᵉHn」な)な)ウIモJnfn*🅾️Jウ⁙ᵉKᵉ(TH⬆️⁘ひHケ⁵⬆️■⬆️=⬆️I⬆️a⬆️)ひMケ゛T:tD▤、@¹@■@aりIBaB,³`c\\⬇️▮れ`れ¹³I░IノbDJd`●▮をIをᶜ♥Qh\rそMそ□H,\nᶜ⌂D⌂H⌂`⌂■\nDᵇᶜ⬅️D⬅️H⬅️`⬅️9ᵇIᵇ■+¹KIKIkakIょJk?ᵇKᵇ▮,H😐a😐IアIム▮M`MHmH♪`♪\000イ8イHイ`イIMJmbmS-、NHnᶜ🅾️Hな`なHモ¹.¹NINInIなIモaモ\".N.Jn□なbなH◆¹ヤaヤbO▮■,■、Qᶜ➡️D➡️H➡️▮カ`カ5■IQaQ9ねIねaね²qJqbqᶜ★D★H★`★8ラM□□RJr▮⁙、Sᶜ⧗H⧗5⁙9クbS:sJsbs、T⁘ひHひ■TIT■t=tMt\rひ■ルMルJ4Jtbt4◀D∧5◀\rへIへaへ□6ᶜ❎H❎MまQス□Xc90\000H`PナI█¹き」き)きIら□@□`J`N`b`J█6らK\000`dᶜ░4░H░‖⁴I░a░Mさ5ろ=ろIノ²D□DJDND□さbノK⁴,⁸▮H(H`H▮hᶜ☉⁘☉D☉H☉Hっ-h¹☉■☉!☉9☉=☉I☉a☉)そMそ5っEっ□H2HJHbそ⁙(Hᵉ▮.H.Hn0🅾️HなHウ5ᵉ■N■n-n9🅾️I🅾️■な」な)な‖ウIモ□.□N:NJNNNbN:nᵉ🅾️.🅾️□な.ウJウbモ7ᵉ▮t■ひMひ²tD▤□X1`ᵉ░X⁷5っ▮ᵉ ᵉHᵉ².、X=ス8AH▒	¹I¹4²D🐱H🐱¹BIB`c▮れ`れ	³EれbCJ⬇️J$\000しHし`し`を-⁶H⁷、	H	H\nᶜ⌂D⌂H⌂`⌂¹JJ⌂8ᵇHᵇᶜ⬅️D⬅️H⬅️)ᵇIᵇ¹KIK!kIkak9⬅️Iミaミ□KJ⬅️Hᶜ■ᶜIムH\r▮M、M\000イHイ!-¹MIMaMaと:mJmbm▮ᶠHᶠ-ᶠaヤJ◆\000qᶜ➡️▮➡️D➡️H➡️▮カ5■I■IqaヨJ1□QbQbqH★`ラ■r\r⁙5ク\"s:sJsbs,▥ᶜ♪J`Jd,⁶a●Iそ5ょᶜ♪H♪\rᵉJn,■4■H➡️\\➡️	■Iカᶜ❎H❎■▶I▶g I³Hh@	L\r)ᶠ¹aHヤ¹➡️(@H`⁘きHら-\000E\000I\000■@a@■`1`Mき□ * N ゛@\"@J@□`J`ᶠ\000K\000M¹4⁴4░D░-d■░¹さ6$b$ND□░7⁴K⁴、H(HHhL☉⁘そ-hMhI☉¹そ■そ9そIそMそ9ヘIヘQヘ□(*(N(NH□hJhᶜᵉHn‖ᵉ5ᵉMᵉ-n)なIモ²n□n゛n゛Q□xL¹ !	¹\r¹I¹ᶜ🐱D🐱H🐱▮ヌIB5るD³▮れ!³9³]³5れHしJeH⁶▮fᶜ●▮●D●H●\000をHを`をI⁶J●ᶜ♥\"♥H⁸HhIH■hIh■そIそaそᵉ(□H²hJh、	H	H웃ᶜ⌂▮⌂D⌂H⌂¹\nI\nJ⌂H⬅️ak。ミ,ᶜ▮😐4😐L😐■ᶜ5ᶜIᶜa😐IムJ😐H\r▮M、MHm`m▮♪\000イ▮イ イHイ`イ\r\rI\r■MIMJmᶜ◆D◆H◆▮ヤ\rᶠ■ヤᶜ➡️▮➡️D➡️H➡️IQᶜ★D★H★Iラaラ□R²r,⁙4⁙H⁙、Sᶜ⧗,⧗D⧗H⧗\000リ▮リHリ9⁙9クIクbsJ⧗Iひ9ルᶜˇ,ˇ4ˇDˇHˇ`ˇ5‖D∧5◀avIへᶜ❎H❎、「H「ᶜ▤■x■ま5スᶜ▥▮▥D▥H▥9セEセ、@L@ᶜ`H```I\000I@1`9`I`■█I█a█IきIナ2 J N@²`□`□きD¹▮!⁸▒,▒\r¹M¹=りJ▒N▒b▒,²<²▮B8B`BM²IB5る²b\"b:bF🐱N🐱4³Hc`cᶜ⬇️H⬇️¹³\r³=³ac5れIれ]れb#⁶⬇️^⬇️⁙³、D▮dHd`dHさ`さIDaDIdIさND□さᶜ✽,✽D✽8しI⁵M⁵]⁵aeb%,⁶D⁶H●8を■⁶¹●¹すIをF●⁴⁷0♥Hそ`そ4っ!HIH)そIそᵉ(NH□そ」	5ゃᶜ⌂H⌂`⌂\\ᵇ`ᵇL⬅️	ᵇ■ᵇMᵇ9k4ᶜ<ᶜ4😐L😐\\😐Mᶜ]ᶜ,\r`\rHmX♪`♪\000イ」\r5\r■とIイ□mJm-ᵉ¥.`ᶠ「◆,◆5ᶠ¹oaoIエMエIヤ:/4■」■6➡️L□X□`□▮★H★L★X★\r□5□M□\rキYキ:rJrbrJ★「⁙\\⁙、S0⧗¹⁙■⁙]ク:3b3□T,ˇLˇ■‖□ˇ4◀\\◀ᶜ∧L∧5◀5サ゛vH❎H▥H⁴■░2░H☉■☉■そ9そ`n⁵🅾️■な⁵⬆️■▤■ま²xH`I`Mき²`H¹`!H▒ᶜ🐱D🐱H🐱`🐱Lヌ5²IBD⬇️H⬇️▮れ`れ	³IdI░□さD✽Hし■e□eJebeHをLヒ\r⁶-をEをᶜ⬅️H⬅️`⬅️■kIk▮ᶜᶜ😐D😐H😐J😐Hm`mH♪HイIM□M¹.Jnᶜ◆4◆D◆H◆Iヤ4★D★H★ ラIRaRIラJ★H⧗Jsc3,‖H‖ᶜˇ,ˇ4ˇDˇHˇLˇ,「H」、@H`I█IきJ b N@□`ᶜ▒H▒5¹■aMりIBaBᶜ⬇️8⬇️H⬇️D●□●b●H♥HhIhahIそNH(	I	ᶜ⌂D⌂H⌂「ᵇH⬅️HつIk,ᶜ4ᶜ8😐Iム▮m8m8♪H♪5\r■と□mJmHnHな`なINaNI🅾️a🅾️IなIモaモ²N□NNNJnbnᶜ◆D◆H◆`◆□…,■H➡️	■\r■■■Jqbqᶜ★H★L★ ラ5□M□\"rJr,⁙4⁙H⁙、Sᶜ⧗H⧗I⁙Is5クEクIク□s4⬆️H⬆️▮ケ、ケ■tItI⬆️\rひIルaル□TNT□t゛tJtᶜˇ4ˇDˇHˇ4◀`vᶜ∧,∧4∧D∧■◀■∧\rへ゛vJv,「■まNXL▥M」¹き ¹`!,▒H▒5¹■a!aJ▒▮ヌIBH³Hc`cD⬇️H⬇️■³I³\000dJ$▮しHし▮⁶,⁶`&`を」そIそHマᶜ⬅️D⬅️H⬅️,ᶜ\000,8,4😐H😐ala😐Eア9ムIムaム、MHmᶜ♪H♪Hイ	\raとJmbm▮◆¹ᶠ,■IヨJ➡️H□H★`ラIR¹★□RJrbrHリ5⁙bsI`L¹ᶜ⌂H⌂■😐HmJnD◆Hら,¹ᶜ▒D▒H▒\000ニ5¹E¹■aMり²!□!IB²\"8cH⬇️▮ネPネI³acIれ³#ᶜ✽D✽H✽H⁶D●H●`をIを2●⁴♥⁵⁷▮H(HHHHh\000っIhI☉■そIそMそJ(NH゛hQゃ \nD⌂H⌂¹\nI\n\"jᶜᵇ,ᵇLᵇ<⬅️H⬅️L⬅️	ᵇ]ᵇ■kak!⬅️-ょ5ょ=ょ¹ミIミ²K□K:kJkbk□⬅️N⬅️□つ:つ4ᶜHᶜ\000,8,(😐,😐4😐H😐`😐Pてa😐!ムIムHm`mᶜ♪D♪H♪\000イ、イ8イHイ9M²M:mJm¹n4ᶠ\rᶠEエaヤ4■Hqᶜ➡️▮➡️▮カ8カ5■I■IQaQ\rカIカJ➡️D★5□□RbR ⁙`⁙ᶜ⧗0⧗H⧗5⁙I⁙G⁙\0004▮T、T`T、ケItMt¹ひMひb4□tJtᶜˇDˇHˇ`ˇ5‖Eコaコbふ、◀ᶜ∧D∧H❎ᶜ▤D▤\r「■ま5スNXH▥H H`⁘きHら-\000¹`\r`■`-`=`a`=█I█\rきIきMき¹ナ■ナ!ナ□ ◀ > J N b ゛`J`N`ᵉ█>█F█JらL⁴¹さ\rさ■さMさT⁷9♥.♥²ん5っ1ᵇ`n⁘なHウ\rn■な」ウ=ウMウ¹モ■モIモ□.6.Jn¥🅾️>🅾️F🅾️N🅾️.ウ>ウJウ⁴■▮■「■0■4■<■L■X■`■▮➡️X➡️1■=■⁵カ\rカ」カYカ⁶➡️2➡️\0004 t8tHt⁘ひLひHケ)t-t=tItI⬆️Iル◀4J4□T²t□tJtg4H▤7\0005⁴I`■█I█a█Iき□ J □@J`⁙ 2▒8BHヌJb4³D⬇️H⬇️▮れ`れ2⬇️Hd`dID\rdIdadI░IノaノJ$D✽D⁶!す9す-をIを□●\"'HそIh■そJ(□H2Hbh³(⁙(IゅJj、ᵇH⬅️Hつ¹k■kIk²つ▮😐4😐H😐■ᶜIᶜH\rHmH♪ イ¹とEイ²M□M\"M□m\"mJmbと³-ᶜᶠ,ᶠ¹ᶠ	ᶠaエ²oJo⁸■ ■,■ᶜ➡️D➡️H➡️Hね▮カ	■‖■5■IQ5カYカ²1□1J1b12➡️□ね:ね`★²R▮⁙,⁙5クJs>⧗4ˇDˇ4◀D◀ᶜ∧,∧4∧D∧5◀ᶜ❎D❎H❎:wJw4▤(@▮`H```LきHらHナ■@9@M@a@■`-`1`M`a`¹█■█I█\rき)きIき■ナIナᵉ □ * 6 > ゛@.█□き.ら2ら6らJら³\000K\000 ヌ⁘⁴,⁴D⁴H⁴Hd,░4░<░D░L░)⁴‖d-d\rさMさ-ろᵉ$□$:$Jd²さ6ろJろ ⁸ᶜ☉,☉D☉H☉Lそ-hahI☉■そIそaそIヘ□(*(F(J(N(゛H:HNH□hJhF☉²そ□そJそ<⬅️⁶⬅️(😐■ア,ᵉLᵉ(Nᶜ🅾️D🅾️H🅾️ ウHウ!.9.¹n■な)ウ-ウ5ウIウMウ■モIモ□...6.N.□nJnNnN🅾️□なᵉウ6ウJウbウSᵉᶜ➡️X➡️I■Yカ⁶➡️¥➡️)⁙2⧗>⧗(T■t5tItIひMひ²4゛T□tJtH◀D▤axI`H!/¹H🐱Lヌ9BIBaBH³ᶜ⬇️D⬇️H⬇️\000ネ▮ネ■c▮ろ\rdIさMさ゛dF░□さJeHヒLヒ-⁶¹f¹●¹すIすIゃH\nD⌂H⌂Hkᶜ⬅️4⬅️D⬅️H⬅️\\⬅️IKaKIkakIょJkbk²つDᶜHᶜ\000,IᶜIム.😐▮MHmᶜ♪H♪X♪▮イHイHメIMaMJ♪ᶜ◆H◆aヤᶜ➡️▮➡️4➡️H➡️。■I■	カ²1>➡️,□H★bR²rJrD⁙ᶜ⧗H⧗▮リ¹S>⧗J⧗DˇD❎H❎9❎□w゛wbwD」ᶜ▥,▥D▥H▥Hら-\000\r`)きN □`J`N`Jら4⁴D⁴Hdᶜ░⁘░4░D░H░L░「ろHろ5⁴‖d-d1d=d■さIさIろIノJ$JdJろHhᶜ☉D☉H☉`☉⁘そ-h9☉=☉I☉)そIそMそIっIヘ.(F(N(□hJh□そbそ1ᵇ,ᵉ`n⁘なHウIn-ウN.゛N4■)■H⁘Hケ)t-t)ひᶜ▤D▤`▤Hま□8J8□xH (@▮`H█Hら\r\0005\000■@I█■き」き)きMきIナN ゛@□`J`b`JらK\000H$Hd(░<░D░L░MノJろK⁴▮H(H▮hD☉ah■☉I☉a☉」そ)そ■ヘIヘMヘ゛HJh□そ4ᵉH.H🅾️Hウ\rᵉ\r.9🅾️1ウ=ウMウ■モIモaモ2.゛N゛nJn□なJウᶠᵉ⁴4H4ᶜ⬆️H⬆️⁘ひHケM⁘=⬆️I⬆️」ひ)ひ⁶4>4J4□T゛TD▤ax■ヲ(\000(@)\000-`1`M`2 N ゛@⁙ D⁴(░H░)⁴■D-dMd*$Jろ■h*(F(J(□h゛hJh(NHウ■N9NaNMnEウMウ□.¥.□nN🅾️NウHケJ4゛TJtH (@PきHら-\000■@a@Iナ□ ◀ * . J b ゛@゛`Jらᶜ⁴(⁴<⁴H$(DHdᶜ░D░H░-dH((H▮hH☉⁘そLそHっ■ヘIヘaヘN(JhH.Hn(🅾️<🅾️Hウ■N\rウ)ウ-ウ=ウMウ□.N.JnN🅾️*ウJウbウH4(T⁘ひHケ゛TH▤I@Iナaナ□ J □きH¹D▒H²H🐱9BIB■bH³`c	³1れD⁵H⁵²eJebeD●`をF♥IhahH	J웃、\n4⌂H⌂-ゅ、ᵇ4ᵇDᵇHᵇ▮k k8kHkᶜ⬅️ ⬅️D⬅️H⬅️\rᵇ5ょIょ2⬅️J⬅️□つ4ᶜHᶜD\r▮M▮mH♪Hイ	\ram■とaと□MbM`🅾️INaN■nInI🅾️Iモ□n゛nJnbnHヤ`ヤEエaヤ²/,■H■81H1\000q8qHqᶜ➡️▮➡️,➡️D➡️H➡️\\➡️8カIね²1b1²qJqJ➡️Hリ-ク▮TLT、ケITItI⬆️\rひIルaルJ4□T゛tJtD◀▮Vᶜ∧D∧⁘へHへ■vIvI∧\rへ■へIロ□V゛vH「■xf▤5」▮@`@▮`8`ᶜ█D█H█Hら ナ-\0005\000M\000■@\r`■`-`M`I█■き」き)きIきᵉ □ * J N 2@□`J`.█.ら6らJらᶠ\000K\000³ g (⁴,⁴4⁴D⁴L⁴(DHDLDᶜ░,░D░-⁴E⁴ID\rd)d-dMd\rさMさIろ2$Jd¥░Jろbろ,⁸\000H▮H`H▮hᶜ☉,☉D☉H☉⁘そHそ■HaH■h-hMhI☉¹そ■そ)そIそaそ□(N(b(□hJhfhJそLᵇ`ᵇMᵇ」ょ▮nHn-ᵉ■N‖ウ)ウ-ウ1ウ5ウEウMウ□.*.N.゛NJnN🅾️ᶜ■「■L■`■ᶜ➡️▮➡️X➡️」■M■\rカ」カ□➡️¥➡️Htᶜ⬆️D⬆️H⬆️Hケ■t■⬆️a⬆️)ひ64J4N4²t,「□8⁴⁘ᶜ⁘L⁘X⁘「⬆️⁵⁘\r⁘M⁘e⁘H (@▮`⁘き▮らHら`ら\r\000」\0005\000E\000■@■`)`-`=█\rき■き」き)き。ナIナ□ * 6 F J N ゛@□`J`6█□きJらK\000ᶜ⁴(⁴,⁴0⁴4⁴D⁴ᶜd▮dHdᶜ░(░,░0░4░<░D░-⁴5⁴¹d■d-d■░I░\rさ9さIさMさIノMノ□$6$JdJろbろK⁴、H(Hᶜ☉H☉⁘そ⁵h■h-hMh■☉I☉a☉」そ)そMそ¹ヘ■ヘ□(*(>(J(□そbそ▮ᵉ ᵉHᵉLᵉH.(N<🅾️`ウ	ᵉMᵉ■N■n5n¹🅾️=🅾️\rな■な」な)な5なaな\rウ)ウ-ウ=ウEウ■モIモMモ□.*.2.b.JNJnNn6🅾️>🅾️F🅾️N🅾️□な6ウ>ウJウᶜ■▮■「■(■<■X■`■<➡️X➡️¹■」■1■=■=カYカaカ2➡️N➡️H4(T▮tHt`t⁘ひ-t1t1⬆️=⬆️I⬆️」ひ)ひIひMひ¹ル■ル□4N4ᶜ▤H▤■x!x9x■▤a▤□8□x□き、¹H¹`!D▒\000ニ BIBaB□\"HcEれbC▮dMさJ$□dJdbd4⁶D⁶HヒIをF♥Hh」そMそ□hJh▮웃Hマ*⌂ K\000つ8つIKaKak。ミJ⬅️⁸ᶜIᶜ¹😐Iア。ムIムI\rIM¹とIとaと>♪D◆H◆²/、■,■H■L■Hqᶜ➡️D➡️H➡️Hね`ね▮カ`カaq²1ᶜ★H★ ラJ★Eク²3²sH (@H`▮らHら-\0005\000■`a`!█=█a█」き)きIきIナMナᵉ □ ◀ 2 N ゛@゛`J`/\000K\000,⁴D⁴L⁴▮dᶜ░,░<░D░H░L░E⁴-dMdMノ◀$K⁴H☉LそHっ■h-hI☉■そ」そ)そ■ヘ□(.(゛HJH゛hJh□そg(H.■n5n5ウ=ウIモMモᵉ.□.6.Jn6🅾️」ひ▮!-¹■りYり▮🐱H🐱5るIさD⌂H⌂Iᵇ。ミ²つDᶜ、MHMHmᶜ♪H♪\rイ゛mᶜ◆H◆Hヤ、■4➡️>➡️=キ▮リDˇI`²``!D▒H▒\r¹I¹¹a■a9りEり6▒J▒4²H🐱L🐱▮ヌ8ヌHヌM²IBaBIるJbId`し¹⁵`を¹●H⁷J'\000っHっ9HIhIそMそ²(゛HJhH웃H\n4⌂D⌂H⌂ マ5\nI\naJ(ᵇ@ᵇDᵇHᵇHK`K\000⬅️D⬅️H⬅️IKaKIkak¹⬅️5ょ¹ミ*⬅️J⬅️,ᶜᶜ😐D😐H😐5ᶜIᶜa😐IムH\r\000イ イ8イHイ`イHメ¹MIMaM¹とbM\"m:mbmHᶠᶜ◆4◆D◆H◆L◆EᶠIᶠ¹ヤJ◆H■8q`qᶜ➡️H➡️\000カ▮カIね	カ)カIカMカIヨ□1b1\"QJqbqD□ᶜ★D★H★IR²R□R:R□rbrD⁙D⧗H⧗Hリ■⁙QクJsbsJ⧗▮4\rtMひ5ケ■ルJt、‖H‖Dˇ ◀H◀ᶜ∧D∧■◀aへ□VJvᶜ❎D❎H❎I▶-シ5シEシJ❎²8³9⁙9、@▮`H`ᶜ█I@I`I█J b □@J`⁙ Hヌ`ヌ²b`cIdI░\rさ■さIさaさJ$゛dHしHを²●J●J'\r⁸Ih\rそIそ▮ᵇ8KH⬅️\\⬅️¹ᵇ	ᵇIkak!ょIょᶜ😐H😐!ム9ムIムMム□L、MHmPmH♪L♪▮イ¹\r■と9とaと5イEイ□M゛mJmbm□♪,ᶠHᶠ▮◆\rᶠaエ ■H■▮Q(➡️H➡️▮ねHね\000カI➡️■ねIね²1b1□QJq¹r²r□rJrbrH⧗Hリ²3\"3、T、ケᶜ∧,∧M◀H▶H❎Jw(@ ら1\000■`!`¹き■き」き)きIき]き2 J Jらbら▮$\000Dᶜ░(░H░Lさ4ろ	⁴5⁴E⁴‖d¹░■░IさYろ□$2$□D>D²d□dJろbろ(H⁘☉、っHっ)h-h■そ」そ)そIそ-っᵉ(.(Lな■n!n」な6.:.>.□NJ🅾️.ウ▮■X■▮➡️X➡️\r■=■⁵カ■カYカ2➡️HtHケ¹4⁵⬆️=⬆️)ひ.4³⁘■▤!▤a▤Iき² J ¹¹,²\000Bᶜ🐱H🐱`ヌIBaB,³`cᶜ⬇️H⬇️J$HしIわJeD●H●Lヒ5をH\nH⌂I\n¹J(ᵇ▮kᶜ⬅️D⬅️H⬅️Ikak゛kJk8,ᶜ😐D😐H😐\rᶜ5アIムH\rLMHm\000♪ᶜ♪H♪▮イHイIMaとJmbmIᶠaヤbOᶜ➡️H➡️IqIカJ14⁙、SD⧗▮リI⁙■s□3bs>⧗5「IまH▥c9H```N@⁙ IBaBIる`³▮c`cH⁴Hし`しJeJ✽▮⁶H⁶ᶜ●H●□●Iん■hIh」そ□HJh`\nᶜ⌂4⌂D⌂H⌂Iゅ4ᵇDᵇHᵇᶜ⬅️H⬅️IkakJkJ⬅️/ᵇ4ᶜH,H😐¹ᶜa😐Iア,\r m8mᶜ♪D♪H♪`♪\000イHイ	\r¹MIM■とJ♪InI🅾️Iな゛nJndᶠᶜ◆▮◆(◆D◆H◆▮ヤ ヤHヤ	ᶠIᶠ!エIエaヤ□…、■4■H■、QHQH➡️	■!■IカMカJ1□Q\"Q*Q:Q²q□qJqJ➡️H□ᶜ★H★`ラbR,⁙ᶜ⧗0⧗D⧗H⧗bs、T、ケITIひJ4□TbTJt⁙4c4ᶜ∧,∧D∧■◀Iへaへ□VbVJv⁙6c6	▶5▶ᶜ▤D▤5スIスᶜ▥H▥■」H ▮@(@L@▮`H` ら)\000-\0005\000M\000=█I█)きAきIきMき■ナIナMナ゛@J@J`N`□き.ら▶\000K\000ᶜ⁴L⁴(Dᶜ░4░H░\000さ‖⁴ID¹░I░\rさJDNDJdJろ▶⁴K⁴⁸⁸ᶜ⁸,⁸▮(▮H(H▮hᶜ☉D☉H☉⁘そ8っHっ■H\rh-hI☉■そIそ-っEっIっ■ヘIヘaヘNH□hᶜᵉ(ᵉLᵉ(N▮nHnHウIᵉ■N-n=🅾️¹な	な■な)なIな=ウeウ■モ゛nJnN🅾️□なJウKᵉ▮T(Tᶜ⬆️D⬆️H⬆️8ケHケ-tat=⬆️)ひJTNT゛tD▤■X¹▤IヲNX▮` `J ᶜ⌂\000484IきN ゛`▮¹,¹D¹H¹`!ᶜ▒D▒H▒IBH⁵▮しHしJebe²&■h¹そ2HRjH⬅️=ᵇ■k¹ミ\"K\rᶜa😐EアIムaムH\rHmᶜ♪D♪H♪Hイ	\raと(◆)ᶠ■o□…81HqHね`ねIQ■➡️I➡️IねMねIヨJ1`ラIRaR▮⧗Eク\"sbsJ⧗H❎D▤H█5\000I`」き)きJ`K\000(⁴ᶜ░,░4░<░D░L░*$>$▮HD☉Hっ-hMh■そ)そIそaそ□(.(>(NH□hJhNヘD🅾️D▤H░J$」そ7⁸H⌂D⬅️Iム▮mᶜ♪H♪,ᶠᶜ◆H◆`◆	ᶠIエIヤ:o4■ᶜ➡️H➡️Iカ▮リJ I`D⬇️Iな!`ᶜ●4ᵇR4□@¹█IきD🐱¹░5ᶜᶜ\r▮\rD\rH\r4ᶠ²3H‖■「■」!█,▒D▒■aIり²!□!⁸⁸(⁸@⁸、ᶜHᶜᶜ😐ᶜ◆Hヤ■ᶠbo、■H■I\000Mナ2 b J█「¹4¹D¹ᶜ▒\r¹]り<²H🐱¹²■bIるaるJ🐱N🐱0³▮⬇️D⬇️\r³Iれ□⬇️¥⬇️゛dᶜ✽M⁵]⁵「⁶L●\rをMを2●L⁷=⁷\000H`そ5っ□hJhbh0	ᶜ⌂L⌂\r\nXᵇ`ᵇᶜ⬅️L⬅️\rᵇMᵇ4ᶜL😐X😐]ᶜ`ᶠ「◆4◆5ᶠᶜ➡️\r■」■=■X□`□▮★L★X★\\★\rキ\\⁙■⁙-⁙5⁙ᶜ∧L∧M◀5サ=」Yり⁙¹Iれb#\rさL웃`ᵇᶜ⬅️Mᵇᶜ◆D◆4■6➡️▮★L★`★(⁙D⧗■⁙ █!`Iら□ \" □@□`4¹\\▒¹¹▮⬇️,⁴H⁴8d	⁴¹さMさᶜ●D●H●,⁸■そ□h4ᶜ,\rᶜ♪ᶜ◆▮□\r□5キP4H‖▮らJ$D♥」そ\000♪□…,⁘□4>4b4\"$■hD⧗,⁴H⁴¹t²🐱ᶜ⬇️H⬇️,⁶□●J●Ih□(J(b(H\n-\nH⬅️L⬅️\rᵇIᵇEょ□K□⬅️□つIムaム\000mᶜ♪H♪HイJmᶜ◆D◆H◆\rᶠEエ4■H■`q⁸➡️H➡️¹■]■¹ねJ➡️□ね,□H★Jrbr	⁙J⧗、TMtMひ□tJt□vH❎■`I`a`¹さIノJ$b$4⁶H⁶H●■⁶Iを■♥IhahIそaそDᵇHkLkH⬅️Ik2⬅️▮\r,\rHmPm`♪▮イ5\r1イJm□♪J♪H1▮カ²1b1□Q:QNQJqRq□ね¹ラ²rJr、Sᶜ❎D❎H❎-▶E」I`\rきH▒\\▒`▒D²ᶜ🐱H🐱`ヌ8⬇️J$Jろbろ\000eHしH⁶¹⁶-⁶Eを▮kD⬅️¹k!kIk4😐,\rH\r\000Mᶜ♪D♪H♪X♪	\rIイJm/\r¹n\rnInD◆,■ᶜ➡️8➡️H➡️\000カ▮カ\r■IqRqJ➡️H□ᶜ★H★■□M□■の5キEキ²r:r▮⁙,⁙H⁙\\⧗:3²sH‖L‖\000uDˇHˇ\r‖4❎E」EセI⁴H☉HウJ ⁴²,²H🐱`c¹CQれ6⬇️¹░■⁶□●▮HHh¹h■hIヘ▮ᵇDᵇᶜ⬅️H⬅️L⬅️IK²k□k\"kJk²つ□つD😐Mᶜᶜ⧗D⧗H⧗、T▮ケQtᶜ∧,∧D∧,❎ᶜン	\000Ih1ウJ🅾️Z🅾️JウHを`をHヒ`ヒ8ょIつ²つbs」そH@■B9BIBaBHc`cᶜ⬇️D⬇️H⬇️▮れI³JcD✽HしJeᶜ●D●H●\000を5をS⁶9ん▮hHそLそIhIそJ(NH□hJh□そH\nᶜ⌂4⌂D⌂H⌂Hち8kHkᶜ⬅️D⬅️H⬅️■ᵇIᵇIK¹kIkakbkfkᶜ😐H😐J😐Hmᶜ♪H♪`♪HイIMaM■mam¹とJmbm⁙-HぬH1`1Hqᶜ➡️H➡️d➡️IQI➡️IねIヨ□1NQJqbqH★`ラI★Iラaラ□rJr<⁙、SD⧗Js⁘ひ、ケIT)tItJ4ᶜˇDˇHˇ`ˇH◀H∧Ivᶜ❎4❎D❎H❎ᶜ▤E」9セ\r`I`⁵█IきJ b □き`!D▒Lヌ,⬇️▮れ`れHd`d■DIDIdI░IさaさIノaノND□dJd□eJeHh、っIhᵉ(J(□H⁙(H\n、KHk■KIKMKIkak゛KJkH,Hm▮イaとJmIカ゛QJrH⁙asᶜ❎H❎(@■`9█I█」きIナ□ ◀ ²`J`>█F█,⁴D⁴L⁴,░4░<░Lさ)d1d=dIさ□$JdJろK⁴、HHh⁘そLそHっ■h)hI☉■そIそaそIっIヘMヘ.(F(J(゛H*HJHNH□hJhbhg(■n=🅾️‖ウ=ウMウIモ..N.□N:NJウ=⬆️Iル\000x\000BIBaB`c4⬇️D⬇️H⬇️Yれ゛c\rdIdᶜ✽H✽`✽■⁵be4⁶\000を`をLヒI\n8KHkᶜ⬅️H⬅️\000ょIᵇ¹+IkakJkIムaム▮M、MHm`mᶜ♪H♪`♪▮イHイ`イIM¹とIとIイ⁙-ᶜ◆D◆H◆ᶜ➡️D➡️H➡️²1ᶜ★D★H★\000ラLラIラaラJr4⁙、Sᶜ⧗H⧗▮リHリ`リbsᶜˇDˇHˇ4▥H▥H`\r`IB▮れ.✽J웃4⌂D⌂¹JHkHつak□つ4ᶜH,`,4😐7ᶜ\000イ イIMaMJmHn`nᶜ🅾️D🅾️Hな`な\rnInanIなIモaモ□N゛Nfnc.Hq`qIQ\rqI➡️a➡️b1□QNQ゛qJq\rt\rひ4ˇᶜ∧▮∧4❎(@」きIナMナN@□`゛`.ら(⁴(DIさND(Hᶜ☉D☉H☉」そNH□hJh■N」なMウ□n゛n」ひD▤ax`cJ⬇️IkNQH★PラbR¹▶ᶜ⬅️H⬅️HmIとᶜ⧗H⧗⁸▒¹\r	\r5イ	■]カJ➡️¹きK\0004ᵇ0⬅️	ᵇ-ょ/ᵇ\"rJrJ H¹\000!`!\000BLヌ¹BIBHしD●H●I⁶9んᵉ(¹JYゅH⬅️4😐aム6😐HイIM)エ5エIヤaヤ(■8QHqD➡️\000ねIQIねJ1²q:qH⧗Ht\rtIルᶜ∧`∧IvIへaへIロ□.ᶜᵇᶜ⬅️\rなᶜ■ᶜ➡️H`Hナ1`Iきᵉ 6 J N@、BHヌ`ヌH⬇️Hd゛DHをIKIkI⬅️IミJk²m□m\0001HqIQH★IRJrbrI⁙JsITaT4ˇHˇ4∧ᶜ❎H❎□$\rdᶜ⌂H⌂Ik▮MH◆aヤHqIQJ1゛qH⧗■⁙I░■HH⌂MnH◆8!`!IB,⬇️Hネ■cH⁶▮●Hヒ	⁶5⁶I⁶(H4	ᶜ⌂,⌂D⌂H⌂.⌂IKaK1ᶜIム	\rI\rIMHなIモH➡️IQIヨIT」ひ64J4N4□T゛tᶜ∧H∧■◀Iv³6MナMさᵉそ、♪■█NNIきH²\000B、B9BIBaBJeH⁶ᶜ⌂H⌂aJIゅ4ᵇH⬅️9😐a😐Iム5エaヤ²qJqJ▥²!IB\000h`h□(L\n4ᶜ8,¹ᶜ¹-□m³-⁙-aヤHねI■I⁙H❎5「4▥I`⁸▒²!⁶▒J▒H³Iそ8m\000qIQIカJrbrH⁙H❎H▥9🅾️L▒Hし4⁶Hᵇ、K¹kIk ,H,8MHM`M⁴♪H♪Hイ`イ■MaM9ヤaヤ0■I⁙,▥M」□nbn\000█IりJ▒8B▮⁴,⁴H⁴2HNH ,▮\r,\r\000mᶜ♪D♪H♪IM\000🅾️`🅾️\rᵉINI🅾️Iなbn¹ヤ9ヤ-■I■:1IT▮∧■◀J⬅️4ᶠHᶠ¹ヤHね1」,⁶5をH😐	ᶜ"
valid_counts = "⁴:\"'⁷\r-\n¥⁴⁶Z75¹(²W#「」□⁘ᶠ⁸■す\000\000\000▒\000\000⁸\\\000\000]\000\000に\000\000q\000\000x\000²\000\n\000そ\000\000\000+\000\000★#\000\000a\000¹タ\000\000o\000¹O\000¹\000□¹Z\000\000\000😐\000\000ᵇf²\000\000\000\000▥\000\000Q²\000Q\000ᶜ\000⁶¹」⁵⁶\n⁵¹⁸¹⁸²²゜\"\"²ᶜ⁴」ᶜ□⁵ᶜ⁴、⁸¹e\000\000\000R\000\000\000[²\000f\000\000Q\000\000D\000\000>\000\000\000⁶\000y\000\000\000;\000\000	7\000\000J\000	i\000\000m\000\000G\000¹\000「\000⌂\000\000\000]\000\000\000.\000\000\000\000\000⌂\000\000\000\000\0000\000¹\000「\000²¹\rᵉ\000¹⁴¹\000\000³\n「7⁵¹\000		³\000³\000⁴\000³6\000\000\000#\000\000¹、\000\000\000\000¹-\000\000\000\000\000&\000\000\000\000\000U¹\000\000<\000\000ᶠ<\000\000\n\000!-\000\000⁙¹\000」²¹\000□\000웃\000\000\000c\000\000\000n\000\000²\000\000⌂\000\000\000\000\000@\000¹\000「\000り¹\000\000h\000\000¹o\000\000\000\000¹そ¹\000\000\000\000`¹\000\000ᶠ¹R\000\000¹B\000⁵\0009\000¹\000\000\000P\000\000\000\000\000•\000\000\000⁶\000ᶜᵉ▮\r\000⁸ᵇ⁴⁵¹⁵■ᵇᵉ\n\r\000゜⁷⁶¥\rᵇ\n¹³そ\000\000\000u\000\000「o\000\000@\000\000⬆️\000\000c\n\000^\000¹\000⁘¹⁵\000\000\000\000\000\000\000¹\000\000\000\000\000²\000\000\000\000\000F\000\000\000\000\000…\000\000\000め\000\000ᵉM\000\000\000\000\000🐱\000\000\000\000\000D\000\000\000⁸\000し\000h²}\000\000⬆️e\000MU+?✽🅾️	\000\000ほL\000J\000゛\000し\000\000\000h\000\000RL\000\000\000\000\000🅾️\000\000u⁶\000A\000\"\000▶¹\000\000\000³\000\000²²\000\000¹ᵉ⁙Q\000⁙\000 \n³\000³\000\000\000\0007\000\000\0005\000\000\000K\000\000³\000\000)\000\000⁶\000\000⁸\000\000\000¹\000r\000\000\0009\000\000BL\000\000\000\000\0008\000\000、\000\000⁸\000\000\000⁶\000\000\000\000\000⁷\000\000\000\000\000\000\000\000\000¹\000\000¹\000\000\000\000\000\000⁷\000.¹³²&¹\000\000\r\000\000³²\000+\000\000⁴¹¹▶\000\000\000\000\000⁘\000\000\000▮\000\000¹「\000\000²\000\000 \000\000\000\000\000⁶\000\000\000⁴\000"



set_wp()
cls(14) -- was 13
wordlegridempty()

today_word = get_answer(get_today_num())

init_letter_states()
-- draw_tile_response(0,0,1,0)
-- draw_tile_response(1,0,2,1)
-- draw_tile_response(0,1,3,2)
-- draw_tile_in(1,1, 5)
keyboard_draw()
draw_valid_mark(0, 0, 0)


-- decode_answer(1 >> 16)

test_date_1 = {["y"] = 2022, ["m"] = 5, ["d"] = 21}
test_date_2 = {["y"] = 2003, ["m"] = 6, ["d"] = 20}


-- print(get_answer(0))

-- printh(escape_binary_str(binstr), "@clip")

__gfx__
00000000000000000000000000000000666666666666600006666000000000000000000000000000055550000566600006666000066660000666600006666000
00777777000000000000000000000000667666666666600066666600066666660000000000000000555555005555660066665500566666006666660066666600
07666666007777770000000000000000676677777766600067667600060000000666666600000000575575005755750057657500576676006766760067667600
06666666076666660000000000000000667666666676600067676600060000000600000000000000575755005757550057575500575766006767660067676600
06666666066666660077777700000000666666d66676600066766600060000000600000006666666557555005575550055755500557556006676550066766600
0666666606666666077777770000000066666d6d6676600006666000060000000600000006000000055550000555500005555000055550000655500006666000
06666666066666660766666600000000666666766666600000000000060000000600000006000000000000000000000000000000000000000000000000000000
06666666066666660666666600000000666666666666600000000000060000000600000006000000000000000000000000000000000000000000000000000000
06666666066666660d666666000000001fedcba989ab000000000000010000000100000001111111000000000000000000000000000000000000000000000000
066666660666666600dddddd00000000fedcba98789a000000000000010000000100000001111111000000000000000000000000000000000000000000000000
066666660d6666660000000000000000edcba98789ab000000000000010000000100000000000000000000000000000000000000000000000000000000000000
0d66666600dddddd0000000000000000dcba998789ab000000000000010000000111111100000000000000000000000000000000000000000000000000000000
00dddddd000000000000000000000000cba988789abc000000000000011111110000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000ba9878789abc000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000cba98789abcd000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000dcba989abcde000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700077777000077770007777700077777700777777000777700077007700077770000007770077007700770000007700070077007700077770007777700
07700770077000700770007007700070077000700770007007700070077007700007700000000770077077000770000007770770077707700770077007700070
07700770077777000770000007700070077770000770000007700000077777700007700000000770077770000770000007777770077777700770077007700070
07777770077000700770000007700070077000000777770007707700077007700007700000000770077770000770000007707070077777700770077007777700
07700770077000700770007007700070077000700770000007700070077007700007700007700770077077000770007007700070077077700770077007700000
07700770077777000077770007777700077777700770000000777700077007700077770000777700077007700777777007700070077007700077770007700000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00777700077777000077777007777770077007700770077007700070077007700770077007777770000000000000000000000000000000000000000000000000
07700770077000700770007007077070077007700770077007700070077007700770077007007770000000000000000000000000000000000000000000000000
07700070077000700777000000077000077007700770077007707070007770000770077000077700000000000000000000000000000000000000000000000000
07707070077777000007777000077000077007700770077007777770000777000077770000777000000000000000000000000000000000000000000000000000
07700700077007700700077000077000077777700077770007770770077007700007700007770070000000000000000000000000000000000000000000000000
00777070077007700777770000077000007777000007700007700070077007700007700007777770000000000000000000000000000000000000000000000000
