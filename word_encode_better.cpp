#include <string>
#include <iostream>
#include <fstream>
#include <bitset>
#include <vector>
#include <cmath>
#include <map>

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

bool sortbysec(const pair<string,int> &a,
              const pair<string,int> &b){
    return (a.second > b.second);
}

pair<map<pair<int,int>, int>, vector<int> > getFreqList(vector<string> &word_list){
    map<pair<int,int>, int> freqMap;
    for(int i = 0; i < word_list.size(); i++){
        int firstLetter = word_list[i][3] - 97;
        int secondLetter = word_list[i][4] - 97;
        // makes sure the first letter is always lower, so first in alphabet
        if(firstLetter > secondLetter){
            int temp = secondLetter;
            secondLetter = firstLetter;
            firstLetter = temp;
        }
        freqMap[make_pair(firstLetter, secondLetter)]++;
    }
    // just print it here for easy
    vector<pair<string, int> > freqSort;
    for(int i = 0; i < 676; i++){
        string letts;
        letts.push_back((char)((i / 26)+97));
        letts.push_back((char)((i % 26)+97));
        int val = freqMap[make_pair(i / 26, i % 26)];
        freqSort.push_back(make_pair(letts, val));
    }
    sort(freqSort.begin(), freqSort.end(), sortbysec);
    int runningCounter = 0;
    int bitCounter = 1;
    int fullBits = word_list.size() * 11;
    vector<int> bitSizePer(11, 100000000);
    for(int i = 0; i < 676; i++){
        runningCounter += freqSort[i].second;
        if(i >= pow(2, bitCounter)-1){
            int bitSize = runningCounter * (bitCounter+2) + (word_list.size()-runningCounter) * 11;
            // cout << bitCounter << " Bit(s) covers : " << runningCounter << " ( "<< 100*((double)runningCounter)/word_list.size() << "% ) => " 
            // << bitSize << " bits (" << 100*((double)bitSize) / fullBits << "%)" << endl;
            bitSizePer[bitCounter] = bitSize;
            bitCounter++;
        }
    }
    // cout << endl;
    // for(int i = 0; i < 10; i++){
    //     cout << "\t->" << freqSort[i].first << ": " << freqSort[i].second << endl;
    // }
    return make_pair(freqMap, bitSizePer);
}

// assume sorted input
int findThirdBitsSize(vector<string> &word_list){
    vector<int> bitNeed(676);
    vector<int> elemCount(676);
    vector<int> diffElems(676);
    int onHash = 0; // aa
    int lastLetter = 0;
    for(int i = 0; i < word_list.size(); i++){
        int firstLetter = word_list[i][0] - 97;
        int secondLetter = word_list[i][1] - 97;
        int thirdLetter = word_list[i][1] - 97;
        int flHash = firstLetter * 26 + secondLetter;
        if(flHash != onHash){
            lastLetter = 0;
            onHash = flHash;
        }
        if(thirdLetter != lastLetter){
            diffElems[flHash]++;
        }
        int bitsRequired = ceil(log2(thirdLetter-lastLetter));
        elemCount[flHash]++;
        bitNeed[flHash] = max(bitNeed[flHash], bitsRequired);
        lastLetter = thirdLetter;
    }
    // calculate what we actually need:
    int totalRepBits = 0;
    int secsNoElems = 0;
    vector<int> secsWithBitReq(7);
    vector<int> elemsInBitReq(7);
    for(int i = 0; i < 676; i++){
        totalRepBits += diffElems[i]*(bitNeed[i]+1) + (elemCount[i]-diffElems[i]);
        if(elemCount[i] == 0){
            secsNoElems++;
        }
        secsWithBitReq[bitNeed[i]]++;
        elemsInBitReq[bitNeed[i]] += elemCount[i];
    }
    int otherwiseTotal = word_list.size() * 5; // just to see how much this crunches it
    // cout << "\nBits required for third letter: " << totalRepBits << " (" << 100*((double)totalRepBits) / otherwiseTotal << "%)" << endl;
    // cout << secsNoElems << " letter sections have no values" << endl;
    // for(int i =0; i < secsWithBitReq.size(); i++){
    //     cout << "SecBitReq " << i << ": " << secsWithBitReq[i] << " secs with " << elemsInBitReq[i] << " total words" << endl;
    //     // cout << "Words with bitreq " << i << ": " << bitReqWords[i] << endl;
    // }
    return totalRepBits;
}


