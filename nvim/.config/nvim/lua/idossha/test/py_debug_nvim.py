# py_debug_nvim.py

def calculate_fibonacci(n):
    """Calculate the Fibonacci sequence up to the nth number."""
    fib_sequence = [0, 1]
    
    if n <= 0:
        return []
    elif n == 1:
        return [0]
    elif n == 2:
        return fib_sequence
    
    # Calculate the rest of the sequence
    for i in range(2, n):
        next_fib = fib_sequence[-1] + fib_sequence[-2]
        fib_sequence.append(next_fib)
    
    return fib_sequence

def main():
    # Try different values to debug
    test_cases = [5, 10, 15]
    
    for n in test_cases:
        print(f"Fibonacci sequence up to {n} numbers:")
        result = calculate_fibonacci(n)
        print(result)
        
        # Calculate sum for debugging practice
        total = sum(result)
        print(f"Sum of the sequence: {total}")
        print("---")

if __name__ == "__main__":
    main()
