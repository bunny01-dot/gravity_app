# Vocabulary CSV Structure Guide

To ensure all games (Word Match, Flashcards, Synonym Swap, Picture Guess, etc.) work correctly, utilize the following CSV structure.

### **Column Mapping**

| Column Index | Header Name | Description | Used By Game |
| :--- | :--- | :--- | :--- |
| **0** | `Serial` | Unique ID or Serial Number. | Internal Logic |
| **1** | `Word` | The English word to learn. | **All Games** |
| **2** | `POS` | Part of Speech (e.g., noun, verb). | Flashcards / Details |
| **3** | `Meaning` | The definition or translation. | Word Match, Flashcards, Word Builder, Typing Defense |
| **4** | `Hindi_Meaning` | (Optional) Secondary meaning. | *Currently Unused* |
| **5** | `Example` | Example sentence using the word. | **Fill The Gap**, Flashcards |
| **6** | `Image_URL` | URL to an image (https://...) or Asset path. | **Picture Guess**, Flashcards |
| **7** | `Antonyms` | Comma-separated list of antonyms. | *Future Antonym Game* |
| **8** | `Synonyms` | Comma-separated list of synonyms. | **Synonym Swap** |

---

### **Sample CSV Content**

You can copy and save this as `vocabulary.csv`.

```csv
Serial,Word,POS,Meaning,Hindi_Meaning,Example,Image_URL,Antonyms,Synonyms
1,Astronaut,noun,A person trained to travel in a spacecraft,,"The astronaut floated in zero gravity.",https://example.com/astro.png,,pilot,cosmonaut,explorer
2,Benevolent,adj,Well meaning and kindly,,"The benevolent king gave food to the poor.",,malevolent,kind,generous,charitable
3,Calculate,verb,Determine the amount or number of something mathematically,,"Can you calculate the total cost?",,guess,compute,count,determine
4,Drought,noun,A prolonged period of abnormally low rainfall,,"The farmers worried about the drought destroying crops.",,flood,dry spell,aridity,shortage
5,Ecosystem,noun,A biological community of interacting organisms,,"The coral reef is a fragile ecosystem.",,,,environment,habitat
6,Fragile,adj,Easily broken or damaged,,"Handle the fragile vase with care.",,strong,delicate,frail,brittle
7,Gravity,noun,The force that attracts a body toward the center of the earth,,"Gravity keeps us grounded on Earth.",,,,force,attraction
8,Habitat,noun,The natural home or environment of an animal,,"The polar bear's habitat is melting.",,,,home,territory,environment
9,Illuminate,verb,Make something visible or bright by shining light on it,,"The lamp helped illuminate the dark room.",,darken,light up,brighten,shine
10,Jovial,adj,Cheerful and friendly,,"He was in a jovial mood after winning.",,miserable,cheerful,jolly,merry
```

### **Critical Data Rules for Games**

1.  **Fill The Gap**: The `Example` sentence **MUST** contain the `Word` (case-insensitive). The game looks for the word to replace it with valid blanks.
    *   *Bad*: Word: "Cat", Example: "The feline sat there." (Game cannot hide "Cat")
    *   *Good*: Word: "Cat", Example: "The **cat** sat there." (Game generates "The ___ sat there.")
2.  **Synonym Swap**: The `Synonyms` column must not be empty. Separate multiple synonyms with commas (e.g., "fast, quick, swift").
3.  **Picture Guess**: The `Image_URL` must be a direct link to an image (ending in .png, .jpg) or a valid asset path.
4.  **Word Match**: Requires both `Word` and `Meaning` to be present.
