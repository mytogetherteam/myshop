const fs = require('fs');

const keysEn = {
  "terms_and_privacy": "I agree to the Terms of Service and Privacy Policy",
  "please_agree_terms": "Please agree to the Terms of Service and Privacy Policy"
};

const keysMy = {
  "terms_and_privacy": "ဝန်ဆောင်မှု စည်းမျဉ်းများနှင့် ကိုယ်ရေးကိုယ်တာ မူဝါဒကို သဘောတူပါသည်",
  "please_agree_terms": "ကျေးဇူးပြု၍ ဝန်ဆောင်မှု စည်းမျဉ်းများနှင့် ကိုယ်ရေးကိုယ်တာ မူဝါဒကို သဘောတူပါ"
};

const keysTh = {
  "terms_and_privacy": "ฉันยอมรับข้อกำหนดในการให้บริการและนโยบายความเป็นส่วนตัว",
  "please_agree_terms": "โปรดยอมรับข้อกำหนดในการให้บริการและนโยบายความเป็นส่วนตัว"
};

function updateFile(file, keys) {
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  for (const [key, value] of Object.entries(keys)) {
    data[key] = value;
  }
  fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf8');
}

updateFile('assets/lang/en.json', keysEn);
updateFile('assets/lang/my.json', keysMy);
updateFile('assets/lang/th.json', keysTh);

console.log('Terms translations applied.');
