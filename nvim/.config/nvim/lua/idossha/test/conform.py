# this is a "messy" python file on purpose.
# test conform with this file


import sys, os
from collections import deque, defaultdict, namedtuple
import time, random
from math import sin, cos, sqrt
import requests  # third-party import

def greet (name : str , times= 1 ):
   for _ in range(times):
       print (f"Hello, {name}!")

def main():
   greet("Conform Demo" , 2)

   numbers =  [10,7,6,100,42, -2,99]
   sorted_numbers = sorted(numbers, key= lambda x: -x)
   print("Reversed sorted list:", sorted_numbers)

   # Using requests just for demonstration
   # You might not have it installed, but isort can still reorder this import 
   r = requests.get("https://httpbin.org/get")
   print("Status Code:", r.status_code)

   # Some random math to show more lines
   value =  sin(3.14159 / 2) + cos(0)
   print("Random math result:", value)

if __name__ == "__main__":
   main()
