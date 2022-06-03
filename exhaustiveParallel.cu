#include <thrust/host_vector.h>
#include <thrust/device_vector.h>
#include <thrust/generate.h>
#include <thrust/functional.h>
#include <thrust/transform.h>
#include <thrust/copy.h>
#include <cstdlib>
#include <algorithm>
#include <iostream>
#include <iomanip>
#include <tuple>
#include <chrono>
#include <omp.h>

struct match
{
    char b;
    int above, diag;
    match(int b_) : b(b_) {};
    __host__ __device__
    int operator()(const thrust::tuple<char, int, int>& v) {
        
        if(b == thrust::get<0>(v)){
            diag = thrust::get<1>(v) + 2;
        }
        else{
            diag = thrust::get<1>(v) - 1;
        }
        
        above = thrust::get<2>(v) - 1;

        if(diag>above && diag>0){
            return diag;
        }
        else if(above>diag && above>0){
            return above;
        }
        else if(above==diag && above>0){
            return diag;
        }
        else{
            return 0;
        }
    }
};

template <typename T>
struct PrintVec {
    __host__ __device__
    T operator()(const T y){
        // Unpack to Sij, Si-1j
        printf("%d ", y);
        return y;
    }
};

struct compare_left {
    __host__ __device__
    int operator()(const int& x, const int& y){
        int current = y;
        int left = x-1;

        if(current>left && current>0){
            return current;
        }
        else if(left>current && left>0){
            return left;
        }
        else if(left==current && left>0){
            return left;
        }
        else{
            return 0;
        }
    }
};

int main(int argc, char* argv[]) {

    int n, m;    
    std::string a, b, A, B;
    std::cin >> n;
    std::cin >> m;
    std::cin >> a;
    std::cin >> b;
    int lenSubstr;
    // int indexA, indexB;
    int globalMaxScore = 0;
    int temp;
    
    a = '-' + a;
    b = '-' + b;

    if(n>m){
        lenSubstr = m;
    }
    else{
        lenSubstr = n;
    }

    thrust::device_vector<char> StrA(n+1);
    thrust::device_vector<char> StrB(m+1);
                
    thrust::device_vector<int> val1(m+1);
    thrust::device_vector<int> val2(m+1);

    for(int i = 0; i<b.length(); i++){
        StrB[i] = b[i];
    }
    for(int i = 0; i<a.length(); i++){
        StrA[i] = a[i];
    }
    
    // std::cout << a << " " << b << std::endl;
    // std::cout << lenSubstr << std::endl;

    int minLen=-1;
    while(lenSubstr>=2 && lenSubstr >= minLen){
        // indexA = 0;
        // std::cout << lenSubstr << std::endl;
        for(int indexA = 0; indexA<a.length()-lenSubstr; indexA++){
            // indexB = 0;
            for(int indexB = 0; indexB<b.length()-lenSubstr; indexB++){
                
                thrust::fill(val1.begin(), val1.end(), 0);

                int maxScore = 0;
                auto begin_Parallel = std::chrono::high_resolution_clock::now();
                for(int i = 1; i < lenSubstr+1; i++){

                    thrust::transform(thrust::make_zip_iterator(thrust::make_tuple(StrB.begin()+1+indexB, val1.begin(), val1.begin()+1)),
                                    thrust::make_zip_iterator(thrust::make_tuple(StrB.begin()+1+indexB+lenSubstr, val1.begin()+lenSubstr, val1.begin()+1+lenSubstr)),
                                    val2.begin()+1,
                                    match(StrA[i+indexA]));

                    thrust::inclusive_scan(
                        val2.begin(),
                        val2.begin()+lenSubstr,
                        val1.begin(), 
                        compare_left()
                    );

                    temp = thrust::reduce(val1.begin(), val1.begin()+lenSubstr, 0, thrust::maximum<int>());
                    if (temp > maxScore){
                        maxScore = temp;
                    }

                    // thrust::transform(val1.begin(), val1.begin()+lenSubstr, val1.begin(), PrintVec<int>());
                    // std::cout << std::endl;
                }
                auto end_Parallel = std::chrono::high_resolution_clock::now();
                auto elapsed_Parallel = std::chrono::duration_cast<std::chrono::nanoseconds>(end_Parallel - begin_Parallel);
                // printf("Time measured: %.6f seconds.\n", elapsed_Parallel.count() * 1e-9);

                globalMaxScore = (globalMaxScore<maxScore) ? maxScore : globalMaxScore;
                // indexB++;
            }
            // indexA++;
        }
        minLen = globalMaxScore/2+1;
        lenSubstr--;
        std::cout << "score:  " << globalMaxScore << std::endl;
    }
    // std::cout << "score:  " << globalMaxScore << std::endl;
}