const fs = require('fs');
const path = require('path');

const ASSETS_DIR = path.join(__dirname, '../assets/Master Sheets');
const OUTPUT_FILE = path.join(__dirname, '../assets/beginner_data.json');

const FILES = {
    vocabulary: 'Vocabulary Beginner - Sheet.csv',
    sentences: 'Daily Sentences - Beginner - Sheet.csv',
    verbs: 'Verb Forms Beginner - Sheet.csv'
};

// Helper to parse CSV line respecting quotes
function parseCSVLine(line) {
    const result = [];
    let current = '';
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
        const char = line[i];

        if (char === '"') {
            inQuotes = !inQuotes;
        } else if (char === ',' && !inQuotes) {
            result.push(current.trim().replace(/^"|"$/g, '')); // Remove surrounding quotes if any
            current = '';
        } else {
            current += char;
        }
    }
    result.push(current.trim().replace(/^"|"$/g, ''));
    return result;
}

function parseCSV(content) {
    const lines = content.split(/\r?\n/).filter(l => l.trim().length > 0);
    if (lines.length === 0) return [];

    const headers = parseCSVLine(lines[0]);
    const data = [];

    for (let i = 1; i < lines.length; i++) {
        const values = parseCSVLine(lines[i]);
        if (values.length < headers.length) continue; // Skip incomplete lines

        const row = {};
        for (let j = 0; j < headers.length; j++) {
            const header = headers[j].trim();
            // Basic normalization of header keys
            const key = header;
            row[key] = values[j] || '';
        }
        data.push(row);
    }
    return data;
}

function extractDay(dayStr) {
    if (!dayStr) return null;
    const match = dayStr.match(/Day\s*(\d+)/i);
    return match ? parseInt(match[1], 10) : null;
}

function processVocabulary(data) {
    return data.map(row => {
        return {
            day: extractDay(row['Day Number']),
            word: row['English Word'],
            partOfSpeech: row['Part of Speech'],
            difficulty: row['Difficulty'],
            tamil: row['Tamil Translation'],
            hindi: row['Hindi Translation'],
            example_en: row['English Example'],
            example_ta: row['Tamil Example'],
            example_hi: row['Hindi Example'],
            synonyms: row['Synonyms'],
            tamil_meaning: row['Tamil Meaning']
        };
    }).filter(item => item.day !== null && item.word);
}

function processSentences(data) {
    return data.map(row => {
        // Headers: Day Number,Difficulty,English,Tamil (தமிழ்),Hindi (हिंदी)
        // Need to be careful with exact header names from the file
        // The parser preserves headers as is.
        // Let's check keys dynamically if needed, but for now assuming standard

        return {
            day: extractDay(row['Day Number']),
            english: row['English'],
            tamil: row['Tamil (தமிழ்)'] || row['Tamil'], // Fallback if header varies
            hindi: row['Hindi (हिंदी)'] || row['Hindi']
        };
    }).filter(item => item.day !== null && item.english);
}

function processVerbs(data) {
    return data.map(row => {
        // Headers: English (V1/V2/V3),Day Number,Difficulty Level,Tamil (Infinitive/Past/Perfect),Hindi (Infinitive/Past/Perfect)

        const engParts = (row['English (V1/V2/V3)'] || '').split('/').map(s => s.trim());
        const tamParts = (row['Tamil (Infinitive/Past/Perfect)'] || '').split('/').map(s => s.trim());
        const hinParts = (row['Hindi (Infinitive/Past/Perfect)'] || '').split('/').map(s => s.trim());

        // Handle "Be / Was, Were / Been" case or commas inside
        // The text might clearly use / as separator based on file review.

        return {
            day: extractDay(row['Day Number']),
            v1: engParts[0] || '',
            v2: engParts[1] || '',
            v3: engParts[2] || '',
            tamil_v1: tamParts[0] || '',
            tamil_v2: tamParts[1] || '',
            tamil_v3: tamParts[2] || '',
            hindi_v1: hinParts[0] || '',
            hindi_v2: hinParts[1] || '',
            hindi_v3: hinParts[2] || ''
        };
    }).filter(item => item.day !== null && item.v1);
}

async function main() {
    try {
        const result = {};

        // Process Vocabulary
        if (fs.existsSync(path.join(ASSETS_DIR, FILES.vocabulary))) {
            console.log('Processing Vocabulary...');
            const raw = fs.readFileSync(path.join(ASSETS_DIR, FILES.vocabulary), 'utf-8');
            result.vocabulary = processVocabulary(parseCSV(raw));
        } else {
            console.error(`File not found: ${FILES.vocabulary}`);
            result.vocabulary = [];
        }

        // Process Sentences
        if (fs.existsSync(path.join(ASSETS_DIR, FILES.sentences))) {
            console.log('Processing Sentences...');
            const raw = fs.readFileSync(path.join(ASSETS_DIR, FILES.sentences), 'utf-8');
            result.sentences = processSentences(parseCSV(raw));
        } else {
            console.error(`File not found: ${FILES.sentences}`);
            result.sentences = [];
        }

        // Process Verbs
        if (fs.existsSync(path.join(ASSETS_DIR, FILES.verbs))) {
            console.log('Processing Verbs...');
            const raw = fs.readFileSync(path.join(ASSETS_DIR, FILES.verbs), 'utf-8');
            result.verbs = processVerbs(parseCSV(raw));
        } else {
            console.error(`File not found: ${FILES.verbs}`);
            result.verbs = [];
        }

        fs.writeFileSync(OUTPUT_FILE, JSON.stringify(result, null, 2), 'utf-8');
        console.log(`Successfully processed data to ${OUTPUT_FILE}`);

    } catch (e) {
        console.error('Error processing data:', e);
        process.exit(1);
    }
}

main();
