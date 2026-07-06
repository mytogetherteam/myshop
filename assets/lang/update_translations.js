const fs = require('fs');

function addKeys(file, keys) {
  try {
    const data = JSON.parse(fs.readFileSync(file, 'utf8'));
    Object.assign(data, keys);
    fs.writeFileSync(file, JSON.stringify(data, null, 2));
    console.log('Updated ' + file);
  } catch (e) {
    console.error('Error on ' + file + ':', e);
  }
}

const en = {
  'setup_guide_title': 'Enable Order Alerts',
  'setup_guide_subtitle': 'Required to receive orders when app is in background',
  'setup_guide_warning': 'Without these settings, your phone will block order notifications and you will MISS orders!',
  'setup_guide_step1_title': 'Disable Battery Optimization',
  'setup_guide_step1_subtitle': 'Tap the button below — Android will ask you to confirm',
  'setup_guide_step1_btn': 'Allow Battery Optimization Ignore',
  'setup_guide_step3_title': 'Allow Notifications',
  'setup_guide_step3_subtitle': 'Make sure My Shop notifications are turned ON',
  'setup_guide_step3_btn': 'Open App Settings',
  'setup_guide_done_btn': '✅ Done — Start receiving orders!',
  
  'setup_guide_xiaomi_title': 'Xiaomi/Redmi: Enable AutoStart',
  'setup_guide_xiaomi_steps': '1. Settings → Apps → Manage Apps\n2. Find "My Shop"\n3. Tap "Autostart" → Turn ON\n4. Tap "Battery Saver" → No Restrictions',
  
  'setup_guide_oppo_title': 'OPPO/Realme: Allow Auto Launch',
  'setup_guide_oppo_steps': '1. Phone Manager → Privacy Permissions\n2. Find "My Shop" → Auto Launch → ON\n3. Settings → Battery → App Battery Management\n4. My Shop → Allow background activity',
  
  'setup_guide_vivo_title': 'Vivo: Enable Background Activity',
  'setup_guide_vivo_steps': '1. Settings → Battery\n2. Background Power Management\n3. Find "My Shop" → Do Not Restrict\n4. Settings → Apps → My Shop → Background popup → Allow',
  
  'setup_guide_huawei_title': 'Huawei/Honor: Enable AutoLaunch',
  'setup_guide_huawei_steps': '1. Phone Manager → App Launch\n2. Find "My Shop" → Turn OFF Auto-manage\n3. Enable: Auto-launch + Secondary launch + Run in background',
  
  'setup_guide_samsung_title': 'Samsung: Unrestricted Battery',
  'setup_guide_samsung_steps': '1. Settings → Apps → My Shop → Battery\n2. Select "Unrestricted"\n3. Turn OFF "Put unused apps to sleep"',
  
  'setup_guide_generic_title': 'Enable Background / AutoStart',
  'setup_guide_generic_steps': '1. Settings → Apps → My Shop\n2. Battery / Power settings\n3. Select "Unrestricted" or "No restriction"\n4. Enable "AutoStart" or "Auto Launch" if available'
};

const my = {
  'setup_guide_title': 'Order Notification ဖွင့်ပါ',
  'setup_guide_subtitle': 'App အပြင်ထွက်ထားချိန်မှာ Order လက်ခံရရှိဖို့ မဖြစ်မနေ လိုအပ်ပါတယ်',
  'setup_guide_warning': 'ဒီ Settings တွေကို မပြင်ထားရင် Order အသံမြည်မှာ မဟုတ်တဲ့အတွက် Order လွတ်သွားနိုင်ပါတယ်!',
  'setup_guide_step1_title': 'Battery Optimization ပိတ်ပါ',
  'setup_guide_step1_subtitle': 'အောက်ပါ ခလုတ်ကို နှိပ်ပြီး ခွင့်ပြု (Allow) ပေးပါ',
  'setup_guide_step1_btn': 'Allow Battery Optimization',
  'setup_guide_step3_title': 'Notification ဖွင့်ပါ',
  'setup_guide_step3_subtitle': 'Settings ထဲတွင် My Shop ၏ Notification ကို ဖွင့်ထားပါ',
  'setup_guide_step3_btn': 'App Settings ကို ဖွင့်ရန်',
  'setup_guide_done_btn': '✅ အဆင်ပြေပါပြီ — Order စတင် လက်ခံပါ!',
  
  'setup_guide_xiaomi_title': 'Xiaomi/Redmi: AutoStart ဖွင့်ပါ',
  'setup_guide_xiaomi_steps': '၁။ Settings → Apps → Manage Apps ကိုသွားပါ။\n၂။ "My Shop" ကို ရှာပါ။\n၃။ "Autostart" ကို ဖွင့် (ON) ပေးပါ။\n၄။ "Battery Saver" ထဲဝင်ပြီး "No Restrictions" ရွေးပါ။',
  
  'setup_guide_oppo_title': 'OPPO/Realme: Auto Launch ဖွင့်ပါ',
  'setup_guide_oppo_steps': '၁။ Phone Manager → Privacy Permissions သွားပါ။\n၂။ "My Shop" ကို ရှာပြီး Auto Launch ဖွင့် (ON) ပေးပါ။\n၃။ Settings → Battery → App Battery Management သွားပါ။\n၄။ My Shop → Allow background activity ကို ဖွင့်ပေးပါ။',
  
  'setup_guide_vivo_title': 'Vivo: Background Activity ဖွင့်ပါ',
  'setup_guide_vivo_steps': '၁။ Settings → Battery ကိုသွားပါ။\n၂။ Background Power Management နှိပ်ပါ။\n၃။ "My Shop" ကို ရှာပြီး Do Not Restrict ရွေးပါ။\n၄။ Settings → Apps → My Shop → Background popup ကို Allow လုပ်ပါ။',
  
  'setup_guide_huawei_title': 'Huawei/Honor: AutoLaunch ဖွင့်ပါ',
  'setup_guide_huawei_steps': '၁။ Phone Manager → App Launch သွားပါ။\n၂။ "My Shop" ကို ရှာပြီး Auto-manage ကို ပိတ် (OFF) ပါ။\n၃။ Auto-launch, Secondary launch နဲ့ Run in background အကုန် ဖွင့်ပါ။',
  
  'setup_guide_samsung_title': 'Samsung: Unrestricted ရွေးပါ',
  'setup_guide_samsung_steps': '၁။ Settings → Apps → My Shop → Battery သွားပါ။\n၂။ "Unrestricted" ကို ရွေးပေးပါ။\n၃။ "Put unused apps to sleep" ကို ပိတ် (OFF) ပါ။',
  
  'setup_guide_generic_title': 'Background Activity / AutoStart ဖွင့်ပါ',
  'setup_guide_generic_steps': '၁။ Settings → Apps → My Shop ကိုသွားပါ။\n၂။ Battery / Power settings ကို နှိပ်ပါ။\n၃။ "Unrestricted" သို့မဟုတ် "No restriction" ကို ရွေးပါ။\n၄။ "AutoStart" သို့မဟုတ် "Auto Launch" ရှိပါက ဖွင့် (ON) ပါ။'
};

const th = en;

addKeys('en.json', en);
addKeys('my.json', my);
addKeys('th.json', th);
