const fs = require('fs');
const path = require('path');

const ASSETS_DIR = path.join(__dirname, '../assets/Master Sheets');
const LEVELS = {
    beginner: {
        vocabulary: 'Vocabulary Beginner - Sheet.csv',
        sentences: 'Daily Sentences - Beginner - Sheet.csv',
        verbs: 'Verb Forms Beginner - Sheet.csv',
        output: '../assets/beginner_data.json'
    },
    intermediate: {
        vocabulary: 'Vocabulary Intermediate - Sheet.csv',
        sentences: 'Daily Sentences - Intermediate - Sheet.csv',
        verbs: 'Verb Forms Intermediate - Sheet.csv',
        output: '../assets/intermediate_data.json'
    },
    advanced: {
        vocabulary: 'Vocabulary Advanced - Sheet.csv',
        sentences: 'Daily Sentences - Advanced - Sheet.csv',
        verbs: 'Verb Forms Advanced - Sheet.csv',
        output: '../assets/advanced_data.json'
    }
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
        if (values.length < headers.length) continue;

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
        return {
            day: extractDay(row['Day Number']),
            english: row['English'],
            tamil: row['Tamil (தமிழ்)'] || row['Tamil'],
            hindi: row['Hindi (हिंदी)'] || row['Hindi']
        };
    }).filter(item => item.day !== null && item.english);
}

function processVerbs(data) {
    return data.map(row => {
        const engParts = (row['English (V1/V2/V3)'] || '').split('/').map(s => s.trim());
        const tamParts = (row['Tamil (Infinitive/Past/Perfect)'] || '').split('/').map(s => s.trim());
        const hinParts = (row['Hindi (Infinitive/Past/Perfect)'] || '').split('/').map(s => s.trim());

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
    const levelKey = process.argv[2]?.toLowerCase();

    if (!levelKey || !LEVELS[levelKey]) {
        console.error('Usage: node scripts/process_level_data.js <beginner|intermediate|advanced>');
        process.exit(1);
    }

    const config = LEVELS[levelKey];
    const outputFile = path.join(__dirname, config.output);
    const result = {};

    try {
        console.log(`Processing ${levelKey} data...`);

        // Process Vocabulary
        const vocabPath = path.join(ASSETS_DIR, config.vocabulary);
        if (fs.existsSync(vocabPath)) {
            console.log(`- Vocabulary: ${config.vocabulary}`);
            const raw = fs.readFileSync(vocabPath, 'utf-8');
            result.vocabulary = processVocabulary(parseCSV(raw));
        } else {
            console.warn(`! File not found: ${config.vocabulary}`);
            result.vocabulary = [];
        }

        // Process Sentences
        const sentPath = path.join(ASSETS_DIR, config.sentences);
        if (fs.existsSync(sentPath)) {
            console.log(`- Sentences: ${config.sentences}`);
            const raw = fs.readFileSync(sentPath, 'utf-8');
            result.sentences = processSentences(parseCSV(raw));
        } else {
            console.warn(`! File not found: ${config.sentences}`);
            result.sentences = [];
        }

        // Process Verbs
        const verbPath = path.join(ASSETS_DIR, config.verbs);
        if (fs.existsSync(verbPath)) {
            console.log(`- Verbs: ${config.verbs}`);
            const raw = fs.readFileSync(verbPath, 'utf-8');
            result.verbs = processVerbs(parseCSV(raw));
        } else {
            console.warn(`! File not found: ${config.verbs}`);
            result.verbs = [];
        }

        fs.writeFileSync(outputFile, JSON.stringify(result, null, 2), 'utf-8');
        console.log(`Successfully processed data to ${outputFile}`);
        console.log(`Stats: Vocab: ${result.vocabulary.length}, Sentences: ${result.sentences.length}, Verbs: ${result.verbs.length}`);

    } catch (e) {
        console.error('Error processing data:', e);
        process.exit(1);
    }
}

main();
