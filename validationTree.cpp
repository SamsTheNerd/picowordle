#include <string>
#include <iostream>
#include <fstream>
#include <bitset>
#include <vector>
#include <cmath>


using namespace std;

class node{
    public:
    node* parent;
    node* children[26];
    bool isLeaf;
    

    int familySize;
    node(bool leaf=false){
        familySize = 0;
        parent = nullptr;
        isLeaf = leaf;
        for(int i = 0; i < 26; i++){
            children[i] = nullptr;
        }
    }

    int getFamilySize(){
        int baseSize = 1; // just itself
        if(isLeaf){
            return 0;
        }
        for(int i = 0; i < 26; i++){
            if(children[i]){
                baseSize += children[i]->getFamilySize();
            }
        }
        familySize = baseSize;
        return baseSize;
    }
};

class letterTree{
    public:
    letterTree(){
        root_node = new node();
        validNode = new node(true);
    }
    node* root_node;
    node* validNode; // just so that valid second to last layer nodes can be non null




    void addWord(string newWord){
        node* lastNode = root_node;
        for(int l = 0; l < 5; l++){
            int thisLetter = newWord[l] - 97;
            if(lastNode->children[thisLetter] == NULL){
                if(l < 4){ // not at last layer
                    node* newNode = new node();
                    newNode->parent = lastNode;
                    lastNode->children[thisLetter] = newNode;
                } else { // is at last layer
                    lastNode->children[thisLetter] = validNode;
                }
            }
            lastNode = lastNode->children[thisLetter];
        }
    }


    // really just to check that everything works
    bool isValidWord(string wordCheck){
        node* lastNode = root_node;
        for(int l = 0; l < 5; l++){
            int thisLetter = wordCheck[l] - 97;
            if(lastNode->children[thisLetter] == NULL){
                return false;
            }
            lastNode = lastNode->children[thisLetter];
        }
        return true;
    }

    void assignFamilySizes(){
        root_node->getFamilySize();
    }

    void printBaseSizes(){
        cout << "\n";
        for(int i = 0; i < 26; i++){
            if(root_node->children[i]){
                char thisLetter = 97+i;
                cout << thisLetter << ": " << root_node->children[i]->familySize << endl;
            } else {
                char thisLetter = 97+i;
                cout << thisLetter << ": " << 0 << endl;
            }
        }
    }

    // layer 0 - root node - contains everything
    // layer 1 - 26 blocks, 1 for each letter - going to be quite large but only 26 so we could store those values seperate
    // layer 2 - unknown # blocks - each should have a smaller family, want to know largest of these so we know how many bits we'll need per block
    int largestSecondLayer(){
        int largestFamily = 0;
        for(int i = 0; i < 26; i++){
            if(root_node->children[i]){
                for(int j = 0; j < 26; j++){
                    if(root_node->children[i]->children[j]){ // we have "[i][j]..."
                        int thisFamilyVal = root_node->children[i]->children[j]->familySize;
                        if(thisFamilyVal > largestFamily){
                            largestFamily = thisFamilyVal;
                        }
                    }
                }
            }
        }
        return largestFamily;
    }

    bool isFirstLayerFull(){
        for(int i = 0; i < 26; i++){
            if(root_node->children[i] == NULL){
                return false;
            }
        }
        return true;
    }
};

// want to find the best way to order our words:
// newOrder is an array where [originalPos] = newPos
// so reorderWord("abcde", [4,2,3,1,0]) = "edbca"
string reorderWord(string originalWord, int newOrder[5]){
    string newString = "";
    for(int i = 0; i < 5; i++){
        int oldPos = find(newOrder, newOrder+5, i) - newOrder;
        newString += originalWord[oldPos];
    }
    return newString;
}


// recursive
void generatePermutations(vector<vector<int> > &permutationList, int layer = 0, vector<int> stillOpen = {0,1,2,3,4}, vector<int> permutationSoFar = {}){
    if(layer == 5){
        // int finalPermutation[5];
        // for(int i = 0; i < 5; i++){
        //     finalPermutation[i] = permutationSoFar[i];
        // }
        permutationList.push_back(permutationSoFar);
    }
    for(int i = 0; i < stillOpen.size(); i++){
        vector<int> newPermutation = permutationSoFar;
        newPermutation.push_back(stillOpen[i]);
        vector<int> newStillOpen = stillOpen;
        newStillOpen.erase(newStillOpen.begin()+i);
        generatePermutations(permutationList, layer+1, newStillOpen, newPermutation);
    }
}

