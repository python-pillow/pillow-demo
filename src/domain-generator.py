import random
import requests

# Fetch a list of words from an online dictionary or use a predefined list
def get_word_list():
    response = requests.get("https://raw.githubusercontent.com/dwyl/english-words/master/words_dictionary.json")
    words_dict = response.json()
    # Filter words that are 4 characters or less
    short_words = [word for word in words_dict if len(word) <= 5]
    return short_words

# Function to generate a cool domain name
def generate_domain_name(word_list):
    # Randomly pick two words
    word1 = random.choice(word_list)
    word2 = random.choice(word_list)
    # Join the words to form a potential domain name
    domain_name = word1 + word2
    return domain_name

def main():
    word_list = get_word_list()
    domain_name = generate_domain_name(word_list)
    print(f"Cool domain name idea: {domain_name}.com")

if __name__ == "__main__":
    main()
