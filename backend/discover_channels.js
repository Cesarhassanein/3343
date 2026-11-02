// Polling script - keeps checking for updates every 3 seconds
const https = require('https');

const BOT_TOKEN = '8526582853:AAFAJWAQg2q2SGJhScOaYI65O_-OftjA-RQ';

function callTelegram(method) {
  return new Promise((resolve, reject) => {
    https.get(`https://api.telegram.org/bot${BOT_TOKEN}/${method}`, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try { resolve(JSON.parse(data)); } catch(e) { reject(e); }
      });
    }).on('error', reject);
  });
}

let lastOffset = 0;
let discoveredChats = new Map();
let attempts = 0;
const MAX_ATTEMPTS = 40; // ~2 minutes

async function poll() {
  attempts++;
  try {
    const url = `getUpdates?limit=100&timeout=3${lastOffset ? '&offset=' + lastOffset : ''}`;
    const updates = await callTelegram(url);
    
    if (updates.result && updates.result.length > 0) {
      for (const u of updates.result) {
        lastOffset = u.update_id + 1;
        
        // Check all possible chat sources
        const sources = [
          u.message, u.channel_post, u.edited_channel_post,
          u.my_chat_member, u.chat_member
        ];
        
        for (const src of sources) {
          if (src && src.chat) {
            const c = src.chat;
            if (!discoveredChats.has(c.id)) {
              discoveredChats.set(c.id, {
                id: c.id,
                title: c.title || c.first_name || 'Unknown',
                type: c.type,
                username: c.username || 'N/A'
              });
              console.log(`\n🟢 NEW CHAT DISCOVERED!`);
              console.log(`   ID: ${c.id}`);
              console.log(`   Title: ${c.title || c.first_name || 'Unknown'}`);
              console.log(`   Type: ${c.type}`);
            }
          }
        }
      }
    }
  } catch(e) {
    console.error('Poll error:', e.message);
  }
  
  if (attempts % 5 === 0) {
    console.log(`[${new Date().toISOString()}] Polling... (attempt ${attempts}/${MAX_ATTEMPTS}, found ${discoveredChats.size} chats)`);
  }
  
  if (attempts >= MAX_ATTEMPTS) {
    console.log('\n=== FINAL RESULTS ===');
    if (discoveredChats.size === 0) {
      console.log('No chats discovered. Make sure:');
      console.log('1. Bot @Zewonbbot is added as ADMIN to each channel');
      console.log('2. Send a message in each channel AFTER adding the bot');
    } else {
      console.log('Discovered chats:');
      for (const [id, info] of discoveredChats) {
        console.log(`  ${info.title} (${info.type}): ${id}`);
      }
    }
    process.exit(0);
  }
  
  setTimeout(poll, 3000);
}

console.log('🔍 Polling for channel updates...');
console.log('   Add @Zewonbbot as admin to your channels, then send a message in each.');
console.log('   Waiting up to 2 minutes...\n');
poll();
