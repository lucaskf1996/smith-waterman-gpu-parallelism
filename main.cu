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
    std::string a, b;
    std::cin >> n;
    std::cin >> m;
    std::cin >> a;
    std::cin >> b;

    a = '-' + a;
    b = '-' + b;
    
    thrust::device_vector<char> StrA(n+1);
    thrust::device_vector<char> StrB(m+1);
    thrust::device_vector<int> val1(m+1);
    thrust::device_vector<int> val2(m+1);

    for(int i = 0; i<m+1; i++){
        StrB[i] = b[i];
    }
    std::cout << std::endl;
    for(int i = 0; i<n+1; i++){
        StrA[i] = a[i];
    }
    
    thrust::fill(val1.begin(), val1.end(), 0);
    thrust::fill(val2.begin(), val2.end(), 0);

    thrust::device_vector<char> d_StrA = StrA;
    int maxScore = 0;
    int temp;
    std::cout << std::endl;
    for(int val = 0; val<m+1; val++){
        std::cout << val1[val] << " ";
    }
    for(int i = 1; i < n+1; i++){

        thrust::transform(thrust::make_zip_iterator(thrust::make_tuple(StrB.begin()+1, val1.begin(), val1.begin()+1)),
                          thrust::make_zip_iterator(thrust::make_tuple(StrB.end(), val1.end()-1, val1.end())),
                          val2.begin()+1,
                          match(StrA[i]));

        std::cout << std::endl;

        thrust::inclusive_scan(
            val2.begin(),
            val2.end(),
            val1.begin(), 
            compare_left()
        );

        temp = thrust::reduce(val1.begin(), val1.end(), 0, thrust::maximum<int>());
        if (temp > maxScore){
            maxScore = temp;
        }
        
        // for(int val = 0; val<m+1; val++){
        //     std::cout << val1[val] << " ";
        // }
    }
    std::cout << std::endl << maxScore << std::endl;
}

