#include <string>
#include <iostream>
#include <fstream>
#include <bitset>
#include <vector>
#include <cmath>

using namespace std;

// note for later maybe ? [255] gives '\0' and ord('\0') = 0, soooo idk if I want to recode everything rn but def something to be aware of!!
// maybe deal with that when I go back to compression stuff
vector<string> picoChars = {
"\\000",
"¹",
"²",
"³",
"⁴",
"⁵",
"⁶",
"⁷",
"⁸",
"\t", // "   ",
"\\n",
"ᵇ",
"ᶜ",
"\\r",
"ᵉ",
"ᶠ",
"▮",
"■",
"□",
"⁙",
"⁘",
"‖",
"◀",
"▶",
"「",
"」",
"¥",
"•",
"、",
"。",
"゛",
"゜",
" ",
"!",
"\\\"",
"#",
"$",
"%",
"&",
"'",
"(",
")",
"*",
"+",
",",
"-",
".",
"/",
"0",
"1",
"2",
"3",
"4",
"5",
"6",
"7",
"8",
"9",
":",
";",
"<",
"=",
">",
"?",
"@",
"A",
"B",
"C",
"D",
"E",
"F",
"G",
"H",
"I",
"J",
"K",
"L",
"M",
"N",
"O",
"P",
"Q",
"R",
"S",
"T",
"U",
"V",
"W",
"X",
"Y",
"Z",
"[",
"\\\\",
"]",
"^",
"_",
"`",
"a",
"b",
"c",
"d",
"e",
"f",
"g",
"h",
"i",
"j",
"k",
"l",
"m",
"n",
"o",
"p",
"q",
"r",
"s",
"t",
"u",
"v",
"w",
"x",
"y",
"z",
"{",
"|",
"}",
"~",
"○",
"█",
"▒",
"🐱",
"⬇️",
"░",
"✽",
"●",
"♥",
"☉",
"웃",
"⌂",
"⬅️",
"😐",
"♪",
"🅾️",
"◆",
"…",
"➡️",
"★",
"⧗",
"⬆️",
"ˇ",
"∧",
"❎",
"▤",
"▥",
"あ",
"い",
"う",
"え",
"お",
"か",
"き",
"く",
"け",
"こ",
"さ",
"し",
"す",
"せ",
"そ",
"た",
"ち",
"つ",
"て",
"と",
"な",
"に",
"ぬ",
"ね",
"の",
"は",
"ひ",
"ふ",
"へ",
"ほ",
"ま",
"み",
"む",
"め",
"も",
"や",
"ゆ",
"よ",
"ら",
"り",
"る",
"れ",
"ろ",
"わ",
"を",
"ん",
"っ",
"ゃ",
"ゅ",
"ょ",
"ア",
"イ",
"ウ",
"エ",
"オ",
"カ",
"キ",
"ク",
"ケ",
"コ",
"サ",
"シ",
"ス",
"セ",
"ソ",
"タ",
"チ",
"ツ",
"テ",
"ト",
"ナ",
"ニ",
"ヌ",
"ネ",
"ノ",
"ハ",
"ヒ",
"フ",
"ヘ",
"ホ",
"マ",
"ミ",
"ム",
"メ",
"モ",
"ヤ",
"ユ",
"ヨ",
"ラ",
"リ",
"ル",
"レ",
"ロ",
"ワ",
"ヲ",
"ン",
"ッ",
"ャ",
"ュ",
"ョ",
"◜",
"◝"};


// want to get our 16 bit representation for validation list:
// x ccccc bbbbb aaaaa
// bits 0-4 : represent first letter
// bits 5-9: represent second letter
// bits 10-14: represent third letter
// bit 15 - unused
// deal with the other part somewhere else
// returns P8SCII representation in 2 chars-ish
string encodeValidWord(string fullWord){
    bitset<16> fullBitset;
    for(int l = 0; l < 3; l++){
        int thisLetter = fullWord[l+2] - 97;
        bitset<5> thisLetterBits(thisLetter);
        // cout << thisLetterBits << endl;
        for(int b = 0; b < 5; b++){
            fullBitset.set((5*l)+b, thisLetterBits[b]);
        }
    }
    bitset<8> lowerBits; //0-7
    bitset<8> upperBits; //8-15
    for(int b = 0; b < 8; b++){
        lowerBits.set(b, fullBitset[b]);
        upperBits.set(b, fullBitset[b+8]);
    }
    return picoChars[upperBits.to_ulong()] + picoChars[lowerBits.to_ulong()];
}