class TreeData{
    public:
    int orderArray[5];
    int totalNodeCount;
    int largestSecondLayer;
    bool firstLayerFull;

    int bitPerBlock;

    TreeData(letterTree &baseTree, int orderArrayIn[5]){
        for(int i = 0; i < 5; i++){
            orderArray[i] = orderArrayIn[i];
        }
        totalNodeCount = baseTree.root_node->familySize;
        largestSecondLayer = baseTree.largestSecondLayer();
        firstLayerFull = baseTree.isFirstLayerFull();
        bitPerBlock = 26 + ceil(log2(largestSecondLayer));
    }



};

bool operator<(const TreeData &lTD, const TreeData &rTD){
    return (lTD.bitPerBlock*lTD.totalNodeCount) < (rTD.bitPerBlock*rTD.totalNodeCount);
}

int main(){
    // going very dirty, just error checking
    string wordListName = "valid_words.txt";
    // string wordListName = "small_words.txt";
    ifstream wordList(wordListName);

    letterTree ourTree;

    vector<string> wordListVector;

    if(wordList.is_open()){
        string thisWord;
        while(getline(wordList, thisWord)){
            // new word
            ourTree.addWord(thisWord);
            wordListVector.push_back(thisWord);
        }
    }

    cout << "is 'among' word: ";
    cout << ourTree.isValidWord("among") << endl;
    cout << "is 'padme' word: ";
    cout << ourTree.isValidWord("padme") << endl;
    cout << "is 'small' word: ";
    cout << ourTree.isValidWord("small") << endl;

    ourTree.assignFamilySizes();

    cout << "\nTotalTreeSize: " << ourTree.root_node->familySize << endl;


    ourTree.printBaseSizes();

    cout << "\nIs first layer full: " << ourTree.isFirstLayerFull() << endl;
    cout << "\nLargest Second Layer: " << ourTree.largestSecondLayer() << endl;

    int exampleArray[] = {4,2,3,1,0};
    cout << "\nreorderWord(\"abcde\", [4,2,3,1,0]) = " << reorderWord("abcde", exampleArray) << endl;

    vector<vector<int> > ourPermutationList = {};

    generatePermutations(ourPermutationList);

    

    cout << "\nPermutationCount (expecting 120): " << ourPermutationList.size() << endl;
    cout << "Example permutation";
    for(int i = 0; i < ourPermutationList[1].size(); i++){
        cout << ourPermutationList[1][i]<< ", ";

    }
    cout << endl;
    // want to make a bunch of them:

    vector<TreeData> treeResults;

    for(int p = 0; p < 120; p++){
        letterTree thisPermTree;
        int permArray[5];
        // cout << "Perm " << p+1 << ": [";
        for(int i = 0; i < 5; i++){
            permArray[i] = ourPermutationList[p][i];
            // cout << permArray[i] << " ";
        }
        // cout << "]" << endl;
        for(int w = 0; w < wordListVector.size(); w++){
            thisPermTree.addWord(reorderWord(wordListVector[w], permArray));
        }
        thisPermTree.assignFamilySizes();
        TreeData thisTreeData(thisPermTree, permArray);
        treeResults.push_back(thisTreeData);
    }

    sort(treeResults.begin(), treeResults.end());

    for(int p = 0; p < 120; p++){
        cout << "Permutation #" << p+1 << " - [";
        for(int i = 0; i < 5; i++){
            cout << treeResults[p].orderArray[i];
            if(i != 4)
                cout << ", ";
        }

        cout << "]: " << treeResults[p].bitPerBlock*treeResults[p].totalNodeCount << "- " 
        << treeResults[p].bitPerBlock << "bits * " << treeResults[p].totalNodeCount << "blocks";
        cout  << " | " << (treeResults[p].firstLayerFull ? "Full" : "Empty") << endl; 
    }



}