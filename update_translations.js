const fs = require('fs');

const myKeys = {
  "login_title": "ဆိုင်စီမံခန့်ခွဲမှု အကောင့်ဝင်ရန် 👋",
  "login_subtitle": "သင့်ဆိုင်ကို လွယ်ကူစွာ စီမံခန့်ခွဲပါ",
  "username_or_email": "အသုံးပြုသူအမည် သို့မဟုတ် အီးမေးလ်",
  "username_email_hint": "admin@shop.com",
  "please_enter_username_email": "ကျေးဇူးပြု၍ သင့်အသုံးပြုသူအမည် သို့မဟုတ် အီးမေးလ်ကို ရိုက်ထည့်ပါ",
  "password": "စကားဝှက်",
  "enter_your_password": "သင့်စကားဝှက်ကို ရိုက်ထည့်ပါ",
  "please_enter_password": "ကျေးဇူးပြု၍ သင့်စကားဝှက်ကို ရိုက်ထည့်ပါ",
  "login_btn": "အကောင့်ဝင်ရန်",
  "no_account": "ဆိုင်အကောင့် မရှိသေးဘူးလား? ",
  "apply_now": "ယခုလျှောက်ထားရန်",
  "login_failed": "အကောင့်ဝင်ခြင်း မအောင်မြင်ပါ",
  "unexpected_error": "မျှော်လင့်မထားသော အမှားတစ်ခု ဖြစ်ပွားခဲ့သည်",
  "register_title": "ပါတနာအဖြစ် ပါဝင်ပါ 🚀",
  "register_subtitle": "သင့်အွန်လိုင်းဆိုင်ကိုဖွင့်ပြီး ဖောက်သည်များထံရောက်ရှိရန် ယခုလျှောက်ထားပါ။",
  "shop_name_hint": "ဥပမာ- ကျွန်ုပ်၏ အကောင်းဆုံးဆိုင်",
  "please_enter_shop_name": "ကျေးဇူးပြု၍ သင့်ဆိုင်အမည်ကို ရိုက်ထည့်ပါ",
  "owner_name": "ပိုင်ရှင်အမည်",
  "owner_name_hint": "သင့်နာမည်အပြည့်အစုံကို ရိုက်ထည့်ပါ",
  "please_enter_owner_name": "ကျေးဇူးပြု၍ ပိုင်ရှင်အမည်ကို ရိုက်ထည့်ပါ",
  "phone_hint": "ဥပမာ- ၀၉xxxxxxxxx",
  "please_enter_phone": "ကျေးဇူးပြု၍ သင့်ဖုန်းနံပါတ်ကို ရိုက်ထည့်ပါ",
  "email_optional": "အီးမေးလ်လိပ်စာ (ရွေးချယ်နိုင်သည်)",
  "submit_application": "လျှောက်လွှာတင်မည်",
  "registration_success": "လျှောက်လွှာတင်ခြင်း အောင်မြင်ပါသည်။ သင့်ဆိုင်အကောင့်ကို အတည်ပြုရန်နှင့် ဖွင့်ရန် ကျွန်ုပ်တို့၏အဖွဲ့မှ မကြာမီ ဆက်သွယ်ပါမည်။",
  "registration_failed": "မှတ်ပုံတင်ခြင်း မအောင်မြင်ပါ"
};

const thKeys = {
  "login_title": "เข้าสู่ระบบผู้ดูแลร้านค้า 👋",
  "login_subtitle": "จัดการร้านค้าของคุณได้อย่างง่ายดาย",
  "username_or_email": "ชื่อผู้ใช้หรืออีเมล",
  "username_email_hint": "admin@shop.com",
  "please_enter_username_email": "โปรดป้อนชื่อผู้ใช้หรืออีเมลของคุณ",
  "password": "รหัสผ่าน",
  "enter_your_password": "ป้อนรหัสผ่านของคุณ",
  "please_enter_password": "โปรดป้อนรหัสผ่านของคุณ",
  "login_btn": "เข้าสู่ระบบ",
  "no_account": "ยังไม่มีบัญชีร้านค้า? ",
  "apply_now": "สมัครเลย",
  "login_failed": "เข้าสู่ระบบล้มเหลว",
  "unexpected_error": "เกิดข้อผิดพลาดที่ไม่คาดคิด",
  "register_title": "ร่วมเป็นพาร์ทเนอร์ 🚀",
  "register_subtitle": "สมัครตอนนี้เพื่อเปิดร้านค้าออนไลน์และเข้าถึงลูกค้ามากขึ้น",
  "shop_name_hint": "เช่น ร้านค้ายอดเยี่ยมของฉัน",
  "please_enter_shop_name": "โปรดป้อนชื่อร้านค้าของคุณ",
  "owner_name": "ชื่อเจ้าของ",
  "owner_name_hint": "ป้อนชื่อนามสกุลของคุณ",
  "please_enter_owner_name": "โปรดป้อนชื่อเจ้าของ",
  "phone_hint": "เช่น 09xxxxxxxxx",
  "please_enter_phone": "โปรดป้อนหมายเลขโทรศัพท์ของคุณ",
  "email_optional": "ที่อยู่อีเมล (ไม่บังคับ)",
  "submit_application": "ส่งใบสมัคร",
  "registration_success": "ส่งใบสมัครเรียบร้อยแล้ว! ทีมงานของเราจะติดต่อกลับเพื่อยืนยันและเปิดใช้งานบัญชีร้านค้าของคุณในไม่ช้า",
  "registration_failed": "การลงทะเบียนล้มเหลว"
};

function updateFile(file, keys) {
  const data = JSON.parse(fs.readFileSync(file, 'utf8'));
  for (const [key, value] of Object.entries(keys)) {
    data[key] = value;
  }
  fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf8');
}

updateFile('assets/lang/my.json', myKeys);
updateFile('assets/lang/th.json', thKeys);

console.log('Translations applied.');