// need to deal with getting it actually into 24 bits instead of 25 bits :/
string encodeAnsWord(string fullWord){
    // try converting full thing into base 10?
    long b10Word = 0;
    for(int l = 0; l < 5; l++){
        int thisLetter = fullWord[l] - 97;
        b10Word += (pow(26,l) * thisLetter);
    }
    bitset<24> wordBits(b10Word);
    // cout << b10Word << "  ->  " << wordBits.to_string() << " => ";
    // bitset<8> ourBits[3];

    string encodedString = "";

    // doing upper -> lower again
    for(int byte = 2; byte >= 0; byte--){
        bitset<8> thisByte;
        for(int b = 0; b < 8; b++){
            thisByte.set(b, wordBits[(byte*8)+b]);
        }
        encodedString += picoChars[thisByte.to_ulong()];
    }
    return encodedString;
}






int main(){

    // read in valid words

    string validWordsName = "valid_words.txt";
    // string validWordsName = "small_words.txt";
    ifstream validWordstream(validWordsName);

    vector<string> validWordList;

    if(validWordstream.is_open()){
        string thisWord;
        while(getline(validWordstream, thisWord)){
            // new word
            validWordList.push_back(thisWord);
        }
    }

    sort(validWordList.begin(), validWordList.end());

    // read in answer words

    string ansWordsName = "nyt_answer_list.txt";
    ifstream ansWordstream(ansWordsName);

    vector<string> ansWordList;

    if(ansWordstream.is_open()){
        string thisWord;
        while(getline(ansWordstream, thisWord)){
            // new word
            ansWordList.push_back(thisWord);
        }
    }


    // cout << encodeValidWord("abxyz") << endl;
    // // prediction:
    // // x -> 10111
    // // y -> 11000
    // // z -> 11001
    // // 0 11001 11000 10111 
    // // 0110 0111 0001 0111 
    // // 103 23
    // // h「
    // // it works !

    // cout << "\n\"aaaaa\"b10 = ";
    // cout << encodeAnsWord("aaaaa");
    // cout << endl;
    // cout << "\n\"caaaa\"b10 = ";
    // cout << encodeAnsWord("caaaa");
    // cout << endl;
    // cout << "\n\"zzzzz\"b10 = ";
    // cout << encodeAnsWord("zzzzz");
    // cout << endl;


    string answerWordsEncoded = "";
    for(int w = 0; w < ansWordList.size(); w++){
        answerWordsEncoded += encodeAnsWord(ansWordList[w]);
    }

    ofstream picofullStream("validwordles.p8");

    // cout << endl << answerWordsEncoded << endl;

    ofstream wordleAnswerStream("nyt_answers_encoded.txt");


    // wordleAnswerStream << answerWordsEncoded;
    picofullStream << "nyt_answer_encoded = \"" << answerWordsEncoded << "\"\n";
    wordleAnswerStream.close();


    // keep track of how many valid words start with each pair of letters
    int twoDigitCounter[676] = {};

    string validWordsEncoded = "";

    for(int w = 0; w < validWordList.size(); w++){
        string thisWord = validWordList[w];
        int thisIndex = (thisWord[1]-97)*26 + (thisWord[0]-97);
        twoDigitCounter[thisIndex]++;
        validWordsEncoded += encodeValidWord(thisWord);
    }

    // how do we want to deal with the 676 stuff ? maybe have where each first letter starts, then smallest one for how many of each 2nd letter there is 
    int whereDigitStarts[26] = {};
    int howManySoFar = 0;
    int largestGroup = 0;
    string countString = "";
    picofullStream << "valid_up_counts = {";
    cout << "{";
    for(int f = 0; f < 26; f++){
        whereDigitStarts[f] = howManySoFar;
        // cout << howManySoFar << (f != 25 ? "," : "}");
        cout << howManySoFar << ",";
        picofullStream << howManySoFar << ",";
        for(int s = 0; s < 26; s++){
            howManySoFar += twoDigitCounter[26*s + f];
            countString += picoChars[twoDigitCounter[26*s + f]];
            if(twoDigitCounter[26*s + f] >= largestGroup){
                largestGroup = twoDigitCounter[26*s + f];
            }
        }
    }
    cout << howManySoFar << "}";
    cout << endl;
    picofullStream << howManySoFar << "}\n";
    cout << "largest group: " << largestGroup << endl;



    ofstream wordleValidStream("valid_encoded.txt");
    // wordleValidStream << validWordsEncoded;
    picofullStream << "valid_encoded = \"" << validWordsEncoded << "\"\n";
    wordleValidStream.close();




    ofstream wordleValidCountStream("valid_counts_encoded.txt");
    // wordleValidCountStream << countString;
    picofullStream << "valid_counts = \"" << countString << "\"\n";
    wordleValidCountStream.close();

    picofullStream.close();


    cout << encodeValidWord("aaaaa") << endl;
    cout << encodeValidWord("aahed") << endl;

}