vector<vector<int> > makePermutations(){
    vector<vector<int> > allPermutations;
    vector<int> basePerm = {0,1,2,3,4};
    do {
        allPermutations.push_back(basePerm);
    } while (next_permutation(basePerm.begin(), basePerm.end()));
    return allPermutations;
}

// sorts it too !
vector<string> makeWordPermutation(vector<string> &word_list, vector<int> thisPerm){
    vector<string> newPermList;
    for(int i = 0; i < word_list.size(); i++){
        string permedWord;
        for(int l = 0; l < 5; l++){
            // put each letter back into the new word in the order given by thisPerm
            permedWord.push_back(word_list[i][thisPerm[l]]);
        }
        newPermList.push_back(permedWord);
    }
    sort(newPermList.begin(), newPermList.end());
    return newPermList;
}

void testPermutations(vector<string> &baseWordList){
    int bestBitCount = 1000000000;
    int bestPermIndex = 0;
    int bestBitLookup = 0;

    // just curious
    int worstBitCount = 0;
    int worstPermIndex = 0;
    int worstBitLookup = 0;

    int standardBitCount;

    vector<vector<int> > allPermutations = makePermutations();

    for(int p = 0; p < allPermutations.size(); p++){
        vector<string> permedWordList = makeWordPermutation(baseWordList, allPermutations[p]);
        int thirdBitCount = findThirdBitsSize(permedWordList);
        vector<int> bitsPerSize = getFreqList(permedWordList).second;
        int bestLookupSize = min_element(bitsPerSize.begin(), bitsPerSize.end()) - bitsPerSize.begin();
        int fullBits = thirdBitCount + bitsPerSize[bestLookupSize];
        if(fullBits < bestBitCount){
            bestBitCount = fullBits;
            bestPermIndex = p;
            bestBitLookup = bestLookupSize;
        }
        if(fullBits > worstBitCount){
            worstBitCount = fullBits;
            worstPermIndex = p;
            worstBitLookup = bestLookupSize;
        }
        // just for later comparison
        if(p == 0){
            standardBitCount = fullBits;
        }
    }
    cout << "\nBest: "
    << "\n  bits: " << bestBitCount << " (" << 100*((double)bestBitCount)/standardBitCount << "%)"
    << "\n  p: " << bestPermIndex << " -- { ";
    for(int i = 0; i < 5; i++){
        cout << allPermutations[bestPermIndex][i] << " ";
    }
    cout << "}" 
    << "\n  using size " << bestBitLookup << " lookup storage" << endl;

    cout << "\nWorst: "
    << "\n  bits: " << worstBitCount << " (" << 100*((double)worstBitCount)/standardBitCount << "%)"
    << "\n  p: " << worstPermIndex << " -- { ";
    for(int i = 0; i < 5; i++){
        cout << allPermutations[worstPermIndex][i] << " ";
    }
    cout << "}" 
    << "\n  using size " << worstBitLookup << " lookup storage" << endl;

    cout << "\nDefault: "
    << "\n  bits: " << standardBitCount << " (" << 100*((double)standardBitCount)/standardBitCount << "%)"
    << "\n  p: 0 -- { ";
    for(int i = 0; i < 5; i++){
        cout << allPermutations[0][i] << " ";
    }
    cout << "}" 
    << "\n  using size " << 6 << " lookup storage" << endl;
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

    // getFreqList(validWordList);
    // findThirdBitsSize(validWordList);

    testPermutations(validWordList);

}