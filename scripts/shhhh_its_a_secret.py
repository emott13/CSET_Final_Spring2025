def customHash(string):
    string = pkcs7_pad(string)
    x = len(string) // 2
    string = string[x:] + string[:x]
    hashValue = 4281
    prime = 13
    for s in string:
        hashValue = (((hashValue << 6) + hashValue) * prime) ^ord(s) % (2**128)
    hashValue = toBase23(hashValue)
    return hashValue

def pkcs7_pad(data, block_size=128):
    padLen = block_size - (len(data) % block_size)
    return data + chr(padLen) * padLen

def toBase23(n):
    baseDigits = '*3$58+ED#9/GJK20!1LQR&?deim@_;Pkq~`=o'
    result = ''
    n = abs(n)
    while n > 0:
        remainder = n % 37
        result = baseDigits[remainder] + result
        n //= 37
    return result

# test
if __name__ == '__main__':
    word = input('Enter a word: ')
    print(word)
    hashWord = customHash(word)
    print(f'Your encoded word is: \n{hashWord}')