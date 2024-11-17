#include <bitset>
#include <cassert>
#include <iostream>
#include <vector>
#include <random>
#include <time.h>
#include <chrono>
#include <unistd.h>

#define n 100000
#define l 1000

#define PBSTR "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
#define PBWIDTH 60

using namespace std;

void printProgress(double percentage)
{
    int val = (int)(percentage * 100);
    int lpad = (int)(percentage * PBWIDTH);
    int rpad = PBWIDTH - lpad;
    printf("\r%3d%% [%.*s%*s]", val, lpad, PBSTR, rpad, "");
    fflush(stdout);
}

void hammingDistance(bitset<l> bitsetarray[n], vector<int> bitsetpairs[n], int *pair_count)
{
    for (int i = 0; i < n; i++)
    {
        printProgress(((double)i / (double)n));
        // cout<<i<<endl;
        for (int j = 0; j < n; j++)
        {
            bitset<l> temp = bitsetarray[i] ^ bitsetarray[j];
            if (temp.count() == 1)
            {
                bitsetpairs[i].push_back(j);
                (*pair_count)++;
            }
        }
    }
}

void load_from_file(char *file_name, bitset<l> bitsetarray[n])
{
    FILE *a_file = fopen(file_name, "r");

    if (a_file == NULL)
    {
        printf("unable to load file\n");
        return;
    }

    char temp;

    for (int i = 0; i < n; i++)
    {
        for (int j = 0; j < l; j++)
        {
            if (!fscanf(a_file, "%c\n", &temp))
            {
                printf("File loading error!\n");
                return;
            }

            if (temp == '1')
            {
                bitsetarray[i][j] = true;
            }
            else if (temp == '0')
                bitsetarray[i][j] = false;
        }
    }
}

void print_solution(bitset<l> bitsetarray[n], vector<int> *bitsetpairs, int *pair_count)
{
    cout << "Amount of pairs found: " << (*pair_count) / 2 << endl;
    for (int i = 0; i < n; i++)
    {
        if (bitsetpairs[i].size() > 0)
        {
            cout << "Words with Hamming distance equal to 1 with word:" << bitsetarray[i].to_string() << " are:" << endl;
            for (int j = 0; j < bitsetpairs[i].size(); j++)
            {
                cout << bitsetarray[bitsetpairs[i][j]].to_string() << endl;
            }
        }
    }
}
string gen_random(const int len)
{
    static const char alphanum[] =
        "01";
    string tmp_s;
    tmp_s.reserve(len);

    for (int i = 0; i < len; ++i)
    {
        tmp_s += alphanum[rand() % (sizeof(alphanum) - 1)];
    }

    return tmp_s;
}
void generate_data(char *file_name, int pairs)
{
    srand(time(NULL));
    FILE *a_file = fopen(file_name, "w");

    if (a_file == NULL)
    {
        printf("unable to load file\n");
        return;
    }

    int amount_of_iter = pairs;
    while (amount_of_iter > 0)
    {

        string temp = gen_random(l);
        const char *c = temp.c_str();
        fputs(c, a_file);
        cout << temp << endl;
        int index = rand() % temp.length();
        if (temp[index] == '0')
            temp[index] = '1';
        else
            temp[index] = '0';
        cout << temp << endl;
        fputs("\n", a_file);
        const char *ca = temp.c_str();
        fputs(ca, a_file);
        fputs("\n", a_file);
        amount_of_iter--;
    }
    for (int i = 0; i < n - pairs; i++)
    {
        for (int j = 0; j < l; j++)
        {
            if (rand() % 2 == 0)
                fputs("0", a_file);
            else
                fputs("1", a_file);
        }
        fputs("\n", a_file);
    }
}

int main(int argc, char **argv)
{
    if (argc < 2)
    {
        printf("file_with_data\n");
        return 1;
    }

    auto start = chrono::steady_clock::now();

    // generate_data(argv[1],5);

    bitset<l> *bitsetarray = new bitset<l>[n];
    vector<int> *bitsetpairs = new std::vector<int>[n];
    int *pair_count = new int;
    *pair_count = 0;
    load_from_file(argv[1], bitsetarray);
    hammingDistance(bitsetarray, bitsetpairs, pair_count);
    print_solution(bitsetarray, bitsetpairs, pair_count);

    delete[] bitsetarray;
    delete[] bitsetpairs;

    auto end = chrono::steady_clock::now();
    cout << "Elapsed time in milliseconds: "
         << chrono::duration_cast<chrono::milliseconds>(end - start).count()
         << " ms" << endl;
    return 0;
}
