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
        draw_enter_key(state)
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

function draw_enter_key(state)
    pal({[7] = 8, [6] = keyStates[state]})
    spr(20, 20, 116)
    spr(21, 28, 116)
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
            draw_valid_mark(1)
        else
            draw_valid_mark(2)
        end
    end
end


function backspace()
    if (currentWordLength <= 0) return
    deli(currentWord)
    if(currentWordLength==5) draw_valid_mark(0)
    currentWordLength-=1
    draw_blank_tile(currentWordLength, onGuess)
end

function draw_valid_mark(state)
    -- just get rid of it all, will need to clean this up later
    rectfill(104, 8, 110, 91, 14)
    if(state == 0) pal({[6] = 9, [7] = 8})
    if(state == 1) pal({[6] = 1, [7] = 8})
    if(state == 2) pal({[6] = 3, [7] = 8})
    spr(6, 104, 8 + (onGuess*14)+4)
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
        draw_valid_mark(0)
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
    if(sframe >= let_delay*fpf*4 + 8*fpf) saw = false
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
        if (reset_back) draw_key(27, 1, false, flr(frame_num / fpkf) % 2 == 0)
    end


    if (fsc ~= -1) fsc += 1
    if (fsc >= 4) fsc = -1
    if (fsb ~= -1) fsb += 1
    if (fsb >= 4) fsb = -1
    frame_num+=1
    if (frame_num >= 256) frame_num = 0 -- might not be 256 later idk
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
#include validwordles.p8 


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
draw_valid_mark(0)


-- decode_answer(1 >> 16)

test_date_1 = {["y"] = 2022, ["m"] = 5, ["d"] = 21}
test_date_2 = {["y"] = 2003, ["m"] = 6, ["d"] = 20}


-- print(get_answer(0))

-- printh(escape_binary_str(binstr), "@clip")

__gfx__
00000000000000000000000000000000666666666666600006666000000000000000000000000000055550000666600006666000066660000666600000000000
00777777000000000000000000000000667666666666600066666600066666660000000000000000555555006666550066666600666666006666660000000000
07666666007777770000000000000000676677777766600067667600060000000666666600000000575575005765750057667600676676006766760000000000
06666666076666660000000000000000667666666676600067676600060000000600000000000000575755005757550057576600676766006767660000000000
06666666066666660077777700000000666666d66676600066766600060000000600000006666666557555005575550055755600667655006676660000000000
0666666606666666077777770000000066666d6d6676600006666000060000000600000006000000055550000555500005555000065550000666600000000000
06666666066666660766666600000000666666766666600000000000060000000600000006000000000000000000000000000000000000000000000000000000
06666666066666660666666600000000666666666666600000000000060000000600000006000000000000000000000000000000000000000000000000000000
06666666066666660d66666600000000666666666666000000000000010000000100000001111111000000000000000000000000000000000000000000000000
066666660666666600dddddd00000000666666667666000000000000010000000100000001111111000000000000000000000000000000000000000000000000
066666660d6666660000000000000000666666676666000000000000010000000100000000000000000000000000000000000000000000000000000000000000
0d66666600dddddd0000000000000000666666676666000000000000010000000111111100000000000000000000000000000000000000000000000000000000
00dddddd000000000000000000000000666666766666000000000000011111110000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000666676766666000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000666667666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000666666666666000000000000000000000000000000000000000000000000000000000000000000000000000000000000
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
