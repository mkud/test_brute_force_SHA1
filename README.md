# test task: Brute force SHA1

The task is to find the string that that the SHA1-hash has 12 leading zeros.

* BruteForceManager - Main manager developed in Python. Main responsibility - 
  * connect to the test server with TLS;
  * get initial prefix;
  * create farm of SHA1 calculators;
  * send result to the test server.
* BruteForceSHA1CPU - CPU calculator of SHA1. 
  * gets the prefix value in command line;
  * calculates SHA1 using the OpenSSL library in several threads;
  * the result in the form of the space separated hex-code (valid UTF-8, subset from 0x21 to 0x7e)
* BruteForceSHA1CUDA - CUDA (Nvidia technology) calculator of SHA1. 
  * gets the prefix value in command line;
  * calculates SHA1 using the CUDA technology;
  * the result in the form of the space separated hex-code (valid UTF-8, subset from 0x21 to 0x7e)

