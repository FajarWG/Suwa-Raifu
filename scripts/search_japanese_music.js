const fs = require('fs');

async function searchKeywords() {
  const keywords = [
    'japanese traditional',
    'japanese lofi',
    'japanese garden',
    'kimi no na wa',
    'your name radwimps',
    'radwimps',
    'ghibli',
    'japanese ambient',
    'shamisen',
    'shrine',
    'zen garden',
    'japanese summer'
  ];

  const candidateMap = new Map();

  for (const kw of keywords) {
    try {
      const url = `https://apis.roblox.com/toolbox-service/v1/marketplace/3?keyword=${encodeURIComponent(kw)}&limit=30`;
      const res = await fetch(url);
      if (!res.ok) continue;
      const data = await res.json();
      if (data && data.data) {
        for (const item of data.data) {
          if (item.id && !candidateMap.has(item.id)) {
            candidateMap.set(item.id, { id: item.id, keyword: kw });
          }
        }
      }
    } catch (e) {
      console.error('Error fetching kw:', kw, e.message);
    }
  }

  console.log(`Found ${candidateMap.size} unique candidate asset IDs.`);

  // Now fetch details in batches of 10
  const candidates = Array.from(candidateMap.values());
  const detailed = [];

  for (let i = 0; i < Math.min(candidates.length, 60); i++) {
    const c = candidates[i];
    try {
      const res = await fetch(`https://economy.roblox.com/v2/assets/${c.id}/details`);
      if (res.ok) {
        const info = await res.json();
        if (info && info.AssetTypeId === 3) {
          detailed.push({
            id: c.id,
            name: info.Name,
            creator: info.Creator ? info.Creator.Name : 'Unknown',
            keyword: c.keyword
          });
        }
      }
    } catch (e) {}
  }

  console.log(`Retrieved details for ${detailed.length} audio assets.`);
  fs.writeFileSync('scripts/candidate_audio.json', JSON.stringify(detailed, null, 2));
  console.log('Saved to scripts/candidate_audio.json');
}

searchKeywords();
